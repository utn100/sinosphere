#!/usr/bin/env python3
"""
tag_krdict.py — Enrich compound_words with Korean vocabulary verification data
and import native Korean words into a new korean_words table.

Source: combined_korean_vocabulary_list (NIKL 2003 + TOPIK 2015)
  github.com/julienshim/combined_korean_vocabulary_list/results.tsv

Effects:
  1. Sets compound_words.kr_verified = 1 for words found in the vocabulary list
  2. Updates compound_words.topik_level with accurate TOPIK levels (replaces HSK proxy)
  3. Sets compound_words.pos (part of speech)
  4. Inserts native Korean words (no hanja) into the korean_words table

Usage:
    python3 pipeline/tag_krdict.py                      # dry-run, show 20 samples
    python3 pipeline/tag_krdict.py --limit 50           # dry-run, 50 samples
    python3 pipeline/tag_krdict.py --apply              # write to full DB
    python3 pipeline/tag_krdict.py --apply --limit 100  # write first 100 rows (test)
    python3 pipeline/tag_krdict.py --tsv path/to/file.tsv --apply
"""

import argparse
import csv
import re
import sqlite3
import sys
import uuid
from pathlib import Path

# Add pipeline dir to path so we can import the romaja generator
sys.path.insert(0, str(Path(__file__).parent))
from generate_romaja import to_display_romaja

# ── Mappings ──────────────────────────────────────────────────────────────────

TOPIK_MAP = {
    'A': 1,   # Beginner / 초급
    'B': 3,   # Intermediate / 중급
    'C': 5,   # Advanced / 고급
}

POS_MAP = {
    '명사':   'noun',
    '동사':   'verb',
    '형용사': 'adjective',
    '부사':   'adverb',
    '대명사': 'pronoun',
    '수사':   'numeral',
    '접사':   'affix',
    '관형사': 'determiner',
    '감탄사': 'interjection',
    '조사':   'particle',
    '의존명사': 'bound noun',
    '보조동사': 'auxiliary verb',
    '보조형용사': 'auxiliary adjective',
}

# ── Helpers ───────────────────────────────────────────────────────────────────

_SUFFIX_RE = re.compile(r'\d+$')

def clean_word(word: str) -> str:
    """Strip trailing homonym numbers (가격03 → 가격) and whitespace."""
    return _SUFFIX_RE.sub('', word.strip())


def ensure_columns(cur: sqlite3.Cursor) -> None:
    """Add new columns to compound_words if not already present."""
    existing = {row[1] for row in cur.execute('PRAGMA table_info(compound_words)')}
    if 'kr_verified' not in existing:
        print('  Adding kr_verified column to compound_words…')
        cur.execute('ALTER TABLE compound_words ADD COLUMN kr_verified INTEGER DEFAULT 0')
    if 'pos' not in existing:
        print('  Adding pos column to compound_words…')
        cur.execute('ALTER TABLE compound_words ADD COLUMN pos TEXT')


def ensure_korean_words_table(cur: sqlite3.Cursor) -> None:
    """Create korean_words table if not present."""
    cur.execute('''
        CREATE TABLE IF NOT EXISTS korean_words (
            id             TEXT PRIMARY KEY,
            hangul         TEXT NOT NULL UNIQUE,
            romaja         TEXT,
            english_def    TEXT DEFAULT '',
            topik_level    INTEGER,
            pos            TEXT,
            frequency_rank INTEGER,
            nikl_level     TEXT
        )
    ''')


def load_tsv(path: Path) -> list[dict]:
    with open(path, encoding='utf-8', newline='') as f:
        reader = csv.DictReader(f, delimiter='\t')
        return list(reader)


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description='Tag compound_words with Korean vocabulary data and import native words')
    parser.add_argument('--db',    default='data/db/sinosphere.db')
    parser.add_argument('--tsv',   default='data/raw/combined_korean_vocab.tsv')
    parser.add_argument('--apply', action='store_true',
                        help='Write to DB (default: dry-run)')
    parser.add_argument('--limit', type=int, default=None,
                        help='Process at most N rows (default: all when --apply, 20 for dry-run)')
    args = parser.parse_args()

    dry_run = not args.apply
    limit   = args.limit if args.limit is not None else (20 if dry_run else None)

    db_path  = Path(args.db)
    tsv_path = Path(args.tsv)

    if not db_path.exists():
        print(f'DB not found: {db_path}', file=sys.stderr); sys.exit(1)
    if not tsv_path.exists():
        print(f'TSV not found: {tsv_path}', file=sys.stderr)
        print('Run: curl -L https://raw.githubusercontent.com/julienshim/'
              'combined_korean_vocabulary_list/refs/heads/master/results.tsv '
              f'-o {tsv_path}', file=sys.stderr)
        sys.exit(1)

    rows = load_tsv(tsv_path)
    if limit:
        rows = rows[:limit]
    print(f'Processing {len(rows):,} TSV rows{" (dry-run)" if dry_run else ""}…\n')

    conn = sqlite3.connect(db_path)
    cur  = conn.cursor()

    if not dry_run:
        ensure_columns(cur)
        ensure_korean_words_table(cur)

    # Build a lookup set of all hangul values in compound_words for fast matching
    existing_hangul = {
        row[0] for row in
        cur.execute('SELECT DISTINCT hangul FROM compound_words WHERE hangul IS NOT NULL').fetchall()
    }

    # Counters
    verified_updates = 0
    native_inserts   = 0
    skipped          = 0

    compound_updates: list[tuple] = []   # (topik, pos, kr_verified=1, hangul)
    native_rows: list[tuple] = []        # (id, hangul, romaja, topik, pos, freq, nikl)

    for row in rows:
        word = clean_word(row.get('word', ''))
        if not word:
            skipped += 1
            continue

        topik_letter = (row.get('topik_level') or '').strip()
        topik_num    = TOPIK_MAP.get(topik_letter)
        pos_kr       = (row.get('part_of_speech') or '').strip()
        pos_en       = POS_MAP.get(pos_kr, pos_kr or None)
        hanja        = (row.get('hanja') or '').strip()
        nikl         = (row.get('nikl_level') or '').strip() or None
        rank_str     = (row.get('rank') or '').strip()
        rank         = int(rank_str) if rank_str.isdigit() else None

        is_in_compound = word in existing_hangul

        if dry_run or (limit and limit <= 100):
            dest = 'compound_words' if is_in_compound else ('korean_words' if not hanja else 'skip (has hanja, not in DB)')
            topik_str = f'T{topik_num}' if topik_num else '—'
            print(f'  {word:<12} pos={pos_en or "—":<12} topik={topik_str:<4} hanja={hanja or "—":<8} → {dest}')

        if is_in_compound:
            compound_updates.append((topik_num, pos_en, word))
            verified_updates += 1
        elif not hanja:
            # Native Korean word not in compound_words → insert into korean_words
            romaja = to_display_romaja(word)
            native_rows.append((str(uuid.uuid4()), word, romaja, topik_num, pos_en, rank, nikl))
            native_inserts += 1
        else:
            skipped += 1

    print(f'\nSummary:')
    print(f'  compound_words to mark kr_verified=1: {verified_updates:,}')
    print(f'  korean_words to insert (native):      {native_inserts:,}')
    print(f'  skipped (no match + has hanja):       {skipped:,}')

    if not dry_run:
        print(f'\nWriting to DB…')

        # Mark kr_verified, update topik_level (only if we have one), and pos
        cur.executemany(
            '''UPDATE compound_words
               SET kr_verified = 1,
                   topik_level = COALESCE(?, topik_level),
                   pos = ?
               WHERE hangul = ?''',
            compound_updates,
        )

        # Insert native Korean words
        cur.executemany(
            '''INSERT OR IGNORE INTO korean_words
               (id, hangul, romaja, topik_level, pos, frequency_rank, nikl_level)
               VALUES (?, ?, ?, ?, ?, ?, ?)''',
            native_rows,
        )

        conn.commit()
        print(f'Done.')
        print(f'  {verified_updates:,} compound_words updated (kr_verified=1)')
        print(f'  {native_inserts:,} native Korean words inserted into korean_words')
    else:
        print(f'\nDry-run — no changes written. Run with --apply to write to DB.')

    conn.close()


if __name__ == '__main__':
    main()
