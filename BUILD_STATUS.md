# Sinosphere Rosetta — Project Context & Build Status

**App:** Vietnamese-English bilingual dictionary app for Vietnamese learners of Mandarin Chinese  
**Core concept:** Every Chinese character has a Hán-Việt (Sino-Vietnamese) reading — cognate with the Mandarin. The app exploits this to make Chinese vocabulary immediately memorable for Vietnamese speakers. A character like 晨 (chén) maps to THẦN in Vietnamese; the component analysis (chiết tự) explains the etymology as a story in Vietnamese.  
**Stack:** Flutter 3.47.0 · Dart 3.13 · Drift SQLite · Riverpod v3 · Multi-provider AI  
**Package ID:** `com.sinosphere.sinosphere_rosetta`  
**Last updated:** 2026-08-13

---

## Directory Layout

```
sinophere/
├── app/                        ← Flutter project
│   ├── assets/sinosphere.db    ← 82 MB SQLite DB (bundled asset)
│   ├── lib/                    ← 20 Dart source files
│   └── pubspec.yaml
├── data/
│   ├── db/sinosphere.db        ← master DB (copy to app/assets/ before building)
│   └── raw/
│       ├── unihan/             ← Unihan_Readings.txt, Unihan_RadicalStrokeCounts.txt
│       └── Unihan.zip          ← full Unihan data (kTotalStrokes in IRGSources.txt)
├── pipeline/                   ← 6 Python scripts
├── sinosphere_prototype.html   ← interactive HTML prototype (full UX)
├── sinosphere_firstscreen.html ← first-screen mockup
├── sinosphere_rosetta_prd.md   ← Product Requirements Document
└── BUILD_STATUS.md             ← this file
```

---

## Phase 0 — Data Pipeline ✅ Complete

### Pipeline scripts (run in order for a clean build)

```bash
cd sinophere/
python3 pipeline/build_db.py          # ~10 min — builds sinosphere.db from scratch
python3 pipeline/patch_hanviet.py     # ~2 min — backfills HV readings
python3 pipeline/patch_compounds.py   # ~1 min — recomputes compound HV from patched chars
python3 pipeline/patch_jp_strokes.py  # ~30 sec — fills jp_onyomi + stroke_count
python3 pipeline/validate_db.py       # ~10 sec — 63 assertions, expect 0 errors
python3 pipeline/generate_etymology.py --resume  # ongoing — AI story generation
```

### Data sources used

| Source | Path / URL | Used for |
|---|---|---|
| CC-CEDICT | `data/raw/cedict_ts.u8` | English defs, pinyin, traditional variants |
| MakeMeHanzi | `data/raw/dictionary.txt` | Component decomposition, component type (semantic/phonetic/iconic) |
| Unihan | `data/raw/Unihan.zip` + `data/raw/unihan/` | HV readings (`kVietnamese`), KR hangul (`kHangul`), JP onyomi (`kJapaneseOn`), stroke count (`kTotalStrokes` from IRGSources.txt) |
| HSK 3.0 | `data/raw/hsk/` | HSK level tags 1-7 (level 7 = HSK 7-9) |
| Thiều Chửu + Trần Văn Chánh | `data/raw/thieuchuu.json` | Supplementary HV readings |
| HanziStoriesViet | `data/raw/hanzistoriesviet.json` | Additional HV readings |
| Subtlex-CH | `data/raw/subtlex_ch.txt` | Word frequency ranks |
| Claude Haiku 4.5 | API (Anthropic / SAP Hyperspace) | Vietnamese chiết tự etymology stories |

### Etymology story generation

Stories are 2-3 sentence Vietnamese narratives explaining a character's meaning through its components. Generated via `generate_etymology.py`:

```bash
# Run with direct Anthropic API key
ANTHROPIC_API_KEY=sk-ant-... python3 pipeline/generate_etymology.py --resume

# Run via SAP Hyperspace proxy
HYPERSPACE_BASE_URL=https://api.hyperspace.tools.sap/llm-proxy/anthropic \
HYPERSPACE_API_KEY=<your-api-key> \
python3 pipeline/generate_etymology.py --resume

# Other options
--char 晨          # single character
--limit 100        # process N characters then stop
--priority         # HSK 1 first, then 2, etc.
```

`--resume` is on by default — skips characters that already have a story. The Batches API is not available on Hyperspace; the script auto-falls back to individual calls.

### Database stats (as of 2026-08-13)

| Metric | Value |
|---|---|
| Compound words | 119,449 |
| Characters | 9,565 |
| With Hán-Việt reading | 9,000 (94.1%) |
| With JP Onyomi | 7,114 (74.4%) |
| With stroke count | 9,565 (100%) |
| HSK-tagged words | 10,957 |
| High HV-resonance words | 88,997 |
| With etymology story | 2,707 |
| DB size | 82 MB |

### Etymology coverage by HSK level

| Level | Coverage |
|---|---|
| HSK 1 | 289/289 (100%) |
| HSK 2 | 491/491 (100%) |
| HSK 3 | 648/648 (100%) |
| HSK 4 | 823/823 (100%) |
| HSK 5 | 922/941 (98%) |
| HSK 6 | 949/974 (97%) |
| HSK 7-9 | 2,232/2,724 (82%) |

### DB schema (8 tables)

```
characters        id, symbol, pinyin, hangul, han_viet, english_def,
                  etymology_story, decomposition, radical, hsk_level,
                  jp_onyomi, stroke_count
                  NOTE: hsk_level is always NULL — use compound_words instead

components        id, symbol, pinyin, han_viet, english_def, stroke_count

character_components  character_id, component_id, component_type, position
                      component_type: 'semantic' | 'phonetic' | 'iconic'

compound_words    id, simplified, traditional, pinyin, hangul, han_viet,
                  han_viet_resonance, vietnamese_note, english_def,
                  hsk_level, frequency_rank, origin_type,
                  is_cognate_anchor, ai_generated

word_characters   word_id, character_id, position

user_collections  id, name, icon, created_at
                  Special ID: 'bookmarks' (auto-created on first bookmark)

user_collection_words  collection_id, word_id, added_at
                       NOTE: word_id stores character.id (not compound_words.id)

reading_history   id, title, raw_text, token_json, created_at   [Phase 3]
ai_cache          query, response_json, cached_at
```

FTS5 virtual table: `words_fts` — content table over `compound_words`, indexes `simplified`, `han_viet`, `pinyin`, `english_def`.

---

## Phase 1 — Flutter App ✅ Complete

`flutter analyze lib/` → **0 errors, 0 warnings**

### Flutter project structure

```
app/lib/
├── main.dart                          ← splash + DB init (Isolate.run for 82MB copy)
├── app.dart                           ← MaterialApp + ThemeModeNotifier
├── core/
│   ├── database/
│   │   ├── database.dart              ← @DriftDatabase, openDatabase()
│   │   ├── tables/tables.dart         ← 8 Drift table classes
│   │   └── daos/
│   │       ├── character_dao.dart     ← CharacterDetail, getHskLevel(), getComponents()
│   │       ├── compound_dao.dart      ← FTS5 search + LIKE fallback
│   │       └── collection_dao.dart    ← bookmarks (stores character.id as word_id)
│   ├── services/
│   │   ├── ai_service.dart            ← LlmProvider enum, LlmSettingsNotifier
│   │   └── database_provider.dart     ← databaseProvider (must be overridden in ProviderScope)
│   └── theme/
│       └── app_theme.dart             ← SinosphereColors ThemeExtension, context.colors
└── features/
    ├── shell/app_shell.dart           ← 4-tab NavigationBar + IndexedStack
    ├── dict_card/
    │   ├── dict_card_screen.dart      ← DictCardScreen, _SearchResultSheet, _WordBottomSheet
    │   ├── dict_card_provider.dart    ← activeSymbolProvider, characterDetailProvider
    │   └── widgets/
    │       ├── character_hero.dart    ← 72px symbol, HV, HSK badge, JP/KR/strokes
    │       ├── component_tree.dart    ← semantic/phonetic/iconic pills
    │       ├── etymology_card.dart    ← 3 states: story / shimmer / missing
    │       └── compound_list.dart     ← 8 most frequent compounds
    ├── search/search_bar.dart         ← SinosphereSearchBar, chip, direct DB query
    ├── collections/collections_screen.dart  ← bookmarkedSymbolsProvider (public)
    └── settings/settings_screen.dart  ← LLM config, RadioGroup, theme toggle
```

### Key architectural decisions

**DB init:** `openDatabase()` in `database.dart` — checks if DB exists, copies 82 MB asset via `Isolate.run()` (non-blocking), then opens. Called before `runApp()` but after the splash screen is shown.

**State management:** Riverpod v3. All providers use `NotifierProvider` / `AsyncNotifier` (no deprecated `StateProvider`). Key providers:
- `databaseProvider` — must be overridden in `ProviderScope` (throws if not)
- `activeSymbolProvider` — currently shown character symbol (default `晨`)
- `characterDetailProvider(symbol)` — `FutureProvider.family`, loads full `CharacterDetail`
- `bookmarkedSymbolsProvider` — in `collections_screen.dart`, **public** so dict card can invalidate it
- `llmSettingsProvider` — `AsyncNotifier<LlmSettings>` with `.save()` method (not `.update()`)
- `themeModeProvider` — `NotifierProvider<ThemeModeNotifier, ThemeMode>` with `.set()` and `.toggle()`

**HSK level on character:** `characters.hsk_level` is always NULL in the DB. Use `CharacterDao.getHskLevel(characterId)` which queries `MIN(hsk_level)` from `compound_words` via `word_characters`.

**Search:** `SinosphereSearchBar` runs queries directly in `ConsumerStatefulWidget` state — no `FutureProvider.family`. 350ms debounce. FTS5 primary (`"query" OR query*`), LIKE fallback on error. Single-char result → sets `activeSymbolProvider`. Multi-char result → opens `_SearchResultSheet`. Persistent chip shows last result for quick reopen.

**Bookmarks:** `toggleBookmark(char.id)` stores `character.id` in `user_collection_words.word_id`. `getBookmarkedSymbols()` joins `characters` directly. After toggling, invalidate both `bookmarkProvider(char.id)` and `bookmarkedSymbolsProvider`.

**Compound sheets:** Both `_WordBottomSheet` (from compound list) and `_SearchResultSheet` (from search) are consistent — `DraggableScrollableSheet`, each character at 48px font, individually tappable via `GestureDetector` → `Navigator.pop` + `activeSymbolProvider.set(ch)`.

### Colour tokens

```dart
background  = Color(0xFF020817)  // slate-950
surface     = Color(0xFF0F172A)  // slate-900
card        = Color(0xFF1E293B)  // slate-800
hanviet     = Color(0xFFF59E0B)  // amber-500   — HV readings
semantic    = Color(0xFF10B981)  // emerald-500  — semantic components
phonetic    = Color(0xFF3B82F6)  // blue-500     — phonetic components
iconic      = Color(0xFFA855F7)  // purple-500   — iconic components
sky         = Color(0xFF38BDF8)  // sky-400      — pinyin, compounds
learned     = Color(0xFF8B5CF6)  // violet-500   — user nodes (Graph phase)
```

Access via `context.colors` (returns `SinosphereColors` ThemeExtension).

### AI / LLM integration

Four providers in `ai_service.dart`:

| Provider | Enum value | Notes |
|---|---|---|
| Claude Haiku 4.5 | `LlmProvider.claude` | `claude-haiku-4-5-20251001` |
| Gemini Flash | `LlmProvider.gemini` | `gemini-1.5-flash` |
| GPT-4o mini | `LlmProvider.openai` | `gpt-4o-mini` |
| Custom | `LlmProvider.custom` | OpenAI-compatible endpoint; SAP Hyperspace base URL: `https://api.hyperspace.tools.sap/llm-proxy/anthropic`, API key = Hyperspace API key |

API keys stored in `flutter_secure_storage`. Keys: `llm_provider`, `llm_api_key`, `llm_base_url`.

Vietnamese chiết tự prompt matches `pipeline/generate_etymology.py` system prompt exactly.

### Dependencies

```yaml
drift: ^2.23.1           # resolved: 2.34.3
drift_sqflite: ^2.0.1
sqflite: ^2.4.2
path_provider: ^2.1.5
path: ^1.9.1
flutter_riverpod: ^3.4.2  # resolved: 3.4.2 — Riverpod v3, no StateProvider
riverpod_annotation: ^4.0.6
http: ^1.2.2
flutter_secure_storage: ^11.0.0
url_launcher: ^6.3.1
shimmer: ^3.0.0
uuid: ^4.6.0
# dev
drift_dev: ^2.23.1
build_runner: ^2.4.14
riverpod_generator: ^4.0.8
```

---

## Android / iOS Status

| Platform | Status |
|---|---|
| Android | ✅ APK built and tested on Xiaomi device |
| iOS | ❌ Xcode setup incomplete — not yet built |

Build: `cd sinophere/app && flutter build apk --release`  
Output: `build/app/outputs/flutter-apk/app-release.apk` (~130 MB)

> Play Store limit is 100 MB for initial download — need Play Asset Delivery to split the 82 MB DB for store submission.

### Bugs fixed in real-device testing

| Bug | Root cause | Fix |
|---|---|---|
| Search kept loading | `FutureProvider.family` spawned new instance per keystroke; no debounce | Rewrote to direct `async` call in widget state with 350ms debounce |
| Search slow on first launch | 82 MB `rootBundle.load` blocked main thread | `Isolate.run()` for file write; splash shown immediately |
| FTS5 broken on some Android | Older SQLite may not support FTS5 query syntax | LIKE fallback on exception |
| HSK badge missing | `characters.hsk_level` never populated in pipeline | `getHskLevel()` queries from `compound_words` |
| JP Onyomi / strokes blank | Pipeline never populated these columns | `patch_jp_strokes.py` reads from Unihan zip |
| Component text cut off | Hard 55-char truncation | Removed; `maxLines: 3, overflow: ellipsis` |
| Compound sheet cut off | `showModalBottomSheet` default height + no scroll | `DraggableScrollableSheet` + `ListView` |
| Compound sheet chars not tappable | Plain `Text` widget, no interaction | Both sheet types use `GestureDetector` per character |
| Bookmark not appearing in Decks | `getBookmarkedSymbols` joined via `compound_words` (wrong) + provider never invalidated | Fixed join to `characters` directly; `ref.invalidate(bookmarkedSymbolsProvider)` on toggle |

---

## Remaining Work

### Phase 1 — Polish
- [ ] HSK deck word counts in Decks screen hardcoded → query DB at runtime
- [ ] 12 topic packs in Decks are UI stubs → back with real DB queries
- [ ] Bookmark button not on compound list rows (only on main character card)
- [ ] Finish etymology generation: HSK 7-9 at 82% → target 95%+
- [ ] App icon + splash screen asset (currently default Flutter icon)
- [ ] iOS build (install CocoaPods, complete Xcode setup)

### Phase 2 — Graph Explorer
- [ ] `CustomPainter` canvas, 3-tier graph (radical → character → compound)
- [ ] Radical picker (214 radicals)
- [ ] Filter: All / Strong HV Cognates / My Words
- [ ] Seed graph with HSK 1-4 on first launch
- [ ] "Explore Component Graph" on Dict Card navigates to that character's graph

### Phase 3 — Smart Reader
- [ ] Chinese text paste + segmentation (Jieba via FFI)
- [ ] Interlinear annotation (pinyin above, HV below)
- [ ] Tap word → Dict Card
- [ ] Add to deck from Reader
- [ ] Reading history (`reading_history` table already in schema)

### Phase 4 — Distribution
- [ ] Play Asset Delivery for 82 MB DB
- [ ] App Store submission

---

## Prototype

`sinosphere_prototype.html` — open in any browser, no server needed.

Tabs: Dict Card · Graph Explorer · Smart Reader · Decks  
Search demo data: 晨, 明, 城, 地, 学, 心 + 28 compound words  
Search flow: type → dropdown shows compounds → tap → word sheet with tappable chars → tap char → dict card  
After sheet dismissal: chip shows last word for quick reopen
