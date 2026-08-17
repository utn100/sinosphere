#!/usr/bin/env python3
"""
enrich_korean_words.py — Fetch English definitions, synonyms, antonyms, and
example sentences for both korean_words (native) and compound_words (Sino-Korean
kr_verified=1) tables using the KDict Open API.

API docs: https://krdict.korean.go.kr/openApi/openApiInfo

Usage:
    python3 pipeline/enrich_korean_words.py --key KEY               # dry-run, 10 rows (native only)
    python3 pipeline/enrich_korean_words.py --key KEY --limit 20    # dry-run, 20 rows
    python3 pipeline/enrich_korean_words.py --key KEY --apply       # full run (native only)
    python3 pipeline/enrich_korean_words.py --key KEY --apply --sino # also enrich compound_words
    python3 pipeline/enrich_korean_words.py --key KEY --apply --resume  # skip already-done words
"""

import argparse
import sqlite3
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

API_BASE   = 'https://krdict.korean.go.kr/api'
USER_AGENT = 'SinosphereApp/1.0'
SLEEP_SEC  = 0.2
COMMIT_EVERY = 50

REL_TYPE_SYNONYM = '유의어'
REL_TYPE_ANTONYM = '반대말'


# ── API helpers ───────────────────────────────────────────────────────────────

def _get(url: str) -> ET.Element:
    req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
    with urllib.request.urlopen(req, timeout=8) as r:
        return ET.fromstring(r.read().decode('utf-8'))


def _get_with_retry(url: str, retries: int = 3) -> ET.Element | None:
    for attempt in range(retries):
        try:
            return _get(url)
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(1.0 * (attempt + 1))
            else:
                raise
    return None


def search_word(key: str, word: str) -> str | None:
    encoded = urllib.parse.quote(word)
    url = (f'{API_BASE}/search?key={key}&q={encoded}'
           f'&search_target=word&translated=y&trans_lang=1')
    root = _get_with_retry(url)
    if root is None:
        return None
    total = root.findtext('total') or '0'
    if int(total) == 0:
        return None
    return root.findtext('.//target_code')


def fetch_detail(key: str, target_code: str) -> dict:
    url = (f'{API_BASE}/view?key={key}&q={target_code}'
           f'&method=target_code&translated=y&trans_lang=1')
    root = _get_with_retry(url)
    result = {'english_def': '', 'synonyms': '', 'antonyms': '', 'example_sentence': ''}
    if root is None:
        return result

    item = root.find('.//item')
    if item is None:
        return result
    wi = item.find('word_info')
    if wi is None:
        return result

    # English translation — prefer trans_word (short: "go; travel") over trans_dfn (long definition)
    trans_word = wi.findtext('.//sense_info/translation/trans_word')
    trans_dfn  = wi.findtext('.//sense_info/translation/trans_dfn')
    if trans_word:
        tw = trans_word.strip()
        result['english_def'] = tw if tw else (trans_dfn or '').strip()

    # Related words
    synonyms: list[str] = []
    antonyms: list[str] = []
    for rel in wi.findall('.//rel_info'):
        rel_word = rel.findtext('word', '').strip()
        rel_type = rel.findtext('type', '').strip()
        if not rel_word:
            continue
        if rel_type == REL_TYPE_SYNONYM and rel_word not in synonyms:
            synonyms.append(rel_word)
        elif rel_type == REL_TYPE_ANTONYM and rel_word not in antonyms:
            antonyms.append(rel_word)

    # Examples — first 문장 (sentence) + first 구 (phrase), joined by newline
    sentence = ''
    phrase   = ''
    for ex_info in wi.findall('.//example_info'):
        ex_type = ex_info.findtext('type', '').strip()
        ex_text = ex_info.findtext('example', '').strip()
        if not ex_text:
            continue
        if ex_type == '문장' and not sentence:
            sentence = ex_text
        elif ex_type == '구' and not phrase:
            phrase = ex_text
        if sentence and phrase:
            break

    example_parts = [p for p in [sentence, phrase] if p]
    result['synonyms']         = ', '.join(synonyms[:5]) if synonyms else ''
    result['antonyms']         = ', '.join(antonyms[:5]) if antonyms else ''
    result['example_sentence'] = '\n'.join(example_parts)

    return result


# ── DB helpers ────────────────────────────────────────────────────────────────

def ensure_native_columns(cur: sqlite3.Cursor) -> None:
    existing = {row[1] for row in cur.execute('PRAGMA table_info(korean_words)')}
    for col, defn in [
        ('english_def',      'TEXT DEFAULT ""'),
        ('synonyms',         'TEXT'),
        ('antonyms',         'TEXT'),
        ('example_sentence', 'TEXT'),
    ]:
        if col not in existing:
            print(f'  Adding {col} to korean_words…')
            cur.execute(f'ALTER TABLE korean_words ADD COLUMN {col} {defn}')


def ensure_sino_columns(cur: sqlite3.Cursor) -> None:
    """Add kr_* columns to compound_words — separate from Chinese enrichment columns."""
    existing = {row[1] for row in cur.execute('PRAGMA table_info(compound_words)')}
    for col, defn in [
        ('kr_synonyms',  'TEXT'),
        ('kr_antonyms',  'TEXT'),
        ('kr_example',   'TEXT'),
    ]:
        if col not in existing:
            print(f'  Adding {col} to compound_words…')
            cur.execute(f'ALTER TABLE compound_words ADD COLUMN {col} {defn}')


# ── Process a list of (id, hangul) rows ───────────────────────────────────────

def process_rows(key: str, rows: list[tuple], dry_run: bool,
                 update_sql: str, limit: int | None,
                 cur: sqlite3.Cursor, conn: sqlite3.Connection) -> tuple[int, int, int]:
    updates: list[tuple] = []
    found = 0
    not_found = 0
    errors = 0

    for i, (word_id, hangul) in enumerate(rows):
        if i > 0:
            time.sleep(SLEEP_SEC)

        try:
            target_code = search_word(key, hangul)
            if not target_code:
                not_found += 1
                if dry_run or (limit and limit <= 50):
                    print(f'  {hangul:<14} NOT FOUND in KDict')
                continue

            detail = fetch_detail(key, target_code)
            found += 1

            updates.append((
                detail['english_def'],
                detail['synonyms']  or None,
                detail['antonyms']  or None,
                detail['example_sentence'] or None,
                word_id,
            ))

            if dry_run or (limit and limit <= 50):
                syn = detail['synonyms'] or '—'
                ant = detail['antonyms'] or '—'
                ex  = (detail['example_sentence'] or '—').replace('\n', ' | ')[:50]
                eng = (detail['english_def'] or '—')[:30]
                print(f'  {hangul:<14} EN={eng:<32} syn={syn:<12} ant={ant:<12} ex={ex}')

        except Exception as e:
            errors += 1
            if dry_run or (limit and limit <= 50):
                print(f'  {hangul:<14} ERROR: {e}')

        # Commit incrementally
        if not dry_run and len(updates) >= COMMIT_EVERY:
            cur.executemany(update_sql, updates)
            conn.commit()
            print(f'  [{i+1}/{len(rows)}] committed {len(updates)} rows (found: {found})')
            updates = []

    if not dry_run and updates:
        cur.executemany(update_sql, updates)
        conn.commit()

    return found, not_found, errors


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description='Enrich Korean words with KDict API data')
    parser.add_argument('--key',    required=True, help='KDict API key')
    parser.add_argument('--db',     default='data/db/sinosphere.db')
    parser.add_argument('--apply',  action='store_true',
                        help='Write to DB (default: dry-run)')
    parser.add_argument('--sino',   action='store_true',
                        help='Also enrich compound_words WHERE kr_verified=1')
    parser.add_argument('--limit',  type=int, default=None,
                        help='Process at most N words per table (default: 10 dry-run, all apply)')
    parser.add_argument('--resume', action='store_true',
                        help='Skip words that already have data populated')
    args = parser.parse_args()

    dry_run = not args.apply
    limit   = args.limit if args.limit is not None else (10 if dry_run else None)

    db_path = Path(args.db)
    if not db_path.exists():
        print(f'DB not found: {db_path}', file=sys.stderr); sys.exit(1)

    conn = sqlite3.connect(db_path)
    cur  = conn.cursor()

    if not dry_run:
        ensure_native_columns(cur)
        if args.sino:
            ensure_sino_columns(cur)
        conn.commit()

    # ── Native Korean words ───────────────────────────────────────────────────
    if args.resume:
        q = "SELECT id, hangul FROM korean_words WHERE english_def = '' OR english_def IS NULL"
    else:
        q = 'SELECT id, hangul FROM korean_words'
    if limit:
        q += f' LIMIT {limit}'
    native_rows = cur.execute(q).fetchall()

    print(f'\n=== Native Korean words ({len(native_rows):,}) ===')
    native_update_sql = '''UPDATE korean_words
       SET english_def = ?, synonyms = ?, antonyms = ?, example_sentence = ?
       WHERE id = ?'''
    f1, nf1, e1 = process_rows(args.key, native_rows, dry_run,
                                native_update_sql, limit, cur, conn)

    # ── Sino-Korean words (compound_words kr_verified=1) ─────────────────────
    f2 = nf2 = e2 = 0
    if args.sino:
        if args.resume:
            q2 = "SELECT id, hangul FROM compound_words WHERE kr_verified=1 AND (kr_example IS NULL OR kr_example='')"
        else:
            q2 = 'SELECT id, hangul FROM compound_words WHERE kr_verified=1 AND hangul IS NOT NULL'
        if limit:
            q2 += f' LIMIT {limit}'
        sino_rows = cur.execute(q2).fetchall()

        print(f'\n=== Sino-Korean words ({len(sino_rows):,}) ===')
        sino_update_sql = '''UPDATE compound_words
           SET kr_synonyms = ?, kr_antonyms = ?, kr_example = ?
           WHERE id = ?'''
        # Note: no english_def update for compound_words (already has Chinese english_def)
        def sino_process(key, rows, dry_run, limit, cur, conn):
            updates = []
            found = not_found = errors = 0
            for i, (word_id, hangul) in enumerate(rows):
                if i > 0: time.sleep(SLEEP_SEC)
                try:
                    tc = search_word(key, hangul)
                    if not tc:
                        not_found += 1
                        if dry_run or (limit and limit <= 50):
                            print(f'  {hangul:<14} NOT FOUND')
                        continue
                    detail = fetch_detail(key, tc)
                    found += 1
                    updates.append((
                        detail['synonyms'] or None,
                        detail['antonyms'] or None,
                        detail['example_sentence'] or None,
                        word_id,
                    ))
                    if dry_run or (limit and limit <= 50):
                        syn = detail['synonyms'] or '—'
                        ant = detail['antonyms'] or '—'
                        ex  = (detail['example_sentence'] or '—').replace('\n', ' | ')[:50]
                        print(f'  {hangul:<14} syn={syn:<12} ant={ant:<12} ex={ex}')
                except Exception as e:
                    errors += 1
                    if dry_run or (limit and limit <= 50):
                        print(f'  {hangul:<14} ERROR: {e}')
                if not dry_run and len(updates) >= COMMIT_EVERY:
                    cur.executemany(sino_update_sql, updates)
                    conn.commit()
                    print(f'  [{i+1}/{len(rows)}] committed {len(updates)} rows (found: {found})')
                    updates = []
            if not dry_run and updates:
                cur.executemany(sino_update_sql, updates)
                conn.commit()
            return found, not_found, errors
        f2, nf2, e2 = sino_process(args.key, sino_rows, dry_run, limit, cur, conn)

    print(f'\n=== Summary ===')
    print(f'  Native  — found: {f1:,}  not found: {nf1:,}  errors: {e1:,}')
    if args.sino:
        print(f'  Sino-KR — found: {f2:,}  not found: {nf2:,}  errors: {e2:,}')
    if dry_run:
        print('\nDry-run — no changes written. Run with --apply to write to DB.')
    else:
        print('Done.')

    conn.close()


if __name__ == '__main__':
    main()
