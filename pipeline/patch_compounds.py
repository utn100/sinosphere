"""
Sinosphere Rosetta — Compound Hán-Việt Recompute Patch
After patch_hanviet.py fills missing character HV readings,
this script recomputes han_viet for all compound_words that
still have '?' placeholders or empty segments.

Non-destructive: only updates compounds where reconstruction
produces a better result than what's currently stored.

Run AFTER patch_hanviet.py:
    python3 pipeline/patch_compounds.py
"""

import sqlite3
from pathlib import Path

ROOT    = Path(__file__).parent.parent
DB_PATH = ROOT / "data" / "db" / "sinosphere.db"

def is_cjk(ch: str) -> bool:
    return '一' <= ch <= '鿿' or '㐀' <= ch <= '䶿'

def build_compound_hanviet(simplified: str, hv_map: dict[str, str]) -> tuple[str, bool]:
    """
    Reconstruct HV for a compound. Returns (hanviet_string, is_complete).
    Uses '?' for any CJK char still missing a reading.
    """
    parts = []
    complete = True
    for ch in simplified:
        if is_cjk(ch):
            hv = hv_map.get(ch)
            if hv:
                parts.append(hv)
            else:
                parts.append("?")
                complete = False
    return " ".join(parts) if parts else "", complete

def score_resonance(simplified: str, han_viet: str, is_complete: bool,
                    hv_map: dict[str, str]) -> str:
    """Simplified resonance scoring (mirrors build_db.py logic)."""
    if not han_viet or han_viet == "?":
        return "none"
    cjk_chars = [c for c in simplified if is_cjk(c)]
    if not cjk_chars:
        return "none"
    covered = sum(1 for c in cjk_chars if c in hv_map)
    coverage = covered / len(cjk_chars)
    if coverage == 0:
        return "none"
    real_parts = [p for p in han_viet.upper().split() if p != "?"]
    if not real_parts:
        return "none"
    if is_complete and coverage >= 0.9:
        return "high"
    elif coverage >= 0.5:
        return "medium"
    else:
        return "low"

def main():
    print("=== Sinosphere Rosetta — Compound HV Recompute Patch ===\n")

    con = sqlite3.connect(DB_PATH)

    # Load full char→HV map from the now-patched characters table
    hv_map = dict(con.execute(
        "SELECT symbol, han_viet FROM characters WHERE han_viet != '' AND han_viet IS NOT NULL"
    ).fetchall())
    print(f"Character HV map loaded: {len(hv_map):,} entries")

    # Find compounds that need updating:
    # - currently have '?' in han_viet, OR
    # - han_viet is empty but the chars now have readings
    compounds = con.execute("""
        SELECT id, simplified, han_viet, han_viet_resonance
        FROM compound_words
    """).fetchall()
    print(f"Total compound words:    {len(compounds):,}")

    updates = []
    resonance_updates = []
    improved = 0
    newly_complete = 0

    for wid, simp, old_hv, old_res in compounds:
        new_hv, is_complete = build_compound_hanviet(simp, hv_map)

        if not new_hv:
            continue

        # Only update if the new result is better than what's stored
        old_has_placeholder = "?" in (old_hv or "")
        new_has_placeholder = "?" in new_hv
        was_empty = not old_hv or old_hv == ""

        if was_empty or old_has_placeholder:
            if new_hv != old_hv:
                new_res = score_resonance(simp, new_hv, is_complete, hv_map)
                updates.append((new_hv, new_res, wid))
                improved += 1
                if old_has_placeholder and not new_has_placeholder:
                    newly_complete += 1

    print(f"\nCompounds to update:     {improved:,}")
    print(f"  Placeholders resolved: {newly_complete:,}")

    if updates:
        con.executemany(
            "UPDATE compound_words SET han_viet=?, han_viet_resonance=? WHERE id=?",
            updates
        )
        con.commit()

    # ── Stats after ───────────────────────────────────────────────────────────
    still_placeholder = con.execute(
        "SELECT COUNT(*) FROM compound_words WHERE han_viet LIKE '%?%'"
    ).fetchone()[0]
    empty_hv = con.execute(
        "SELECT COUNT(*) FROM compound_words WHERE han_viet = '' OR han_viet IS NULL"
    ).fetchone()[0]
    total = con.execute("SELECT COUNT(*) FROM compound_words").fetchone()[0]

    dist = dict(con.execute("""
        SELECT han_viet_resonance, COUNT(*) FROM compound_words
        GROUP BY han_viet_resonance
    """).fetchall())

    print(f"\nAfter patch:")
    print(f"  Compounds with '?' placeholder: {still_placeholder:,}")
    print(f"  Compounds with empty HV:        {empty_hv:,}")
    print(f"  Total compounds:                {total:,}")
    print(f"\n  Resonance breakdown:")
    for level in ["high", "medium", "low", "none"]:
        print(f"    {level:8s}: {dist.get(level, 0):,}")

    # Spot-check
    print("\nSpot-check:")
    for word in ["特别", "别人", "告别", "区别", "离别", "做到", "妈妈", "北京", "国家", "树木"]:
        row = con.execute(
            "SELECT simplified, han_viet, han_viet_resonance FROM compound_words WHERE simplified=?",
            (word,)
        ).fetchone()
        if row:
            print(f"  {row[0]:6s} → {row[1]:25s} [{row[2]}]")

    con.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
