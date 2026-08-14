"""
Sinosphere Rosetta — Hán-Việt Reading Patch
Fills missing han_viet readings in the characters table using:
  1. Unihan kTraditionalVariant → kVietnamese  (432 chars)
  2. Thiều Chửu + Trần Văn Chánh dictionary   (fills most of the rest)
  3. HanziStoriesViet                          (catches any remainder)

Non-destructive: only updates chars where han_viet is currently empty.
Safe to run multiple times.

Run:
    python3 pipeline/patch_hanviet.py
"""

import re
import sqlite3
from pathlib import Path

ROOT    = Path(__file__).parent.parent
DB_PATH = ROOT / "data" / "db" / "sinosphere.db"
RAW     = ROOT / "data" / "raw"

UNIHAN_READINGS  = RAW / "unihan" / "Unihan_Readings.txt"
UNIHAN_VARIANTS  = RAW / "unihan" / "Unihan_Variants.txt"
THIENCHUU        = RAW / "tudien" / "ThienChuu_TranVanChanh.tab"
HANZI_STORIES    = RAW / "tudien" / "HanziStoriesViet.tab"


def load_unihan_hv() -> dict[str, str]:
    """Load Unihan kVietnamese map: char → uppercase HV reading."""
    hv = {}
    with open(UNIHAN_READINGS, encoding="utf-8") as f:
        for line in f:
            if "kVietnamese" not in line or not line.startswith("U+"):
                continue
            parts = line.strip().split("\t")
            if len(parts) < 3 or parts[1] != "kVietnamese":
                continue
            ch = chr(int(parts[0][2:], 16))
            hv[ch] = parts[2].split()[0].upper()
    return hv


def load_trad_variant_map() -> dict[str, str]:
    """Load Unihan kTraditionalVariant: simplified char → traditional char."""
    s2t = {}
    with open(UNIHAN_VARIANTS, encoding="utf-8") as f:
        for line in f:
            if "kTraditionalVariant" not in line or not line.startswith("U+"):
                continue
            parts = line.strip().split("\t")
            if len(parts) < 3 or parts[1] != "kTraditionalVariant":
                continue
            simp = chr(int(parts[0][2:], 16))
            trad = chr(int(parts[2].split()[0][2:], 16))
            s2t[simp] = trad
    return s2t


def load_thienchuu() -> dict[str, str]:
    """Load Thiều Chửu + Trần Văn Chánh: char → uppercase HV reading."""
    hv = {}
    with open(THIENCHUU, encoding="utf-8") as f:
        for line in f:
            parts = line.strip().split("\t", 1)
            if len(parts) < 2 or not parts[0].strip():
                continue
            char = parts[0].strip()
            m = re.match(r'\[([^\]]+)\]', parts[1])
            if m:
                reading = m.group(1).strip().split(",")[0].strip().upper()
                hv[char] = reading
    return hv


def load_hanzi_stories_hv() -> dict[str, str]:
    """Load HanziStoriesViet: char → uppercase HV reading."""
    hv = {}
    with open(HANZI_STORIES, encoding="utf-8") as f:
        for line in f:
            parts = line.strip().split("\t", 1)
            if len(parts) < 2 or not parts[0].strip():
                continue
            char = parts[0].strip()
            m = re.search(r'<b>HÁN VIỆT </b>([^<]+)', parts[1])
            if m:
                reading = m.group(1).strip().split(",")[0].strip().upper()
                hv[char] = reading
    return hv


def main():
    print("=== Sinosphere Rosetta — Hán-Việt Reading Patch ===\n")

    # ── Load all sources ──────────────────────────────────────────────────────
    print("Loading sources...")
    unihan_hv  = load_unihan_hv()
    s2t_map    = load_trad_variant_map()
    thienchuu  = load_thienchuu()
    hanzi_hv   = load_hanzi_stories_hv()
    print(f"  Unihan kVietnamese:       {len(unihan_hv):,}")
    print(f"  Simp→Trad variants:       {len(s2t_map):,}")
    print(f"  Thiều Chửu:               {len(thienchuu):,}")
    print(f"  HanziStoriesViet:         {len(hanzi_hv):,}")

    # ── Build resolution function ─────────────────────────────────────────────
    def resolve(char: str) -> tuple[str, str] | None:
        """Return (reading, source) or None."""
        # 1. Direct Unihan kVietnamese
        if char in unihan_hv:
            return unihan_hv[char], "unihan_direct"
        # 2. Via traditional variant → Unihan
        trad = s2t_map.get(char)
        if trad and trad in unihan_hv:
            return unihan_hv[trad], "unihan_via_trad"
        # 3. Thiều Chửu
        if char in thienchuu:
            return thienchuu[char], "thienchuu"
        # 4. HanziStoriesViet
        if char in hanzi_hv:
            return hanzi_hv[char], "hanzi_stories"
        return None

    # ── Load missing chars from DB ────────────────────────────────────────────
    con = sqlite3.connect(DB_PATH)

    before = con.execute(
        "SELECT COUNT(*) FROM characters WHERE han_viet != '' AND han_viet IS NOT NULL"
    ).fetchone()[0]
    total = con.execute("SELECT COUNT(*) FROM characters").fetchone()[0]

    missing = con.execute("""
        SELECT id, symbol FROM characters
        WHERE han_viet = '' OR han_viet IS NULL
    """).fetchall()

    print(f"\nDB status before patch:")
    print(f"  Total characters:         {total:,}")
    print(f"  Already have HV reading:  {before:,}")
    print(f"  Missing HV reading:       {len(missing):,}")

    # ── Resolve and patch ─────────────────────────────────────────────────────
    source_counts: dict[str, int] = {}
    patched = 0
    still_missing = []

    updates = []
    for char_id, symbol in missing:
        result = resolve(symbol)
        if result:
            reading, source = result
            updates.append((reading, char_id))
            source_counts[source] = source_counts.get(source, 0) + 1
            patched += 1
        else:
            still_missing.append(symbol)

    con.executemany(
        "UPDATE characters SET han_viet = ? WHERE id = ?",
        updates
    )
    con.commit()

    # ── Report ────────────────────────────────────────────────────────────────
    after = con.execute(
        "SELECT COUNT(*) FROM characters WHERE han_viet != '' AND han_viet IS NOT NULL"
    ).fetchone()[0]

    print(f"\nPatch results:")
    print(f"  Patched:                  {patched:,}")
    for src, count in sorted(source_counts.items(), key=lambda x: -x[1]):
        label = {
            "unihan_direct":   "  Unihan direct",
            "unihan_via_trad": "  Unihan via trad variant",
            "thienchuu":       "  Thiều Chửu",
            "hanzi_stories":   "  HanziStoriesViet",
        }.get(src, src)
        print(f"    {label:<28}: {count:,}")
    print(f"  Still missing:            {len(still_missing):,}")

    print(f"\nDB status after patch:")
    print(f"  Have HV reading:          {after:,} / {total:,} ({after/total*100:.1f}%)")

    # ── Check HSK coverage specifically ───────────────────────────────────────
    hsk_missing_after = con.execute("""
        SELECT COUNT(DISTINCT c.id)
        FROM characters c
        JOIN word_characters wc ON wc.character_id = c.id
        JOIN compound_words cw ON cw.id = wc.word_id
        WHERE (c.han_viet = '' OR c.han_viet IS NULL)
        AND cw.hsk_level IS NOT NULL
    """).fetchone()[0]
    print(f"  HSK chars still missing:  {hsk_missing_after:,}  (target: 0)")

    if still_missing:
        print(f"\nSample of {min(10, len(still_missing))} unresolved chars:")
        for sym in still_missing[:10]:
            print(f"  {sym}")

    # ── Spot-check a few patched readings ─────────────────────────────────────
    print("\nSpot-check — sample patched readings:")
    checks = ["做", "北", "国", "很", "树", "妈", "她", "告", "净", "别"]
    for sym in checks:
        row = con.execute(
            "SELECT han_viet FROM characters WHERE symbol = ?", (sym,)
        ).fetchone()
        if row:
            print(f"  {sym} → {row[0] or '(still empty)'}")

    con.close()
    print("\nDone.")


if __name__ == "__main__":
    main()
