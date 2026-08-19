# Sinosphere

**Decode Words. Discover Meaning.**

A Vietnamese-English bilingual dictionary app for learning **Mandarin Chinese and Korean** — built on the insight that Vietnamese speakers share deep vocabulary roots with both languages through the Sinosphere. Over 60% of Vietnamese vocabulary shares Sino-Vietnamese (Hán-Việt) roots with Chinese, and a large share of Korean vocabulary is Sino-Korean (Hanja-based) that maps onto the same roots. Sinosphere makes these connections explicit in both directions.

---

## What it does

Vietnamese learners often discover that a Chinese or Korean word they've never seen already has a Vietnamese cognate they know well. 明 (míng) → MINH as in *văn minh* (civilisation). 心 (xīn) → TÂM as in *tâm lý* (psychology). 학교 (hak-gyo, "school") shares its Hanja 學校 (HỌC HIỆU) with the same Vietnamese roots. The app surfaces these connections at every level.

A **ZH / KR language-mode pill** in the top bar switches the entire app between Chinese and Korean. Each mode reshapes the Dict, Graph, Reader, and Decks tabs; the accent color shifts (coral for ZH, indigo for KR).

### Dict Tab

**Chinese mode** — look up any character or compound word. Each entry shows:
- The character at 72px with its **Hán-Việt (HV) reading** in amber
- Pinyin, HSK level badge, Japanese onyomi, Korean hanja, stroke count
- **Structural decomposition (Chiết Tự)** — colour-coded component pills (semantic · phonetic · iconic), each with its own HV reading
- **Vietnamese etymology story** — a 2-3 sentence narrative explaining *why* the components combine to form the meaning. Bundled for HSK 1-6; generated on-device via AI for the rest
- **Frequent compounds** ordered by HV resonance — words where the Vietnamese and Chinese meanings still closely match shown first
- Tapping a compound opens a detail sheet with tappable characters; each character drills into its own Dict Card

**Korean mode** — search Korean words (`학교 / hak-gyo / school`). Each entry shows:
- Large **hangul** with **romaja** reading, English definition, **TOPIK level** badge, and **part-of-speech** badge
- **Hanja root row** (Sino-Korean words) — tappable Hanja chips; tapping one jumps to the Chinese Dict Card for that character
- **Hanja Analysis panel** — per-Hanja tiles with hangul syllable, Hán-Việt reading, pinyin, definition, and component chips
- **Korean Compounds panel** — related Sino-Korean words sharing a Hanja, each with hangul, romaja, Hanja, and TOPIK badge
- **Word Relations** — synonyms, antonyms, and an example sentence (for both native and Sino-Korean words)
- **Explore Hanja Graph** teaser → opens the Korean graph
- A **practice button** → opens single-word writing practice

### Graph Tab
An interactive character/word graph, rendered with a custom painter (no third-party graph library):
- **ZH**: start from a character (search or Dict Card teaser) or pick one of 214 Kangxi radicals. The focal character shows its components (inner ring) and characters sharing the same radical (outer ring). Tap a component → sibling characters; tap a character → its compound words (paginated, HV-resonance ordered); tap a compound → word sheet.
- **KR**: builds Hanja "pivots" from a Korean word's components; native Korean words with no Hanja show a native-word state.

### Reader Tab
Paste, type, or **capture text from a photo** for interlinear annotation:
- **OCR / camera** — "From image" scans a photo (gallery or camera) with on-device ML Kit text recognition (Chinese or Korean script depending on mode) and drops the extracted text into the reader
- **Greedy longest-match segmentation** against the compound-word database — 早晨 is recognised as one token (TẢO THẦN), not two characters
- Toggle **PY** (pinyin) and **HV** (Hán-Việt) annotations independently
- Tap any token → word detail sheet; long-press → open its Component Graph
- **English translation** — offline word-by-word gloss always available; AI natural translation (Claude / Gemini / GPT-4o mini / custom endpoint) on demand, cached locally
- **Vocabulary harvest** — star words → bulk-save to bookmarks or a new deck
- All annotated texts auto-saved to reading history

### Decks Tab
Language-aware deck grids plus shared collections:
- **ZH — HSK Levels**: HSK 1–7 (7 = levels 7-9 combined), paginated 50-per-page, frequency-ordered, with memorized progress
- **KR — TOPIK Levels**: Beginner (I), Intermediate (II), Advanced (III), combining Sino-Korean and native Korean words with memorized progress
- **Daily Practice banner** — a 10-word handwriting quiz (see below)
- **Topic Collections** — Nature, Body, City, Emotions, Time, Family, Learning, Travel, Food, Business, Strong HV Cognates, Popular Song Vocab. In KR mode these show Sino-Korean percentage instead of HV resonance
- **My Collections** — create named decks; add words from the Reader harvest panel
- **Recently Bookmarked** — bookmark characters/words from any Dict Card or list

### Daily Practice
A handwriting quiz launched from the Decks banner (or single-word from a Dict Card's practice button):
- 10 random words (mode-aware — ZH characters or Korean words)
- Shows the definition + reading as the prompt; you **draw the character/word on a finger-paint canvas**
- **Reveal** shows the answer as a tracing guide; **Try again / Next / Got it**; missed words feed a retry round
- Ends with a score summary and "Practice again"

### Daily Word Notifications
A daily word-of-the-day notification (channel *Daily Word*):
- **Mode-aware** — picks a Chinese word in ZH mode, a valid Korean word (native + `kr_verified` Sino-Korean) in KR mode
- **Rotating encouraging taglines** in the title; body shows the word + reading + definition (pinyin for ZH; hangul-only for KR)
- Fires daily at a configurable hour, plus optionally an immediate one on app open
- **Tapping opens the word** — switches to the matching language mode and opens the Dict Card (single character) or word sheet
- Configurable in Settings (enable/disable, hour, on-open)

### Settings
Configure the AI provider used for etymology stories and translation:
- **Claude Haiku 4.5** (Anthropic API key)
- **Gemini Flash** (Google AI key)
- **GPT-4o mini** (OpenAI key)
- **Custom endpoint** (any OpenAI-compatible proxy — base URL + model + key)

Also: language mode, theme (light/dark/system), and notification preferences. API keys are stored in device secure storage (iOS Keychain / Android Keystore).

---

## Database

The app ships with `sinosphere.db` (SQLite) bundled as an asset, copied to writable storage on first launch. Drift ORM, schema version 8.

| Table | Contents |
|---|---|
| `compound_words` | Chinese words — simplified, traditional, pinyin, HV reading + resonance, English def, HSK level, frequency; plus Korean columns: `hangul`, `romaja`, `topik_level`, `is_sino_korean`, `kr_verified`, `pos`, `kr_synonyms`, `kr_antonyms`, `kr_example`, `topik_in_source`, `origin_type` |
| `korean_words` | Native Korean words — `hangul`, `romaja`, `english_def`, `topik_level`, `pos`, `frequency_rank`, `nikl_level`, and enrichment (`synonyms`, `antonyms`, `example_sentence`) |
| `characters` | Chinese characters — symbol, pinyin, HV reading, JP onyomi, stroke count, etymology story |
| `components` | Radical/component records |
| `character_components` | Decomposition links with component type (semantic / phonetic / iconic) |
| `word_characters` | Character ↔ word membership |
| `user_collections` | User-created decks |
| `user_collection_words` | Deck membership + memorized words |
| `reading_history` | Annotated text sessions with serialised token JSON |
| `ai_cache` | Cached AI responses (etymology stories + translations) |

FTS5 virtual table `words_fts` enables sub-50ms full-text search across simplified, HV, pinyin, and English definition (Korean search runs against `hangul` / `romaja` / `english_def`).

**Data sources:** CC-CEDICT · Unihan (Unicode) · MakeMeHanzi · HSK 3.0 · Thiều Chửu · Trần Văn Chánh · Subtlex-CH frequency corpus · NIKL / TOPIK Korean vocabulary · Claude Haiku 4.5 (etymology stories)

---

## Building from source

### Prerequisites
- Flutter 3.47+ / Dart 3.13+
- Python 3.10+ (for the data pipeline)
- Android SDK (for Android build)

### 1. Generate the database

The database is not committed to the repo (too large). Run the pipeline:

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

# Validate
python3 pipeline/validate_db.py

# (Optional) Generate Vietnamese etymology stories via AI
ANTHROPIC_API_KEY=sk-ant-... python3 pipeline/generate_etymology.py --resume
```

You'll need the raw data files in `data/raw/` (Unihan.zip, cedict_ts.u8, Korean vocabulary TSVs, etc.) — see `pipeline/build_db.py` for the full list.

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

> **Note:** The APK is large with the bundled database. For Play Store distribution, Play Asset Delivery is needed to split the database.

#### Android release notes
- **Notifications**: `flutter_local_notifications` requires the scheduled/boot/action receivers to be declared in `android/app/src/main/AndroidManifest.xml`, and the notification icon (`@drawable/ic_notification`) must be kept from resource shrinking via `res/raw/keep.xml` — both are configured. R8 keep rules for the plugin and Gson live in `proguard-rules.pro`.
- **OCR**: ML Kit text-recognition script models (Chinese, Korean, and others) are declared in `app/build.gradle.kts` and kept in ProGuard.

---

## Project structure

```
sinosphere/
├── pipeline/               ← Python data pipeline
│   ├── build_db.py         ← Core DB builder
│   ├── patch_hanviet.py    ← HV reading backfill
│   ├── patch_compounds.py  ← Compound HV recompute
│   ├── patch_jp_strokes.py ← JP onyomi + stroke counts
│   ├── generate_etymology.py ← AI etymology story generation
│   └── validate_db.py      ← Validation suite
├── app/                    ← Flutter project
│   ├── lib/
│   │   ├── core/
│   │   │   ├── database/   ← Drift ORM (tables, DAOs)
│   │   │   ├── services/   ← AI, OCR, notifications, DB provider, lang mode
│   │   │   └── theme/      ← Dark/light theme tokens
│   │   └── features/
│   │       ├── dict_card/  ← Dict Card (ZH + KR) + widgets
│   │       ├── graph/      ← Graph Explorer (ZH + KR, CustomPainter)
│   │       ├── reader/     ← Smart Reader + annotation + OCR
│   │       ├── collections/← Decks: HSK, TOPIK, topics, bookmarks
│   │       ├── practice/   ← Daily/single-word handwriting practice
│   │       ├── search/     ← Search bar with FTS + LIKE fallback
│   │       ├── settings/   ← AI provider, notifications, theme
│   │       ├── shell/      ← Bottom nav shell + language pill
│   │       └── splash/     ← Startup splash
│   └── assets/sinosphere.db ← (generated, not committed)
└── sinosphere_rosetta_prd.md ← Original product requirements
```

---

## Tech stack

| Layer | Technology |
|---|---|
| UI | Flutter 3.47 · Dart 3.13 |
| State | Riverpod (NotifierProvider throughout) |
| Database | Drift over SQLite · FTS5 for search |
| AI | HTTP calls to Claude / Gemini / OpenAI / custom OpenAI-compatible endpoints |
| OCR | google_mlkit_text_recognition (Chinese + Korean scripts) |
| Notifications | flutter_local_notifications (daily scheduled + on-open) |
| Secure storage | flutter_secure_storage (Keychain / Keystore) |
| Graph rendering | Flutter CustomPainter (no third-party graph library) |

---

## Etymology stories

The Vietnamese Chiết Tự narratives are generated by Claude Haiku 4.5 using a Vietnamese-language prompt that explains the component logic. Stories are cached in the DB, and on-device generation fills gaps as users encounter them. Coverage is highest for the lower HSK bands (HSK 1-4 ~100%) and tapers for the higher levels.
