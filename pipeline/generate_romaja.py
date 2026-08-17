#!/usr/bin/env python3
"""
generate_romaja.py — populate compound_words.romaja using Revised Romanization of Korean.

Usage:
    python3 pipeline/generate_romaja.py              # dry-run: print 20 samples, no DB writes
    python3 pipeline/generate_romaja.py --limit 50   # dry-run with 50 samples
    python3 pipeline/generate_romaja.py --apply      # write romaja to full DB (~5 min)
    python3 pipeline/generate_romaja.py --apply --limit 100  # write only first 100 rows (test)
    python3 pipeline/generate_romaja.py --db path/to/sinosphere.db --apply
"""

import argparse
import sqlite3
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Revised Romanization of Korean (국어의 로마자 표기법)
# Reference: https://www.korean.go.kr/front_eng/roman/roman_01.do
# ---------------------------------------------------------------------------

# Initial consonants (초성) — 19 values indexed 0–18
CHOSEONG = [
    'g', 'kk', 'n', 'd', 'tt', 'r', 'm', 'b', 'pp',
    's', 'ss', '', 'j', 'jj', 'ch', 'k', 't', 'p', 'h',
]

# Vowels (중성) — 21 values indexed 0–20
JUNGSEONG = [
    'a', 'ae', 'ya', 'yae', 'eo', 'e', 'yeo', 'ye', 'o',
    'wa', 'wae', 'oe', 'yo', 'u', 'wo', 'we', 'wi', 'yu',
    'eu', 'ui', 'i',
]

# Final consonants (종성) — 28 values indexed 0–27 (0 = no batchim)
# Revised Romanization: final ㄱ→k, ㄷ→t, ㅂ→p, ㄹ→l
JONGSEONG = [
    '',   'k',  'k',  'k',  'n',  'n',  'n',  't',  'l',
    'k',  'lm', 'l',  'l',  'l',  'p',  'l',  'm',  'p',
    'p',  't',  't',  'ng', 't',  't',  'k',  't',  'p',  'k',
]

# Batchim (종성) romanization when followed by a vowel — liaison rules
JONGSEONG_LIAISON = [
    '',   'g',  'kk', 'gs', 'n',  'nj', 'nh', 'd',  'r',
    'lg', 'lm', 'lb', 'ls', 'lt', 'lp', 'lh', 'm',  'b',
    'bs', 's',  'ss', 'ng', 'j',  'ch', 'k',  't',  'p',  'h',
]

HANGUL_BASE = 0xAC00
HANGUL_END  = 0xD7A3


def is_hangul_syllable(ch: str) -> bool:
    return HANGUL_BASE <= ord(ch) <= HANGUL_END


def decompose(ch: str) -> tuple[int, int, int]:
    """Decompose a Hangul syllable into (choseong, jungseong, jongseong) indices."""
    code = ord(ch) - HANGUL_BASE
    jong = code % 28
    jung = (code // 28) % 21
    cho  = code // 28 // 21
    return cho, jung, jong


def hangul_to_romaja(text: str) -> str:
    """Convert a Hangul string to Revised Romanization."""
    if not text:
        return ''

    result: list[str] = []
    syllables = list(text)
    n = len(syllables)

    for i, ch in enumerate(syllables):
        if not is_hangul_syllable(ch):
            # Pass through non-Hangul characters (spaces, hyphens, etc.)
            result.append(ch)
            continue

        cho, jung, jong = decompose(ch)
        next_ch = syllables[i + 1] if i + 1 < n else None

        # Check if next syllable is Hangul and starts with no initial consonant (ㅇ, index 11)
        next_is_vowel_initial = (
            next_ch is not None
            and is_hangul_syllable(next_ch)
            and decompose(next_ch)[0] == 11  # ㅇ as choseong is silent
        )

        initial = CHOSEONG[cho]
        vowel   = JUNGSEONG[jung]

        if jong == 0:
            # No batchim
            result.append(initial + vowel)
        elif next_is_vowel_initial:
            # Liaison: batchim moves to next syllable's onset
            result.append(initial + vowel)
            result.append(JONGSEONG_LIAISON[jong])
            # Skip the ㅇ initial of the next syllable; handled by liaison prefix
            # We prepend the liaison to next iteration via a lookahead buffer
            # Actually we handle this by injecting into result now and flagging
            # Simpler: just append liaison here; next iteration will append '' + vowel
            # which is correct because CHOSEONG[11] = ''
        else:
            # Batchim present, next is consonant-initial or end of word
            result.append(initial + vowel + JONGSEONG[jong])

    romanized = ''.join(result)

    # Post-processing: aspirate stops before 'h' (simplified)
    # ㄱ+ㅎ = k, ㄷ+ㅎ = t, ㅂ+ㅎ = p, ㅈ+ㅎ = ch
    romanized = romanized.replace('gh', 'k').replace('dh', 't')
    romanized = romanized.replace('bh', 'p').replace('jh', 'ch')

    # Insert hyphens between syllables for readability (optional but standard in app)
    return romanized


def to_display_romaja(text: str) -> str:
    """Convert hangul word to hyphenated romaja syllable display (e.g. 학교 → hak-gyo)."""
    if not text:
        return ''

    parts: list[str] = []
    buf: list[str] = []

    for ch in text:
        if is_hangul_syllable(ch):
            cho, jung, jong = decompose(ch)
            syllable = CHOSEONG[cho] + JUNGSEONG[jung]
            if jong:
                syllable += JONGSEONG[jong]
            parts.append(syllable)
        else:
            # Flush any buffered parts then add the non-Hangul character
            if parts:
                buf.append('-'.join(parts))
                parts = []
            buf.append(ch)

    if parts:
        buf.append('-'.join(parts))

    return ''.join(buf)


# ---------------------------------------------------------------------------
# DB helpers
# ---------------------------------------------------------------------------

def ensure_column(cur: sqlite3.Cursor, column: str, col_type: str = 'TEXT') -> None:
    existing = {row[1] for row in cur.execute('PRAGMA table_info(compound_words)')}
    if column not in existing:
        print(f'  Adding {column} column…')
        cur.execute(f'ALTER TABLE compound_words ADD COLUMN {column} {col_type}')


def main() -> None:
    parser = argparse.ArgumentParser(description='Generate romaja for compound_words.hangul')
    parser.add_argument('--db',    default='data/db/sinosphere.db')
    parser.add_argument('--apply', action='store_true',
                        help='Write romaja to DB (default: dry-run)')
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
        ensure_column(cur, 'romaja', 'TEXT')

    query = 'SELECT id, hangul FROM compound_words WHERE hangul IS NOT NULL'
    if limit:
        query += f' LIMIT {limit}'

    rows = cur.execute(query).fetchall()
    print(f'Processing {len(rows):,} rows{"" if not limit else f" (limit {limit})"}…\n')

    updates: list[tuple[str, str]] = []
    for word_id, hangul in rows:
        romaja = to_display_romaja(hangul)
        updates.append((romaja, word_id))
        if dry_run or (limit and limit <= 100):
            print(f'  {hangul:<10} → {romaja}')

    if not dry_run:
        print(f'\nWriting {len(updates):,} romaja values…')
        cur.executemany('UPDATE compound_words SET romaja = ? WHERE id = ?', updates)
        conn.commit()
        print(f'Done. {len(updates):,} rows updated.')
    else:
        print(f'\nDry-run complete — {len(updates):,} rows would be updated.')
        print('Run with --apply to write to DB.')

    conn.close()


if __name__ == '__main__':
    main()
