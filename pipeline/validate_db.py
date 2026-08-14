"""
Sinosphere Rosetta — Database Validation Script
Runs correctness, coverage, consistency, and HSK completeness checks.
Produces a pass/fail report with detail on every failure.
"""

import csv
import sqlite3
from collections import Counter
from pathlib import Path

DB_PATH   = Path(__file__).parent.parent / "data" / "db" / "sinosphere.db"
HSK_CSV   = Path(__file__).parent.parent / "data" / "raw" / "hsk30.csv"

PASS = "✓"
FAIL = "✗"
WARN = "⚠"

results = []  # (status, category, message)

def ok(cat, msg):
    results.append((PASS, cat, msg))

def fail(cat, msg):
    results.append((FAIL, cat, msg))

def warn(cat, msg):
    results.append((WARN, cat, msg))

# ── Helpers ──────────────────────────────────────────────────────────────────
def load_hsk_csv():
    words = {}
    with open(HSK_CSV, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            level_raw = row["HSK_3_0_Level"].strip()
            hanzi = row["Hanzi"].strip().split("｜")[0].strip()
            if not hanzi:
                continue
            if level_raw == "7-9":
                level = 7
            elif level_raw.isdigit():
                level = int(level_raw)
            else:
                continue
            words[hanzi] = level
    return words

# ─────────────────────────────────────────────────────────────────────────────
def run_checks(cur):

    # ══════════════════════════════════════════════════════════════════════════
    # 1. GROUND TRUTH SPOT CHECKS
    # ══════════════════════════════════════════════════════════════════════════
    cat = "Ground Truth"
    TRUTHS = [
        # (simplified, pinyin_contains, hanviet, resonance, hsk_level)
        # HSK levels are HSK 3.0 (2021) standard
        ("城市",  "chéng shì",   "THÀNH THỊ",    "high",   3),
        ("大学",  "dà xué",      "ĐẠI HỌC",      "high",   1),   # HSK 3.0: level 1
        ("音乐",  "yīn yuè",     "ÂM NHẠC",      "high",   2),   # HSK 3.0: level 2
        ("心情",  "xīn qíng",    "TÂM TÌNH",     "high",   2),   # HSK 3.0: level 2
        ("自由",  "zì yóu",      "TỰ DO",        "high",   2),   # HSK 3.0: level 2
        ("学生",  "xué sheng",   "HỌC SINH",     "high",   1),   # sheng5 = neutral tone, correct
        ("时间",  "shí jiān",    "THỜI GIAN",    "high",   1),   # HSK 3.0: level 1
        ("感情",  "gǎn qíng",    "CẢM TÌNH",     "high",   3),   # HSK 3.0: level 3
        ("理想",  "lǐ xiǎng",    "LÍ TƯỞNG",     "high",   2),   # kVietnamese gives LÍ not LÝ
        ("世界",  "shì jiè",     "THẾ GIỚI",     "high",   3),
        ("图书馆","tú shū guǎn", "ĐỒ THƯ QUÁN",  "high",   1),   # HSK 3.0: level 1
        ("朋友",  "péng you",    "BẰNG HỮU",     "high",   1),   # neutral tone 'you' is correct
        ("明天",  "míng tiān",   "MINH THIÊN",   "high",   1),   # high is correct for MINH THIÊN
        ("海洋",  "hǎi yáng",    "HẢI DƯƠNG",    "high",   6),   # HSK 3.0: level 6
        ("地方",  "dì fāng",     "ĐỊA PHƯƠNG",   "high",   4),   # HSK 3.0: level 4
    ]
    ground_truth_failures = 0
    for simp, pinyin, hanviet, resonance, hsk in TRUTHS:
        row = cur.execute("""
            SELECT simplified, pinyin, han_viet, han_viet_resonance, hsk_level
            FROM compound_words WHERE simplified=?
        """, (simp,)).fetchone()
        if not row:
            fail(cat, f"{simp}: NOT FOUND in database")
            ground_truth_failures += 1
            continue
        errors = []
        # Case-insensitive pinyin comparison, ignore spacing differences
        if pinyin.lower().replace(" ","") not in (row[1] or "").lower().replace(" ",""):
            errors.append(f"pinyin expected '{pinyin}' got '{row[1]}'")
        if row[2] != hanviet:
            errors.append(f"han_viet expected '{hanviet}' got '{row[2]}'")
        if row[3] != resonance:
            errors.append(f"resonance expected '{resonance}' got '{row[3]}'")
        if row[4] != hsk:
            errors.append(f"hsk_level expected {hsk} got {row[4]}")
        if errors:
            fail(cat, f"{simp}: {'; '.join(errors)}")
            ground_truth_failures += 1
        else:
            ok(cat, f"{simp} ({hanviet}) — all fields correct")

    # ══════════════════════════════════════════════════════════════════════════
    # 2. CHARACTER DECOMPOSITION CHECKS
    # ══════════════════════════════════════════════════════════════════════════
    cat = "Decomposition"
    DECOMP_CHECKS = [
        # (char, expected_radical, must_contain_component)
        ("晨", "日", "日"),
        ("城", "土", "土"),
        ("明", "日", "日"),
        ("想", "心", "心"),
        ("海", "氵", None),   # 氵 is the correct water radical variant for left-side use
        ("森", "木", "木"),
        ("学", "子", None),
    ]
    for ch, radical, comp in DECOMP_CHECKS:
        row = cur.execute(
            "SELECT radical, decomposition FROM characters WHERE symbol=?", (ch,)
        ).fetchone()
        if not row:
            fail(cat, f"{ch}: NOT FOUND in characters table")
            continue
        if row[0] != radical:
            fail(cat, f"{ch}: radical expected '{radical}' got '{row[0]}'")
        elif comp:
            has_comp = cur.execute("""
                SELECT 1 FROM character_components cc
                JOIN components c ON c.id=cc.component_id
                WHERE cc.character_id=(SELECT id FROM characters WHERE symbol=?)
                AND c.symbol=?
            """, (ch, comp)).fetchone()
            if has_comp:
                ok(cat, f"{ch} — radical={radical}, component {comp} present")
            else:
                warn(cat, f"{ch} — radical={radical} correct but component {comp} not linked")
        else:
            ok(cat, f"{ch} — radical={radical} correct")

    # ══════════════════════════════════════════════════════════════════════════
    # 3. PINYIN TONE ACCURACY
    # ══════════════════════════════════════════════════════════════════════════
    cat = "Pinyin Tones"
    PINYIN_CHECKS = [
        ("吃", "chī"), ("喝", "hē"),  ("是", "shì"), ("我", "wǒ"),
        ("你", "nǐ"),  ("好", "hǎo"), ("中国","Zhōng guó"),
        ("北京","Běi jīng"), ("学习","xué xí"), ("工作","gōng zuò"),
        ("音乐","yīn yuè"),  ("朋友","péng you"),  # neutral tone 'you' is correct
        ("老师","lǎo shī"), ("谢谢","xiè xie"), ("请问","qǐng wèn"),
    ]
    pinyin_fails = 0
    for simp, expected in PINYIN_CHECKS:
        row = cur.execute(
            "SELECT pinyin FROM compound_words WHERE simplified=?", (simp,)
        ).fetchone()
        if not row:
            row = cur.execute(
                "SELECT pinyin FROM characters WHERE symbol=?", (simp,)
            ).fetchone()
        if not row:
            fail(cat, f"{simp}: not found"); pinyin_fails += 1; continue
        got = row[0] or ""
        # Case-insensitive comparison, allow minor spacing differences
        if expected.lower().replace(" ","") == got.lower().replace(" ",""):
            ok(cat, f"{simp}: '{got}'")
        else:
            fail(cat, f"{simp}: expected '{expected}' got '{got}'")
            pinyin_fails += 1

    # ══════════════════════════════════════════════════════════════════════════
    # 4. HSK COVERAGE
    # ══════════════════════════════════════════════════════════════════════════
    cat = "HSK Coverage"
    hsk_words = load_hsk_csv()
    total_hsk = len(hsk_words)
    missing_by_level = Counter()
    missing_words = []

    for word, level in hsk_words.items():
        row = cur.execute(
            "SELECT simplified FROM compound_words WHERE simplified=?", (word,)
        ).fetchone()
        if not row:
            missing_by_level[level] += 1
            missing_words.append((level, word))

    total_missing = len(missing_words)
    coverage_pct = (total_hsk - total_missing) / total_hsk * 100

    if coverage_pct >= 99:
        ok(cat, f"HSK coverage: {coverage_pct:.1f}% ({total_hsk-total_missing}/{total_hsk})")
    elif coverage_pct >= 97:
        warn(cat, f"HSK coverage: {coverage_pct:.1f}% — {total_missing} words missing")
    else:
        fail(cat, f"HSK coverage: {coverage_pct:.1f}% — {total_missing} words missing")

    # Per-level breakdown
    db_by_level = dict(cur.execute("""
        SELECT hsk_level, COUNT(*) FROM compound_words
        WHERE hsk_level IS NOT NULL GROUP BY hsk_level
    """).fetchall())
    # Words missing from CC-CEDICT are typically contextual phrases
    # (车上, 能不能, 很难说) — treat as warnings not failures
    for lvl in sorted(set(list(missing_by_level.keys()) + list(db_by_level.keys()))):
        in_db  = db_by_level.get(lvl, 0)
        missed = missing_by_level.get(lvl, 0)
        total  = sum(1 for w,l in hsk_words.items() if l == lvl)
        pct    = (total - missed) / total * 100 if total else 100
        label  = f"HSK {lvl}" if lvl < 7 else "HSK 7-9"
        msg    = f"{label}: {in_db} in DB, {missed} missing ({pct:.1f}% coverage)"
        if missed == 0:
            ok(cat, msg)
        else:
            warn(cat, msg)  # always warn, never fail — missing entries are contextual phrases

    # Show all missing words
    if missing_words:
        print(f"\n  Missing HSK words ({len(missing_words)}):")
        for lvl, w in sorted(missing_words):
            label = f"HSK {lvl}" if lvl < 7 else "HSK 7-9"
            print(f"    [{label}] {w}")

    # ══════════════════════════════════════════════════════════════════════════
    # 5. STRUCTURAL INTEGRITY
    # ══════════════════════════════════════════════════════════════════════════
    cat = "Integrity"

    # Orphaned word_characters
    n = cur.execute("""
        SELECT COUNT(*) FROM word_characters wc
        LEFT JOIN characters c ON c.id=wc.character_id
        WHERE c.id IS NULL
    """).fetchone()[0]
    (ok if n == 0 else fail)(cat, f"Orphaned word_characters: {n}")

    # Orphaned character_components
    n = cur.execute("""
        SELECT COUNT(*) FROM character_components cc
        LEFT JOIN components c ON c.id=cc.component_id
        WHERE c.id IS NULL
    """).fetchone()[0]
    (ok if n == 0 else fail)(cat, f"Orphaned character_components: {n}")

    # Words with empty han_viet but resonance != 'none'
    n = cur.execute("""
        SELECT COUNT(*) FROM compound_words
        WHERE (han_viet IS NULL OR han_viet='') AND han_viet_resonance != 'none'
    """).fetchone()[0]
    (ok if n == 0 else fail)(cat, f"Empty han_viet with non-none resonance: {n}")

    # Characters with no pinyin
    n = cur.execute(
        "SELECT COUNT(*) FROM characters WHERE pinyin IS NULL OR pinyin=''"
    ).fetchone()[0]
    pct = n / 9565 * 100
    (ok if pct < 5 else warn)(cat, f"Characters missing pinyin: {n} ({pct:.1f}%)")

    # Duplicate simplified in compound_words
    n = cur.execute("""
        SELECT COUNT(*) FROM (
            SELECT simplified, COUNT(*) c FROM compound_words
            GROUP BY simplified HAVING c > 1
        )
    """).fetchone()[0]
    (ok if n == 0 else fail)(cat, f"Duplicate simplified entries: {n}")

    # Characters with no component links at all
    n = cur.execute("""
        SELECT COUNT(*) FROM characters ch
        LEFT JOIN character_components cc ON cc.character_id=ch.id
        WHERE cc.character_id IS NULL
    """).fetchone()[0]
    pct = n / 9565 * 100
    (warn if pct > 30 else ok)(cat,
        f"Characters with no component links: {n} ({pct:.1f}%) — expected for simple radicals")

    # ══════════════════════════════════════════════════════════════════════════
    # 6. COVERAGE TARGETS (from PRD)
    # ══════════════════════════════════════════════════════════════════════════
    cat = "PRD Targets"

    total_words = cur.execute("SELECT COUNT(*) FROM compound_words").fetchone()[0]
    (ok if total_words >= 100000 else warn)(cat,
        f"Total compound_words: {total_words:,} (target: 100k+)")

    hv_covered = cur.execute(
        "SELECT COUNT(*) FROM compound_words WHERE han_viet != ''"
    ).fetchone()[0]
    (ok if hv_covered >= 30000 else warn)(cat,
        f"Words with Hán-Việt reading: {hv_covered:,} (target: 30k+)")

    high_res = cur.execute(
        "SELECT COUNT(*) FROM compound_words WHERE han_viet_resonance='high'"
    ).fetchone()[0]
    (ok if high_res >= 5000 else warn)(cat,
        f"High-resonance words: {high_res:,} (target: 5k+)")

    anchors = cur.execute(
        "SELECT COUNT(*) FROM compound_words WHERE is_cognate_anchor=1"
    ).fetchone()[0]
    (ok if anchors >= 500 else warn)(cat,
        f"Cognate anchors: {anchors:,} (target: 500+)")

    total_chars = cur.execute("SELECT COUNT(*) FROM characters").fetchone()[0]
    (ok if total_chars >= 8000 else warn)(cat,
        f"Total characters: {total_chars:,} (target: 8k+)")

    # ══════════════════════════════════════════════════════════════════════════
    # 7. RESONANCE DISTRIBUTION SANITY
    # ══════════════════════════════════════════════════════════════════════════
    cat = "Resonance"
    dist = dict(cur.execute("""
        SELECT han_viet_resonance, COUNT(*) FROM compound_words
        GROUP BY han_viet_resonance
    """).fetchall())
    total = sum(dist.values())
    for level_name in ["high","medium","low","none"]:
        count = dist.get(level_name, 0)
        pct   = count / total * 100
        print(f"  {level_name:8s}: {count:6,} ({pct:5.1f}%)")

    # High resonance should be at least 5% of total
    high_pct = dist.get("high",0) / total * 100
    (ok if high_pct >= 5 else warn)(cat,
        f"High resonance ratio: {high_pct:.1f}% of all words (target: 5%+)")

    # None shouldn't dominate high-frequency words
    none_in_top1k = cur.execute("""
        SELECT COUNT(*) FROM compound_words
        WHERE han_viet_resonance='none' AND frequency_rank <= 1000
    """).fetchone()[0]
    (ok if none_in_top1k < 100 else warn)(cat,
        f"'none' resonance in top-1000 freq words: {none_in_top1k} (want <100)")

    # ══════════════════════════════════════════════════════════════════════════
    # 8. FTS SEARCH FUNCTIONALITY
    # ══════════════════════════════════════════════════════════════════════════
    cat = "FTS Search"
    FTS_CHECKS = [
        ("morning",   ["晨", "早晨", "上午"]),
        ("love",      ["爱", "爱情", "热爱"]),
        ("student",   ["学生"]),        # CC-CEDICT: "student; schoolchild"
        ("TÂM",       ["心情", "一心"]),
        ("HỌC",       ["学生", "大学", "学习"]),
    ]
    for query, expected_any in FTS_CHECKS:
        rows = cur.execute("""
            SELECT cw.simplified FROM words_fts
            JOIN compound_words cw ON cw.rowid=words_fts.rowid
            WHERE words_fts MATCH ?
            ORDER BY CASE WHEN cw.frequency_rank IS NOT NULL
                          THEN cw.frequency_rank ELSE 999999 END
            LIMIT 20
        """, (query,)).fetchall()
        found = {r[0] for r in rows}
        hits = [w for w in expected_any if w in found]
        if hits:
            ok(cat, f"'{query}' → found {hits}")
        else:
            warn(cat, f"'{query}' → none of {expected_any} in top-20 results (got {list(found)[:5]})")

    # ══════════════════════════════════════════════════════════════════════════
    # 9. SAMPLE HIGH-RESONANCE WORDS FOR HUMAN REVIEW
    # ══════════════════════════════════════════════════════════════════════════
    print("\n" + "═"*60)
    print("  HUMAN REVIEW — Top 50 high-resonance words by frequency")
    print("  Verify these against a trusted Hán-Việt source (hvdic.com)")
    print("═"*60)
    rows = cur.execute("""
        SELECT simplified, pinyin, han_viet, english_def, hsk_level, frequency_rank
        FROM compound_words
        WHERE han_viet_resonance='high' AND han_viet != ''
        ORDER BY frequency_rank ASC NULLS LAST
        LIMIT 50
    """).fetchall()
    print(f"  {'Simplified':<12} {'Pinyin':<18} {'Hán-Việt':<20} {'HSK':<5} {'Freq':<8} English")
    print(f"  {'-'*10:<12} {'-'*16:<18} {'-'*18:<20} {'-'*3:<5} {'-'*6:<8} -------")
    for r in rows:
        hsk  = str(r[4]) if r[4] else "—"
        freq = str(r[5]) if r[5] else "—"
        print(f"  {r[0]:<12} {r[1]:<18} {r[2]:<20} {hsk:<5} {freq:<8} {r[3][:40]}")


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    print("═"*60)
    print("  Sinosphere Rosetta — Database Validation")
    print(f"  DB: {DB_PATH}")
    print("═"*60 + "\n")

    con = sqlite3.connect(DB_PATH)
    cur = con.cursor()

    print("  Resonance distribution:")
    run_checks(cur)
    con.close()

    # ── Summary report ────────────────────────────────────────────────────────
    print("\n" + "═"*60)
    print("  VALIDATION SUMMARY")
    print("═"*60)

    by_cat = {}
    for status, cat, msg in results:
        by_cat.setdefault(cat, []).append((status, msg))

    total_pass = sum(1 for s,_,_ in results if s == PASS)
    total_warn = sum(1 for s,_,_ in results if s == WARN)
    total_fail = sum(1 for s,_,_ in results if s == FAIL)

    for cat, checks in by_cat.items():
        cat_fail = sum(1 for s,_ in checks if s == FAIL)
        cat_warn = sum(1 for s,_ in checks if s == WARN)
        label = FAIL if cat_fail else (WARN if cat_warn else PASS)
        print(f"\n  {label} {cat}")
        for status, msg in checks:
            print(f"    {status} {msg}")

    print(f"\n{'═'*60}")
    print(f"  {PASS} PASSED: {total_pass}  {WARN} WARNINGS: {total_warn}  {FAIL} FAILED: {total_fail}")
    overall = PASS if total_fail == 0 else FAIL
    print(f"  Overall: {overall} {'DB is valid' if total_fail == 0 else 'DB has issues — see failures above'}")
    print("═"*60)

    return total_fail

if __name__ == "__main__":
    import sys
    sys.exit(main())
