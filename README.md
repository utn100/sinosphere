# Sinosphere

**Decode Words. Discover Meaning.**

A Vietnamese-English bilingual dictionary app for learning Mandarin Chinese — built on the insight that Vietnamese speakers have a massive hidden advantage: over 60% of Vietnamese vocabulary shares Sino-Vietnamese (Hán-Việt) roots with Chinese. Sinosphere makes this connection explicit.

---

## What it does

Vietnamese learners of Mandarin often discover that a Chinese word they've never seen before already has a Vietnamese cognate they know well. 明 (míng) → MINH as in *văn minh* (civilisation). 心 (xīn) → TÂM as in *tâm lý* (psychology). The app surfaces these connections at every level.

### Dict Tab
Look up any Chinese character or compound word. Each entry shows:
- The character at 72px with its **Hán-Việt (HV) reading** in amber
- Pinyin, HSK level badge, Japanese onyomi, Korean hanja, stroke count
- **Structural decomposition (Chiết Tự)** — colour-coded component pills (semantic · phonetic · iconic) each with their own HV reading
- **Vietnamese etymology story** — a 2-3 sentence narrative in Vietnamese explaining *why* the components combine to form the meaning. Bundled for HSK 1-6 (100%); generated on-device via AI for the rest
- **Frequent compounds** ordered by HV resonance — high-resonance words (where the Vietnamese and Chinese meanings still closely match) shown first
- Tapping any compound word shows a detail sheet with tappable characters; each character tap drills into its own Dict Card

### Graph Tab
An interactive character graph:
- Start from a character (via search or the Dict Card teaser) or pick one of 214 Kangxi radicals
- The focal character shows its components (inner ring) and characters that share the same radical (outer ring)
- Tap a component → expand sibling characters that share it
- Tap a character → expand its compound words (paginated, ordered by HV resonance)
- Tap a compound → word detail sheet with tappable characters
- Compound chips fan out from their parent; `+` / `−` pages through more

### Reader Tab
Paste or select Chinese text for interlinear annotation:
- **Greedy longest-match segmentation** against the 119k compound word database — 早晨 is recognised as one token (TẢO THẦN) not two separate characters
- Toggle **PY** (pinyin below) and **HV** (Hán-Việt above) independently; both, either, or neither
- Tap any token → word detail sheet
- Long-press → open that word's Component Graph
- **English translation**: word-by-word gloss always available offline; AI natural translation (Claude / Gemini / GPT-4o mini / custom endpoint) on demand, cached locally
- **Vocabulary harvest**: star words from the text → bulk-save to bookmarks or create a new deck
- All annotated texts auto-saved to reading history

### Decks Tab
- **HSK 1–7** (HSK 7 = levels 7-9 combined): paginated word lists, 50 per page, ordered by frequency. Tap to see word sheet. Check off memorised words; reset to restore.
- **Topic Collections**: Nature, Body, City, Emotions, Time, Family, Learning, Travel, Food, Business, Strong HV Cognates, Popular Song Vocab — populated by keyword queries against the English definitions
- **My Collections**: create named decks, add words from the Reader harvest panel
- **Bookmarks**: bookmark individual characters from any Dict Card or compound list

### Settings
Configure the AI provider used for etymology story generation and translation:
- **Claude Haiku 4.5** (Anthropic API key)
- **Gemini Flash** (Google AI key)
- **GPT-4o mini** (OpenAI key)
- **Custom endpoint** (any OpenAI-compatible proxy — base URL + model name + API key)

API keys stored in device secure storage (iOS Keychain / Android Keystore).

---

## Database

The app ships with `sinosphere.db` (83 MB SQLite) bundled as an asset, copied to writable storage on first launch. The DB contains:

| Table | Contents |
|---|---|
| `compound_words` | 119,449 words — simplified, traditional, pinyin, HV reading, HV resonance, English definition, HSK level, frequency rank |
| `characters` | 9,565 characters — symbol, pinyin, HV reading, JP onyomi, stroke count, etymology story |
| `components` | 1,801 radical/component records |
| `character_components` | Decomposition links with component type (semantic / phonetic / iconic) |
| `word_characters` | Character ↔ word membership |
| `user_collections` | User-created decks |
| `user_collection_words` | Deck membership + memorized words |
| `reading_history` | Annotated text sessions with serialised token JSON |
| `ai_cache` | Cached AI responses (etymology stories + translations) |

FTS5 virtual table `words_fts` enables sub-50ms full-text search across simplified, HV, pinyin, and English definition.

**Data sources:** CC-CEDICT · Unihan (Unicode) · MakeMeHanzi · HSK 3.0 · Thiều Chửu · Trần Văn Chánh · Subtlex-CH frequency corpus · Claude Haiku 4.5 (etymology stories)

---

## Building from source

### Prerequisites
- Flutter 3.47+ / Dart 3.13+
- Python 3.10+ (for the data pipeline)
- Android SDK (for Android build)

### 1. Generate the database

The 83 MB database is not committed to the repo (too large). Run the pipeline:

```bash
# Install Python deps
pip install anthropic

# Build the core DB (~10 min)
python3 pipeline/build_db.py

# Backfill HV readings from additional sources (~2 min)
python3 pipeline/patch_hanviet.py

# Recompute compound HV readings after patch (~1 min)
python3 pipeline/patch_compounds.py

# Fill JP onyomi + stroke counts from Unihan (~30 sec)
python3 pipeline/patch_jp_strokes.py

# Validate (expect 63 passed, 0 errors)
python3 pipeline/validate_db.py

# (Optional) Generate Vietnamese etymology stories via AI
# Direct Anthropic:
ANTHROPIC_API_KEY=sk-ant-... python3 pipeline/generate_etymology.py --resume
# Or via custom endpoint:
HYPERSPACE_BASE_URL=https://... HYPERSPACE_API_KEY=... python3 pipeline/generate_etymology.py --resume
```

You'll need the raw data files in `data/raw/` (Unihan.zip, cedict_ts.u8, etc.) — see `pipeline/build_db.py` for the full list.

### 2. Copy DB to app assets

```bash
cp data/db/sinosphere.db app/assets/sinosphere.db
```

### 3. Build the Flutter app

```bash
cd app
flutter pub get
flutter build apk --release        # Android
# flutter build ios --release      # iOS (requires Xcode)
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

> **Note:** The APK is ~130 MB with the bundled database. For Play Store distribution, Play Asset Delivery is needed to split the 83 MB database.

---

## Project structure

```
sinosphere/
├── pipeline/               ← Python data pipeline (6 scripts)
│   ├── build_db.py         ← Core DB builder
│   ├── patch_hanviet.py    ← HV reading backfill
│   ├── patch_compounds.py  ← Compound HV recompute
│   ├── patch_jp_strokes.py ← JP onyomi + stroke counts
│   ├── generate_etymology.py ← AI etymology story generation
│   └── validate_db.py      ← 63-assertion test suite
├── app/                    ← Flutter project
│   ├── lib/
│   │   ├── core/
│   │   │   ├── database/   ← Drift ORM (tables, DAOs)
│   │   │   ├── services/   ← AI service, DB provider
│   │   │   └── theme/      ← Dark/light theme tokens
│   │   └── features/
│   │       ├── dict_card/  ← Dict Card screen + widgets
│   │       ├── graph/      ← Graph Explorer (CustomPainter)
│   │       ├── reader/     ← Smart Reader + annotation
│   │       ├── collections/← Decks, HSK, topics, bookmarks
│   │       ├── search/     ← Search bar with FTS + LIKE fallback
│   │       ├── settings/   ← AI provider configuration
│   │       └── shell/      ← Bottom nav shell
│   └── assets/sinosphere.db ← (generated, not committed)
├── BUILD_STATUS.md         ← Detailed build status + architecture notes
└── sinosphere_rosetta_prd.md ← Original product requirements
```

---

## Tech stack

| Layer | Technology |
|---|---|
| UI | Flutter 3.47 · Dart 3.13 |
| State | Riverpod 3.4 (NotifierProvider throughout) |
| Database | Drift 2.34 over SQLite · FTS5 for search |
| AI | HTTP calls to Claude / Gemini / OpenAI / custom OpenAI-compatible endpoints |
| Secure storage | flutter_secure_storage (Keychain / Keystore) |
| Graph rendering | Flutter CustomPainter (no third-party graph library) |

---

## Etymology stories

The Vietnamese Chiết Tự narratives are generated by Claude Haiku 4.5 using a Vietnamese-language prompt that explains the component logic. Coverage as of last pipeline run:

| HSK | Coverage |
|---|---|
| 1-4 | 100% |
| 5 | 98% |
| 6 | 97% |
| 7-9 | 82% |
| Total | ~6,500 / 9,565 characters (68%) |

Stories are cached in the DB. On-device generation fills gaps as users encounter them.
