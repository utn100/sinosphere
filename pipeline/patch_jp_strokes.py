"""
patch_jp_strokes.py — backfills jp_onyomi and stroke_count in characters table from Unihan.
"""
import sqlite3, zipfile

DB_PATH   = "data/db/sinosphere.db"
READINGS  = "data/raw/unihan/Unihan_Readings.txt"
UNIHAN_ZIP = "data/raw/Unihan.zip"

def codepoint_to_char(cp: str) -> str:
    return chr(int(cp[2:], 16))

def load_readings(path):
    jp: dict[str, str] = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            if line.startswith("#") or not line.strip():
                continue
            parts = line.rstrip("\n").split("\t")
            if len(parts) != 3:
                continue
            cp, field, value = parts
            if field == "kJapaneseOn":
                jp[codepoint_to_char(cp)] = value.strip()
    return jp

def load_strokes(zip_path):
    strokes: dict[str, int] = {}
    with zipfile.ZipFile(zip_path) as z:
        with z.open("Unihan_IRGSources.txt") as f:
            for raw in f:
                line = raw.decode("utf-8")
                if line.startswith("#") or not line.strip():
                    continue
                parts = line.rstrip("\n").split("\t")
                if len(parts) != 3:
                    continue
                cp, field, value = parts
                if field == "kTotalStrokes":
                    try:
                        strokes[codepoint_to_char(cp)] = int(value.strip().split()[0])
                    except ValueError:
                        pass
    return strokes

def main():
    print("Loading Unihan readings…")
    jp = load_readings(READINGS)
    print(f"  kJapaneseOn: {len(jp):,} characters")

    print("Loading Unihan stroke counts…")
    strokes = load_strokes(UNIHAN_ZIP)
    print(f"  kTotalStrokes: {len(strokes):,} characters")

    con = sqlite3.connect(DB_PATH)
    cur = con.cursor()

    symbols = cur.execute("SELECT id, symbol FROM characters").fetchall()
    print(f"Patching {len(symbols):,} characters…")

    updated_jp      = 0
    updated_strokes = 0

    for char_id, symbol in symbols:
        onyomi = jp.get(symbol)
        stroke = strokes.get(symbol)
        if onyomi or stroke:
            cur.execute(
                "UPDATE characters SET jp_onyomi = COALESCE(?, jp_onyomi), "
                "stroke_count = CASE WHEN ? > 0 THEN ? ELSE stroke_count END "
                "WHERE id = ?",
                (onyomi, stroke or 0, stroke or 0, char_id),
            )
            if onyomi:  updated_jp      += 1
            if stroke:  updated_strokes += 1

    con.commit()

    total   = cur.execute("SELECT COUNT(*) FROM characters").fetchone()[0]
    has_jp  = cur.execute("SELECT COUNT(*) FROM characters WHERE jp_onyomi IS NOT NULL AND jp_onyomi != ''").fetchone()[0]
    has_st  = cur.execute("SELECT COUNT(*) FROM characters WHERE stroke_count > 0").fetchone()[0]

    for sym in ["晨", "好", "明", "日"]:
        row = cur.execute("SELECT symbol, jp_onyomi, stroke_count FROM characters WHERE symbol=?", (sym,)).fetchone()
        if row:
            print(f"  {row[0]}: jp={row[1]}, strokes={row[2]}")

    con.close()
    print(f"\nDone. {updated_jp:,} jp_onyomi, {updated_strokes:,} stroke_count updated.")
    print(f"Coverage: jp={has_jp}/{total} ({has_jp/total*100:.1f}%), strokes={has_st}/{total} ({has_st/total*100:.1f}%)")

if __name__ == "__main__":
    main()
