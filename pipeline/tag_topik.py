#!/usr/bin/env python3
"""
tag_topik.py — populate compound_words.topik_level.

Two modes:
  1. CSV mode (recommended): provide a TOPIK word list CSV with columns
     'hangul' and 'topik_level'. Maps hangul readings to TOPIK level.

     CSV format (no header required if using --csv-no-header):
       학교,1
       전화,1
       시간,1
       음악,2
       ...

  2. HSK proxy mode (default, no CSV): derives a TOPIK-equivalent level
     from hsk_level using a conservative mapping:
       HSK 1 → TOPIK 1
       HSK 2 → TOPIK 2
       HSK 3 → TOPIK 2
       HSK 4 → TOPIK 3
       HSK 5 → TOPIK 4
       HSK 6 → TOPIK 5
       HSK 7+ → TOPIK 6
       no HSK → NULL (not tagged)

     This is a rough approximation. Replace with a real TOPIK CSV when available.

Usage:
    python3 pipeline/tag_topik.py                        # dry-run, HSK proxy
    python3 pipeline/tag_topik.py --limit 50             # dry-run, 50 rows
    python3 pipeline/tag_topik.py --apply                # write HSK proxy to full DB
    python3 pipeline/tag_topik.py --csv topik_words.csv --apply  # use real TOPIK CSV
    python3 pipeline/tag_topik.py --db path/to/sinosphere.db --apply
"""

import argparse
import csv
import sqlite3
import sys
from pathlib import Path

# HSK → TOPIK proxy mapping (conservative — TOPIK tends to be harder at same level)
HSK_TO_TOPIK: dict[int, int] = {
    1: 1,
    2: 2,
    3: 2,
    4: 3,
    5: 4,
    6: 5,
    7: 6,
    8: 6,
    9: 6,
}


def load_topik_csv(csv_path: Path) -> dict[str, int]:
    """Load a TOPIK word list CSV → {hangul: topik_level}."""
    mapping: dict[str, int] = {}
    with open(csv_path, encoding='utf-8', newline='') as f:
        reader = csv.reader(f)
        for row in reader:
            if len(row) < 2:
                continue
            hangul, level_str = row[0].strip(), row[1].strip()
            try:
                mapping[hangul] = int(level_str)
            except ValueError:
                # Skip header row or malformed entries
                continue
    return mapping


def ensure_column(cur: sqlite3.Cursor, column: str, col_type: str) -> None:
    existing = {row[1] for row in cur.execute('PRAGMA table_info(compound_words)')}
    if column not in existing:
        print(f'  Adding {column} column…')
        cur.execute(f'ALTER TABLE compound_words ADD COLUMN {column} {col_type}')


def main() -> None:
    parser = argparse.ArgumentParser(description='Tag compound_words with topik_level')
    parser.add_argument('--db',    default='data/db/sinosphere.db')
    parser.add_argument('--csv',   default=None,
                        help='Path to TOPIK word list CSV (hangul,topik_level per row)')
    parser.add_argument('--apply', action='store_true',
                        help='Write to DB (default: dry-run)')
    parser.add_argument('--limit', type=int, default=None,
                        help='Process at most N rows (default: all when --apply, 20 for dry-run)')
    args = parser.parse_args()

    dry_run = not args.apply
    limit   = args.limit if args.limit is not None else (20 if dry_run else None)

    db_path = Path(args.db)
    if not db_path.exists():
        print(f'DB not found: {db_path}', file=sys.stderr)
        sys.exit(1)

    # Load CSV mapping if provided
    topik_csv_map: dict[str, int] = {}
    if args.csv:
        csv_path = Path(args.csv)
        if not csv_path.exists():
            print(f'CSV not found: {csv_path}', file=sys.stderr)
            sys.exit(1)
        topik_csv_map = load_topik_csv(csv_path)
        print(f'Loaded {len(topik_csv_map):,} entries from TOPIK CSV.')
        mode = 'csv'
    else:
        print('No CSV provided — using HSK proxy mapping (HSK 1→T1, 2-3→T2, 4→T3, 5→T4, 6→T5, 7+→T6).')
        mode = 'proxy'

    conn = sqlite3.connect(db_path)
    cur  = conn.cursor()

    if not dry_run:
        ensure_column(cur, 'topik_level', 'INTEGER')

    query = 'SELECT id, hangul, hsk_level FROM compound_words'
    if limit:
        query += f' LIMIT {limit}'

    rows = cur.execute(query).fetchall()
    print(f'Processing {len(rows):,} rows{"" if not limit else f" (limit {limit})"}…\n')

    updates: list[tuple[int | None, str]] = []
    level_counts: dict[int | None, int] = {}

    for word_id, hangul, hsk_level in rows:
        topik: int | None = None

        if mode == 'csv' and hangul and hangul in topik_csv_map:
            topik = topik_csv_map[hangul]
        elif mode == 'proxy' and hsk_level is not None:
            topik = HSK_TO_TOPIK.get(hsk_level)

        updates.append((topik, word_id))
        level_counts[topik] = level_counts.get(topik, 0) + 1

        if dry_run or (limit and limit <= 100):
            print(f'  {str(hangul or ""):<12} hsk={str(hsk_level or ""):<4} → topik={topik}')

    print(f'\nTOPIK level distribution:')
    for level in sorted(k for k in level_counts if k is not None):
        print(f'  TOPIK {level}: {level_counts[level]:>7,}')
    print(f'  Untagged:   {level_counts.get(None, 0):>7,}')

    if not dry_run:
        print(f'\nWriting {len(updates):,} rows…')
        cur.executemany(
            'UPDATE compound_words SET topik_level = ? WHERE id = ?',
            updates,
        )
        conn.commit()
        print(f'Done.')
        if mode == 'proxy':
            print(
                '\nNote: topik_level populated via HSK proxy. For accurate TOPIK levels,\n'
                'obtain a TOPIK word list CSV and re-run with --csv topik_words.csv --apply.'
            )
    else:
        print(f'\nDry-run — no changes written. Run with --apply to write to DB.')

    conn.close()


if __name__ == '__main__':
    main()
