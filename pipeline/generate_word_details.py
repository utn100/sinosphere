#!/usr/bin/env python3
"""
generate_word_details.py — generate synonyms, antonyms, and example sentences
for compound_words using the Anthropic Message Batches API (50% cost, async).

Workflow:
    # 1. Submit a batch (returns immediately with a batch ID)
    ANTHROPIC_API_KEY=sk-ant-... python3 pipeline/generate_word_details.py --submit

    # 2. Check status / collect results when done
    ANTHROPIC_API_KEY=sk-ant-... python3 pipeline/generate_word_details.py --collect

    # Single word (sequential, skips batching)
    ANTHROPIC_API_KEY=sk-ant-... python3 pipeline/generate_word_details.py --word 高兴

    # Show DB coverage
    python3 pipeline/generate_word_details.py --status

Options:
    --submit          Build and submit a batch for all pending words
    --collect         Poll the last submitted batch and write results to DB
    --batch-id ID     Use a specific batch ID instead of the saved one
    --word WORD       Process a single word sequentially (no batch)
    --limit N         Cap number of words submitted in a batch
    --priority        HSK 1 first (applies to both batch and sequential)
    --no-resume       Include words that already have data (re-generate)
    --status          Show coverage stats and exit

Environment:
    ANTHROPIC_API_KEY  — required for submit/collect/single-word
    MODEL              — override model (default: claude-haiku-4-5-20251001)
"""

import argparse
import json
import os
import re
import sqlite3
import sys
import time
from pathlib import Path

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
DEFAULT_MODEL  = os.environ.get('MODEL', 'claude-haiku-4-5-20251001')
DB_PATH        = Path('data/db/sinosphere.db')
BATCH_ID_FILE  = Path('data/db/.word_details_batch_id')  # persists last batch ID
MAX_RETRIES    = 3

SYSTEM_PROMPT = """\
You are a Chinese language expert helping Vietnamese learners study Mandarin.
For each Chinese word provided, return ONLY a JSON object (no markdown, no explanation) with:
- "synonyms": array of 2-3 simplified Chinese synonyms (just the characters, no pinyin)
- "antonyms": array of 1-2 simplified Chinese antonyms (just the characters, no pinyin)
- "examples": array of 1-3 objects, each with:
    "zh": natural Chinese sentence or phrase using the word (8-25 characters)
    "py": full pinyin with tone marks for that sentence
    "en": natural English translation

Rules:
- synonyms/antonyms: use ONLY common, well-known words (HSK 1-6 level preferred); empty array if none apply
- do NOT invent obscure or rare words for synonyms/antonyms — only suggest words a learner would already know
- examples: prefer common, everyday sentences; vary register if giving multiple
- Return ONLY the JSON object, no markdown fences, no explanation

Example output for 快乐:
{"synonyms":["高兴","愉快","开心"],"antonyms":["悲伤","痛苦"],"examples":[{"zh":"她看起来非常快乐。","py":"Tā kàn qǐlái fēicháng kuàilè.","en":"She looks very happy."},{"zh":"快乐是人生最重要的事。","py":"Kuàilè shì rénshēng zuì zhòngyào de shì.","en":"Happiness is the most important thing in life."}]}
"""


# ---------------------------------------------------------------------------
# Prompt builder
# ---------------------------------------------------------------------------
def _make_prompt(simplified: str, pinyin: str, english_def: str) -> str:
    return f'Word: {simplified} ({pinyin}) — {english_def}'


def _parse_response(raw: str) -> dict | None:
    try:
        raw = re.sub(r'^```[a-z]*\s*', '', raw.strip())
        raw = re.sub(r'\s*```$', '', raw).strip()
        return json.loads(raw)
    except Exception:
        return None


def _filter_known(words: list[str], known: set[str]) -> list[str]:
    """Keep only words that exist in compound_words.simplified."""
    return [w for w in words if w in known]


def _result_to_db(result: dict, known: set[str]) -> tuple[str | None, str | None, str | None]:
    synonyms   = ','.join(_filter_known(result.get('synonyms', []), known)) or None
    antonyms   = ','.join(_filter_known(result.get('antonyms', []), known)) or None
    examples   = result.get('examples', [])
    if not examples and result.get('example'):
        examples = [{'zh': result['example'], 'py': '', 'en': ''}]
    example_json = json.dumps(examples, ensure_ascii=False) if examples else None
    return synonyms, antonyms, example_json


# ---------------------------------------------------------------------------
# DB helpers
# ---------------------------------------------------------------------------
def ensure_columns(conn: sqlite3.Connection):
    existing = {row[1] for row in conn.execute('PRAGMA table_info(compound_words)')}
    for col, defn in [('synonyms', 'TEXT'), ('antonyms', 'TEXT'), ('example_sentence', 'TEXT')]:
        if col not in existing:
            conn.execute(f'ALTER TABLE compound_words ADD COLUMN {col} {defn}')
    conn.commit()


def load_known_words(conn: sqlite3.Connection) -> set[str]:
    """All simplified words in compound_words — used to filter LLM-generated synonyms."""
    return {r[0] for r in conn.execute('SELECT simplified FROM compound_words')}


def get_words(conn: sqlite3.Connection, resume: bool, priority: bool,
              word: str | None, limit: int | None,
              hsk_only: bool = False, freq_top: int | None = None) -> list[tuple]:
    if word:
        return conn.execute(
            'SELECT id, simplified, pinyin, english_def FROM compound_words WHERE simplified = ?',
            (word,)
        ).fetchall()
    conds = ['synonyms IS NULL'] if resume else []
    if hsk_only and freq_top:
        conds.append(f'(hsk_level IS NOT NULL OR frequency_rank <= {freq_top})')
    elif hsk_only:
        conds.append('hsk_level IS NOT NULL')
    elif freq_top:
        conds.append(f'frequency_rank <= {freq_top}')
    where = ('WHERE ' + ' AND '.join(conds)) if conds else ''
    order = ('ORDER BY CASE WHEN hsk_level IS NULL THEN 999 ELSE hsk_level END, '
             'CASE WHEN frequency_rank IS NULL THEN 999999 ELSE frequency_rank END'
             if priority else
             'ORDER BY CASE WHEN hsk_level IS NULL THEN 999 ELSE hsk_level END')
    lim = f'LIMIT {limit}' if limit else ''
    return conn.execute(
        f'SELECT id, simplified, pinyin, english_def FROM compound_words {where} {order} {lim}'
    ).fetchall()


def write_result(conn: sqlite3.Connection, word_id: str, result: dict, known: set[str]):
    synonyms, antonyms, example_json = _result_to_db(result, known)
    conn.execute(
        'UPDATE compound_words SET synonyms=?, antonyms=?, example_sentence=? WHERE id=?',
        (synonyms, antonyms, example_json, word_id),
    )
    conn.commit()


# ---------------------------------------------------------------------------
# Batch API
# ---------------------------------------------------------------------------
def submit_batch(rows: list[tuple]) -> str:
    import anthropic
    client = anthropic.Anthropic(api_key=os.environ['ANTHROPIC_API_KEY'])

    requests_list = [
        anthropic.types.message_create_params.MessageCreateParamsNonStreaming(
            custom_id=word_id,
            params={
                'model': DEFAULT_MODEL,
                'max_tokens': 512,
                'system': SYSTEM_PROMPT,
                'messages': [{'role': 'user', 'content': _make_prompt(simplified, pinyin or '', english_def or '')}],
            },
        )
        for word_id, simplified, pinyin, english_def in rows
    ]

    print(f'Submitting batch of {len(requests_list):,} requests…')
    batch = client.messages.batches.create(requests=requests_list)
    print(f'Batch submitted: {batch.id}')
    print(f'Status: {batch.processing_status}')
    BATCH_ID_FILE.parent.mkdir(parents=True, exist_ok=True)
    BATCH_ID_FILE.write_text(batch.id)
    print(f'Batch ID saved to {BATCH_ID_FILE}')
    print('\nRun again with --collect to retrieve results when done.')
    return batch.id


def collect_batch(batch_id: str, conn: sqlite3.Connection):
    import anthropic
    client = anthropic.Anthropic(api_key=os.environ['ANTHROPIC_API_KEY'])
    known = load_known_words(conn)

    # Poll until complete
    while True:
        batch = client.messages.batches.retrieve(batch_id)
        status = batch.processing_status
        counts = batch.request_counts
        print(f'  Status: {status}  '
              f'(processing={counts.processing}, succeeded={counts.succeeded}, '
              f'errored={counts.errored}, canceled={counts.canceled})')
        if status == 'ended':
            break
        print('  Not done yet — waiting 30s…')
        time.sleep(30)

    # Collect results
    ok = fail = skip = 0
    for result in client.messages.batches.results(batch_id):
        word_id = result.custom_id
        if result.result.type == 'succeeded':
            raw = result.result.message.content[0].text
            parsed = _parse_response(raw)
            if parsed:
                write_result(conn, word_id, parsed, known)
                ok += 1
            else:
                print(f'  Parse error for {word_id}: {repr(raw[:100])}')
                fail += 1
        elif result.result.type == 'errored':
            print(f'  API error for {word_id}: {result.result.error}')
            fail += 1
        else:
            skip += 1

    print(f'\nDone. {ok:,} written, {fail} errors, {skip} skipped.')
    if BATCH_ID_FILE.exists():
        BATCH_ID_FILE.unlink()


# ---------------------------------------------------------------------------
# Sequential (single word or fallback)
# ---------------------------------------------------------------------------
def run_sequential(rows: list[tuple], conn: sqlite3.Connection):
    import anthropic
    client = anthropic.Anthropic(api_key=os.environ['ANTHROPIC_API_KEY'])
    known = load_known_words(conn)

    ok = fail = 0
    for word_id, simplified, pinyin, english_def in rows:
        msg = None
        for attempt in range(MAX_RETRIES):
            try:
                msg = client.messages.create(
                    model=DEFAULT_MODEL,
                    max_tokens=512,
                    system=SYSTEM_PROMPT,
                    messages=[{'role': 'user', 'content': _make_prompt(
                        simplified, pinyin or '', english_def or '')}],
                )
                parsed = _parse_response(msg.content[0].text)
                if parsed is None:
                    raise ValueError(f'Bad JSON: {repr(msg.content[0].text[:200])}')
                write_result(conn, word_id, parsed, known)
                ok += 1
                break
            except Exception as e:
                if attempt == MAX_RETRIES - 1:
                    print(f'  Error for {simplified}: {e}')
                    fail += 1
                else:
                    time.sleep(2 ** attempt)
        if ok % 50 == 0 and ok > 0:
            print(f'  {ok} done…')

    print(f'Done. {ok} succeeded, {fail} failed.')


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--db',        default=str(DB_PATH))
    parser.add_argument('--word',      help='Single word — runs sequentially')
    parser.add_argument('--submit',    action='store_true', help='Submit batch job')
    parser.add_argument('--collect',   action='store_true', help='Poll + collect batch results')
    parser.add_argument('--batch-id',  help='Override saved batch ID for --collect')
    parser.add_argument('--limit',     type=int, help='Max words in batch')
    parser.add_argument('--priority',  action='store_true', help='HSK 1 first')
    parser.add_argument('--hsk-only',  action='store_true', help='Only process HSK 1-9 words (~10k)')
    parser.add_argument('--freq-top',  type=int, metavar='N',
                        help='Also include non-HSK words with frequency_rank <= N (e.g. 10000)')
    parser.add_argument('--resume',    action='store_true', default=True,
                        help='Skip words that already have data (default on)')
    parser.add_argument('--no-resume', dest='resume', action='store_false')
    parser.add_argument('--status',    action='store_true', help='Show DB coverage and exit')
    args = parser.parse_args()

    db_path = Path(args.db)
    if not db_path.exists():
        print(f'DB not found: {db_path}', file=sys.stderr)
        sys.exit(1)

    conn = sqlite3.connect(db_path)
    ensure_columns(conn)

    # ── Status ────────────────────────────────────────────────────────────────
    if args.status:
        total = conn.execute('SELECT COUNT(*) FROM compound_words').fetchone()[0]
        done  = conn.execute("SELECT COUNT(*) FROM compound_words WHERE synonyms IS NOT NULL").fetchone()[0]
        rows  = conn.execute(
            "SELECT COALESCE(hsk_level,'none'), COUNT(*), "
            "SUM(CASE WHEN synonyms IS NOT NULL THEN 1 ELSE 0 END) "
            "FROM compound_words GROUP BY hsk_level ORDER BY hsk_level"
        ).fetchall()
        print(f'Overall: {done:,}/{total:,} ({100*done//max(total,1)}%)')
        for lvl, cnt, filled in rows:
            pct = 100 * filled // cnt if cnt else 0
            print(f'  HSK {lvl}: {filled:>5}/{cnt:<5} ({pct}%)')
        conn.close()
        return

    # ── Collect ───────────────────────────────────────────────────────────────
    if args.collect:
        batch_id = args.batch_id
        if not batch_id:
            if not BATCH_ID_FILE.exists():
                print('No saved batch ID. Run --submit first or pass --batch-id ID.')
                sys.exit(1)
            batch_id = BATCH_ID_FILE.read_text().strip()
        print(f'Collecting batch {batch_id}…')
        collect_batch(batch_id, conn)
        conn.close()
        return

    # ── Single word (sequential) ──────────────────────────────────────────────
    if args.word:
        rows = get_words(conn, resume=False, priority=False,
                         word=args.word, limit=None)
        print(f'{len(rows)} word(s) to process')
        if not os.environ.get('ANTHROPIC_API_KEY'):
            print('Set ANTHROPIC_API_KEY first.')
            sys.exit(1)
        run_sequential(rows, conn)
        conn.close()
        return

    # ── Submit batch ──────────────────────────────────────────────────────────
    if args.submit:
        rows = get_words(conn, resume=args.resume, priority=args.priority,
                         word=None, limit=args.limit,
                         hsk_only=args.hsk_only, freq_top=args.freq_top)
        print(f'{len(rows):,} words pending')
        if not rows:
            print('Nothing to submit.')
            conn.close()
            return
        if not os.environ.get('ANTHROPIC_API_KEY'):
            print('Set ANTHROPIC_API_KEY first.')
            sys.exit(1)
        submit_batch(rows)
        conn.close()
        return

    parser.print_help()


if __name__ == '__main__':
    main()
