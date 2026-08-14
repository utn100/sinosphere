"""
Sinosphere Rosetta — Phase 0 Etymology Story Generator
Batch-generates Vietnamese Chiết Tự narratives for all characters in sinosphere.db
using Claude Haiku 4.5 (cheapest capable model, ~$0.50 total for all 9,565 characters).

Run:
    python3 pipeline/generate_etymology.py

Flags:
    --limit N       Only process N characters (for testing)
    --priority      Process HSK 1-4 + component chars only first
    --dry-run       Print prompts without calling API
    --resume        Skip chars that already have a story (default: True)

Cost estimate:
    ~200 tokens per story × 9,565 chars = ~1.9M tokens
    Claude Haiku 4.5: $1.00 input / $5.00 output per 1M tokens
    Total: ~$0.50-1.00 depending on prompt + output length
"""

import argparse
import os
import sqlite3
import time
import sys
from pathlib import Path

import anthropic

# ── Paths ─────────────────────────────────────────────────────────────────────
ROOT    = Path(__file__).parent.parent
DB_PATH = ROOT / "data" / "db" / "sinosphere.db"

# ── Client factory ────────────────────────────────────────────────────────────
def make_client() -> anthropic.Anthropic:
    """
    Create an Anthropic client, optionally via SAP Hyperspace AI proxy.

    For Hyperspace, set:
        HYPERSPACE_BASE_URL   e.g. https://api.hyperspace.tools.sap/llm-proxy/anthropic
        HYPERSPACE_API_KEY    your Hyperspace API key (sent as x-api-key header)

    For direct Anthropic API, set:
        ANTHROPIC_API_KEY     your Anthropic key
    """
    base_url = os.environ.get("HYPERSPACE_BASE_URL")
    api_key  = os.environ.get("HYPERSPACE_API_KEY") or os.environ.get("ANTHROPIC_API_KEY")

    if not api_key:
        raise ValueError(
            "No API key found. Set HYPERSPACE_API_KEY (for Hyperspace) "
            "or ANTHROPIC_API_KEY (for direct Anthropic)."
        )

    kwargs = {"api_key": api_key}
    if base_url:
        kwargs["base_url"] = base_url
    return anthropic.Anthropic(**kwargs)

# Model to use — override with MODEL env var if your Hyperspace instance needs a different ID
# e.g. MODEL=claude-haiku-4-5-20251001
MODEL = os.environ.get("MODEL", "claude-haiku-4-5")

# ── Prompt template ──────────────────────────────────────────────────────────
SYSTEM_PROMPT = """Bạn là chuyên gia ngôn ngữ học Hán-Việt và Chiết tự học.
Nhiệm vụ của bạn là viết một câu chuyện ký ức ngắn (2-3 câu) bằng tiếng Việt
giải thích logic kết hợp các thành phần của một chữ Hán.

Phong cách:
- Ngắn gọn, sinh động, dễ nhớ
- Nêu rõ tên Hán-Việt của từng thành phần trong ngoặc đơn
- Giải thích TẠI SAO các thành phần kết hợp tạo ra nghĩa đó
- Không dùng thuật ngữ học thuật khó hiểu
- Không lặp lại thông tin đã rõ ràng

Ví dụ tốt cho chữ 晨 (THẦN - buổi sáng):
"Mặt trời (日 - Nhật) mọc nhô lên trên mốc thời gian cố định (辰 - Thần) báo hiệu thời khắc bình minh vừa hé rạng."

Ví dụ tốt cho chữ 明 (MINH - sáng):
"Mặt trời (日 - Nhật) và mặt trăng (月 - Nguyệt) cùng chiếu sáng một lúc — hình ảnh của sự sáng tỏ tuyệt đỉnh."

Chỉ trả về câu chuyện, không có gì khác."""

def build_user_prompt(char: str, pinyin: str, han_viet: str, english: str,
                      components: list[dict], ids: str) -> str:
    comp_lines = "\n".join(
        f"  - {c['symbol']} [{c['pinyin']}] {c['han_viet'] or '?'} = {c['english_def'][:50]} [{c['component_type']}]"
        for c in components
    )
    return f"""Chữ: {char}
Pinyin: {pinyin}
Hán-Việt: {han_viet}
Nghĩa tiếng Anh: {english}
Cấu trúc IDS: {ids}
Thành phần:
{comp_lines}

Viết câu chuyện Chiết tự ngắn (2-3 câu tiếng Việt):"""

# ── Database helpers ─────────────────────────────────────────────────────────
def load_characters(con, priority_only: bool = False,
                    resume: bool = True, limit: int | None = None) -> list[dict]:
    """Load characters needing etymology stories, ordered by priority."""
    base_query = """
        SELECT
            c.id, c.symbol, c.pinyin, c.han_viet, c.english_def,
            c.decomposition, c.hsk_level, c.radical,
            c.etymology_story
        FROM characters c
    """
    conditions = []
    if resume:
        conditions.append("(c.etymology_story IS NULL OR c.etymology_story = '')")
    if priority_only:
        # HSK 1-4 chars + chars that appear as components
        conditions.append("""(
            EXISTS (
                SELECT 1 FROM compound_words cw
                JOIN word_characters wc ON wc.word_id = cw.id
                WHERE wc.character_id = c.id AND cw.hsk_level <= 4
            )
            OR EXISTS (
                SELECT 1 FROM character_components cc WHERE cc.component_id = c.id
            )
        )""")

    where = ("WHERE " + " AND ".join(conditions)) if conditions else ""

    # Order: HSK level first (lower = higher priority), then by frequency in compounds
    order = """
        ORDER BY
            CASE WHEN c.hsk_level IS NOT NULL THEN c.hsk_level ELSE 99 END,
            (SELECT COUNT(*) FROM word_characters wc WHERE wc.character_id = c.id) DESC
    """
    lim = f"LIMIT {limit}" if limit else ""
    query = f"{base_query} {where} {order} {lim}"

    rows = con.execute(query).fetchall()
    cols = ["id", "symbol", "pinyin", "han_viet", "english_def",
            "decomposition", "hsk_level", "radical", "etymology_story"]

    chars = []
    for row in rows:
        d = dict(zip(cols, row))
        # Fetch components
        d["components"] = con.execute("""
            SELECT c2.symbol, c2.pinyin, c2.han_viet, c2.english_def, cc.component_type
            FROM character_components cc
            JOIN components c2 ON c2.id = cc.component_id
            WHERE cc.character_id = ?
            ORDER BY cc.position
        """, (d["id"],)).fetchall()
        d["components"] = [
            {"symbol": r[0], "pinyin": r[1], "han_viet": r[2] or "",
             "english_def": r[3] or "", "component_type": r[4]}
            for r in d["components"]
        ]
        chars.append(d)
    return chars


def save_story(con, char_id: str, story: str):
    con.execute(
        "UPDATE characters SET etymology_story = ? WHERE id = ?",
        (story.strip(), char_id)
    )
    con.commit()


# ── Generation ────────────────────────────────────────────────────────────────

def _call_single(client, ch: dict) -> str | None:
    """Make a single messages.create call for one character. Returns story or None."""
    prompt = build_user_prompt(
        ch["symbol"], ch["pinyin"], ch["han_viet"] or "—",
        ch["english_def"] or "—", ch["components"],
        ch["decomposition"] or "—"
    )
    response = client.messages.create(
        model=MODEL,
        max_tokens=256,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": prompt}]
    )
    return next((b.text for b in response.content if b.type == "text"), "").strip() or None


def generate_stories(chars: list[dict], dry_run: bool = False,
                     batch_size: int = 50) -> None:
    """Generate etymology stories using Claude Haiku 4.5.

    Uses the Batches API when available (50% cost savings).
    Automatically falls back to individual calls if Batches returns 404
    (e.g. when routing through SAP Hyperspace proxy).
    """
    client = make_client()
    con = sqlite3.connect(DB_PATH)

    total = len(chars)
    done = 0
    errors = 0
    use_batches = True  # try Batches API first; flip to False on 404

    print(f"\nGenerating etymology stories for {total} characters")
    print(f"Model: {MODEL}  |  Batch size: {batch_size}")
    print(f"Estimated cost: ~${total * 0.0001:.2f} - ${total * 0.0002:.2f}\n")

    if dry_run:
        print("=== DRY RUN — printing first 3 prompts ===\n")
        for ch in chars[:3]:
            prompt = build_user_prompt(
                ch["symbol"], ch["pinyin"], ch["han_viet"] or "—",
                ch["english_def"] or "—", ch["components"],
                ch["decomposition"] or "—"
            )
            print(f"--- {ch['symbol']} [{ch['han_viet']}] ---")
            print(prompt)
            print()
        return

    from anthropic.types.message_create_params import MessageCreateParamsNonStreaming
    from anthropic.types.messages.batch_create_params import Request

    batch_num = 0
    for i in range(0, total, batch_size):
        batch_chars = chars[i:i + batch_size]
        batch_num += 1
        print(f"Batch {batch_num} ({i+1}-{min(i+batch_size, total)} of {total})...", end=" ", flush=True)

        if use_batches:
            # ── Batches API path ───────────────────────────────────────────────
            requests = []
            for ch in batch_chars:
                prompt = build_user_prompt(
                    ch["symbol"], ch["pinyin"], ch["han_viet"] or "—",
                    ch["english_def"] or "—", ch["components"],
                    ch["decomposition"] or "—"
                )
                requests.append(Request(
                    custom_id=ch["id"],
                    params=MessageCreateParamsNonStreaming(
                        model=MODEL,
                        max_tokens=256,
                        system=SYSTEM_PROMPT,
                        messages=[{"role": "user", "content": prompt}]
                    )
                ))
            try:
                batch = client.messages.batches.create(requests=requests)
                poll_count = 0
                while True:
                    batch = client.messages.batches.retrieve(batch.id)
                    if batch.processing_status == "ended":
                        break
                    poll_count += 1
                    if poll_count % 6 == 0:
                        print(f"  (waiting... {batch.request_counts.processing} remaining)", end=" ", flush=True)
                    time.sleep(5)

                batch_done = 0
                batch_errors = 0
                for result in client.messages.batches.results(batch.id):
                    if result.result.type == "succeeded":
                        text_blocks = [b for b in result.result.message.content if b.type == "text"]
                        if text_blocks:
                            save_story(con, result.custom_id, text_blocks[0].text.strip())
                            batch_done += 1
                    else:
                        batch_errors += 1
                done += batch_done
                errors += batch_errors
                print(f"✓ {batch_done} saved ({batch_errors} errors)")

            except anthropic.NotFoundError:
                # Batches API not available (e.g. Hyperspace proxy) — switch permanently
                print(f"\n  Batches API unavailable — switching to individual calls for all remaining characters.")
                use_batches = False
                # Fall through to individual path for this batch
                batch_done, batch_errors = _process_individually(client, con, batch_chars)
                done += batch_done
                errors += batch_errors
                print(f"✓ {batch_done} saved ({batch_errors} errors)")

            except anthropic.RateLimitError:
                print(f"\n  Rate limited — waiting 30s, then retrying individually...")
                time.sleep(30)
                batch_done, batch_errors = _process_individually(client, con, batch_chars)
                done += batch_done
                errors += batch_errors
                print(f"✓ {batch_done} saved ({batch_errors} errors)")

            except Exception as e:
                print(f"\n  Batch error: {e} — retrying individually...")
                batch_done, batch_errors = _process_individually(client, con, batch_chars)
                done += batch_done
                errors += batch_errors
                print(f"✓ {batch_done} saved ({batch_errors} errors)")

        else:
            # ── Individual calls path (Hyperspace / no Batches support) ────────
            batch_done, batch_errors = _process_individually(client, con, batch_chars)
            done += batch_done
            errors += batch_errors
            print(f"✓ {batch_done} saved ({batch_errors} errors)")

        pct = done / total * 100
        print(f"  Progress: {done}/{total} ({pct:.1f}%) | Errors: {errors}")

    con.close()
    print(f"\n{'='*50}")
    print(f"Complete: {done} stories generated, {errors} errors")
    print(f"DB: {DB_PATH}")


def _process_individually(client, con, chars: list[dict]) -> tuple[int, int]:
    """Process a list of characters one by one. Returns (done, errors)."""
    done = 0
    errors = 0
    for ch in chars:
        try:
            story = _call_single(client, ch)
            if story:
                save_story(con, ch["id"], story)
                done += 1
            time.sleep(0.3)  # gentle rate limiting
        except anthropic.RateLimitError:
            time.sleep(30)
            try:
                story = _call_single(client, ch)
                if story:
                    save_story(con, ch["id"], story)
                    done += 1
            except Exception as e:
                errors += 1
                print(f"\n  Failed {ch['symbol']}: {e}")
        except Exception as e:
            errors += 1
            print(f"\n  Failed {ch['symbol']}: {e}")
    return done, errors


# ── Single character mode (for testing) ──────────────────────────────────────
def generate_single(char: str) -> str:
    """Generate and print a story for a single character without saving."""
    client = make_client()
    con = sqlite3.connect(DB_PATH)

    row = con.execute("""
        SELECT id, symbol, pinyin, han_viet, english_def, decomposition
        FROM characters WHERE symbol = ?
    """, (char,)).fetchone()

    if not row:
        print(f"Character '{char}' not found in DB")
        con.close()
        return ""

    cid, sym, pinyin, hv, eng, ids = row
    comps = con.execute("""
        SELECT c2.symbol, c2.pinyin, c2.han_viet, c2.english_def, cc.component_type
        FROM character_components cc
        JOIN components c2 ON c2.id = cc.component_id
        WHERE cc.character_id = ?
        ORDER BY cc.position
    """, (cid,)).fetchall()
    con.close()

    components = [
        {"symbol": r[0], "pinyin": r[1], "han_viet": r[2] or "",
         "english_def": r[3] or "", "component_type": r[4]}
        for r in comps
    ]

    prompt = build_user_prompt(sym, pinyin, hv or "—", eng or "—", components, ids or "—")

    print(f"\n--- Prompt for {sym} ---")
    print(prompt)
    print("\n--- Calling Claude Haiku 4.5 ---")

    response = client.messages.create(
        model=MODEL,
        max_tokens=256,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": prompt}]
    )

    story = next((b.text for b in response.content if b.type == "text"), "").strip()
    print(f"\n--- Story ---\n{story}")
    print(f"\nTokens: {response.usage.input_tokens} in / {response.usage.output_tokens} out")
    return story


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="Generate Chiết Tự etymology stories")
    parser.add_argument("--limit", type=int, default=None,
                        help="Only process N characters (for testing)")
    parser.add_argument("--priority", action="store_true",
                        help="Process HSK 1-4 + component characters only")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print prompts without calling the API")
    parser.add_argument("--no-resume", action="store_true",
                        help="Regenerate even if story already exists")
    parser.add_argument("--char", type=str, default=None,
                        help="Test with a single character (prints to stdout, does not save)")
    parser.add_argument("--batch-size", type=int, default=50,
                        help="Characters per API batch (default: 50)")
    args = parser.parse_args()

    if not DB_PATH.exists():
        print(f"DB not found: {DB_PATH}")
        print("Run pipeline/build_db.py first.")
        sys.exit(1)

    # Single character test mode
    if args.char:
        generate_single(args.char)
        return

    con = sqlite3.connect(DB_PATH)
    chars = load_characters(
        con,
        priority_only=args.priority,
        resume=not args.no_resume,
        limit=args.limit
    )
    con.close()

    if not chars:
        print("No characters need stories — all done!")
        return

    # Stats
    has_story = sqlite3.connect(DB_PATH).execute(
        "SELECT COUNT(*) FROM characters WHERE etymology_story IS NOT NULL AND etymology_story != ''"
    ).fetchone()[0]
    total_chars = sqlite3.connect(DB_PATH).execute(
        "SELECT COUNT(*) FROM characters"
    ).fetchone()[0]

    print(f"\n{'='*50}")
    print(f"Sinosphere Rosetta — Etymology Story Generator")
    print(f"{'='*50}")
    print(f"Characters in DB:     {total_chars:,}")
    print(f"Already have story:   {has_story:,}")
    print(f"To generate now:      {len(chars):,}")
    if args.priority:
        print(f"Mode:                 Priority (HSK 1-4 + components)")
    if args.limit:
        print(f"Limit:                {args.limit}")

    generate_stories(chars, dry_run=args.dry_run, batch_size=args.batch_size)


if __name__ == "__main__":
    main()
