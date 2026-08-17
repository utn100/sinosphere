#!/usr/bin/env python3
"""
tag_sino_korean.py — populate is_sino_korean and batchim on compound_words.

  is_sino_korean: 1 if the word has a valid hangul reading (i.e. it IS a Sino-Korean
                  word — the hangul column stores Korean readings of Chinese characters).
                  0 otherwise.

  batchim:        1 if the last hangul syllable ends with a final consonant (받침).
                  0 if the word ends with an open syllable.

Usage:
    python3 pipeline/tag_sino_korean.py              # dry-run: print 20 samples
    python3 pipeline/tag_sino_korean.py --limit 50   # dry-run with 50 samples
    python3 pipeline/tag_sino_korean.py --apply      # write to full DB (fast, rule-based)
    python3 pipeline/tag_sino_korean.py --apply --limit 100  # write only first 100 rows
    python3 pipeline/tag_sino_korean.py --db path/to/sinosphere.db --apply
"""

import argparse
import sqlite3
import sys
from pathlib import Path

HANGUL_BASE = 0xAC00
HANGUL_END  = 0xD7A3


def is_hangul_syllable(ch: str) -> bool:
    return HANGUL_BASE <= ord(ch) <= HANGUL_END


def has_batchim(hangul: str) -> bool:
    """Return True if the last hangul syllable has a final consonant (받침)."""
    if not hangul:
        return False
    # Find the last hangul syllable in the string
    last_hangul = None
    for ch in reversed(hangul):
        if is_hangul_syllable(ch):
            last_hangul = ch
            break
    if last_hangul is None:
        return False
    code = ord(last_hangul) - HANGUL_BASE
    jongseong_index = code % 28
    return jongseong_index != 0  # 0 means no final consonant


def is_valid_hangul(hangul: str) -> bool:
    """Return True if the string contains at least one proper Hangul syllable block."""
    return any(is_hangul_syllable(ch) for ch in hangul)


def ensure_column(cur: sqlite3.Cursor, column: str, col_type: str) -> None:
    existing = {row[1] for row in cur.execute('PRAGMA table_info(compound_words)')}
    if column not in existing:
        print(f'  Adding {column} column…')
        cur.execute(f'ALTER TABLE compound_words ADD COLUMN {column} {col_type}')


def main() -> None:
    parser = argparse.ArgumentParser(
        description='Tag compound_words with is_sino_korean and batchim')
    parser.add_argument('--db',    default='data/db/sinosphere.db')
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

    conn = sqlite3.connect(db_path)
    cur  = conn.cursor()

    if not dry_run:
        ensure_column(cur, 'is_sino_korean', 'INTEGER')
        ensure_column(cur, 'batchim',        'INTEGER')

    query = 'SELECT id, hangul FROM compound_words'
    if limit:
        query += f' LIMIT {limit}'

    rows = cur.execute(query).fetchall()
    print(f'Processing {len(rows):,} rows{"" if not limit else f" (limit {limit})"}…\n')

    updates: list[tuple[int, int, str]] = []
    sino_count   = 0
    batchim_count = 0

    for word_id, hangul in rows:
        sino   = 1 if (hangul and is_valid_hangul(hangul)) else 0
        bat    = 1 if (sino and has_batchim(hangul)) else 0
        updates.append((sino, bat, word_id))
        if sino:
            sino_count += 1
        if bat:
            batchim_count += 1
        if dry_run or (limit and limit <= 100):
            tag = []
            if sino: tag.append('sino-korean')
            if bat:  tag.append('batchim')
            print(f'  {str(hangul or ""):<12} sino={sino}  batchim={bat}  {", ".join(tag)}')

    print(f'\nSummary:')
    print(f'  Sino-Korean (is_sino_korean=1): {sino_count:,} / {len(rows):,}')
    print(f'  Has batchim:                    {batchim_count:,} / {sino_count:,} sino-korean words')

    if not dry_run:
        print(f'\nWriting {len(updates):,} rows…')
        cur.executemany(
            'UPDATE compound_words SET is_sino_korean = ?, batchim = ? WHERE id = ?',
            updates,
        )
        conn.commit()
        print(f'Done.')
    else:
        print(f'\nDry-run — no changes written. Run with --apply to write to DB.')

    conn.close()


if __name__ == '__main__':
    main()
