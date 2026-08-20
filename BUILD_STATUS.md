# Sinosphere — Project Context & Build Status

**App:** Vietnamese-English bilingual dictionary app for Vietnamese learners of Mandarin Chinese, with Korean learner mode  
**Core concept:** Every Chinese character has a Hán-Việt (Sino-Vietnamese) reading — cognate with the Mandarin. The app exploits this to make Chinese vocabulary immediately memorable for Vietnamese speakers. A character like 晨 (chén) maps to THẦN in Vietnamese; the component analysis (chiết tự) explains the etymology as a story in Vietnamese.  
**Stack:** Flutter 3.47.0 · Dart 3.13 · Drift SQLite · Riverpod v3 · Multi-provider AI  
**Package ID:** `com.sinosphere.sinosphere_rosetta`  
**GitHub:** https://github.com/utn100/sinosphere (public)  
**Last updated:** 2026-08-20

---

## Directory Layout

```
sinophere/
├── app/                        ← Flutter project
│   ├── assets/sinosphere.db    ← 83 MB SQLite DB (bundled asset, not committed)
│   ├── lib/                    ← Dart source files
│   └── pubspec.yaml
├── data/
│   ├── db/sinosphere.db        ← master DB (copy to app/assets/ before building)
│   └── raw/                    ← source data files (not committed)
├── pipeline/                   ← 8 Python scripts
├── sinosphere_prototype.html   ← interactive HTML prototype (full UX)
├── sinosphere_rosetta_prd.md   ← Product Requirements Document
└── BUILD_STATUS.md             ← this file
```

---

## Phase 0 — Data Pipeline ✅ Complete

### Pipeline scripts (run in order for a clean build)

```bash
python3 pipeline/build_db.py          # ~10 min — builds sinosphere.db from scratch
python3 pipeline/patch_hanviet.py     # ~2 min — backfills HV readings
python3 pipeline/patch_compounds.py   # ~1 min — recomputes compound HV from patched chars
python3 pipeline/patch_jp_strokes.py  # ~30 sec — fills jp_onyomi + stroke_count
python3 pipeline/validate_db.py       # ~10 sec — 63 assertions, expect 0 errors
python3 pipeline/generate_etymology.py --resume  # ongoing — AI story generation
```

### Data sources

| Source | Used for |
|---|---|
| CC-CEDICT | English defs, pinyin, traditional variants |
| MakeMeHanzi | Component decomposition, component type (semantic/phonetic/iconic) |
| Unihan | HV readings, JP onyomi, stroke count |
| HSK 3.0 | HSK level tags 1-7 |
| Thiều Chửu + Trần Văn Chánh | Supplementary HV readings |
| Subtlex-CH | Word frequency ranks |
| Claude Haiku 4.5 | Vietnamese chiết tự etymology stories |

### Etymology story generation

```bash
# Direct Anthropic API
ANTHROPIC_API_KEY=sk-ant-... python3 pipeline/generate_etymology.py --resume

# Other options
--char 晨       # single character
--limit 100     # process N then stop
--priority      # HSK 1 first, then 2, etc.
```

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
| With etymology story | ~6,500 (68%) |
| DB size | 83 MB |

### Etymology coverage by HSK level

| Level | Coverage |
|---|---|
| HSK 1–4 | 100% |
| HSK 5 | 98% |
| HSK 6 | 97% |
| HSK 7-9 | 82% |

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
                  Special IDs: 'bookmarks', 'memorized' (auto-managed)

user_collection_words  collection_id, word_id, added_at
                       NOTE: word_id stores character.id (not compound_words.id)
                       'memorized' collection used for HSK check-off

reading_history   id, title, raw_text, token_json, created_at
ai_cache          query, response_json, cached_at
```

FTS5 virtual table: `words_fts` — content table over `compound_words`, indexes `simplified`, `han_viet`, `pinyin`, `english_def`.

---

## Phase 1 — Flutter App ✅ Complete

### Flutter project structure

```
app/lib/
├── main.dart                          ← splash + DB init (Isolate.run for 83MB copy)
├── app.dart                           ← MaterialApp + ThemeModeNotifier
├── core/
│   ├── database/
│   │   ├── database.dart              ← @DriftDatabase, openDatabase()
│   │   ├── tables/tables.dart         ← 8 Drift table classes
│   │   └── daos/
│   │       ├── character_dao.dart     ← CharacterDetail, getHskLevel(), getComponents()
│   │       ├── compound_dao.dart      ← FTS5 search + LIKE fallback
│   │       └── collection_dao.dart    ← bookmarks, memorized, topic queries
│   ├── services/
│   │   ├── ai_service.dart            ← LlmProvider enum, LlmSettingsNotifier, translateText()
│   │   └── database_provider.dart
│   └── theme/app_theme.dart           ← SinosphereColors ThemeExtension, context.colors
└── features/
    ├── shell/app_shell.dart           ← 5-tab NavigationBar + IndexedStack
    ├── dict_card/
    │   ├── dict_card_screen.dart      ← DictCardScreen, _SearchResultSheet, _WordBottomSheet
    │   ├── dict_card_provider.dart
    │   └── widgets/
    │       ├── character_hero.dart    ← 72px symbol, HV, HSK badge, JP/KR/strokes
    │       ├── component_tree.dart    ← semantic/phonetic/iconic pills
    │       ├── etymology_card.dart    ← 3 states: story / shimmer / missing
    │       └── compound_list.dart     ← 8 compounds, bookmark button per row
    ├── search/search_bar.dart         ← 350ms debounce, FTS5 + LIKE fallback
    ├── graph/                         ← Phase 2 (see below)
    ├── reader/                        ← Phase 3 (see below)
    ├── collections/
    │   ├── collections_screen.dart    ← HSK grid, topic packs, user decks, bookmarks
    │   └── collection_detail_screen.dart ← CollectionDetailScreen, HskDetailScreen, TopicDetailScreen
    └── settings/settings_screen.dart  ← LLM config, RadioGroup, theme toggle
```

### Key architectural decisions

**State management:** Riverpod v3. All providers use `NotifierProvider` / `AsyncNotifier`. No `StateProvider`. Key providers:
- `databaseProvider` — must be overridden in `ProviderScope`
- `activeSymbolProvider` — currently shown character symbol
- `characterDetailProvider(symbol)` — `FutureProvider.family`
- `bookmarkedSymbolsProvider` — public, invalidated after bookmark toggle
- `llmSettingsProvider` — `AsyncNotifier<LlmSettings>` with `.save()` (not `.update()`)
- `tabIndexProvider` — controls bottom nav tab selection

**HSK level on character:** `characters.hsk_level` is always NULL. Use `CharacterDao.getHskLevel(characterId)` which queries `MIN(hsk_level)` from `compound_words` via `word_characters`.

**Search:** `SinosphereSearchBar` runs queries directly in `ConsumerStatefulWidget` — no `FutureProvider.family`. 350ms debounce. FTS5 primary, LIKE fallback on error.

**Bookmarks:** `toggleBookmark(char.id)` stores `character.id` in `user_collection_words.word_id`. `getBookmarkedSymbols()` joins `characters` directly (not via compound_words).

**Compound sheets:** Both `_WordBottomSheet` and `_SearchResultSheet` are consistent — `DraggableScrollableSheet`, each character 48px, tappable.

**CollectionItem UNION query:** `getCollectionItems(collectionId)` uses UNION of characters JOIN and compound_words JOIN so both single-char and multi-char entries work.

### AI integration

| Provider | Model | Notes |
|---|---|---|
| Claude Haiku 4.5 | `claude-haiku-4-5-20251001` | Direct Anthropic API (`api.anthropic.com`) only |
| Gemini Flash | `gemini-1.5-flash` | Direct Google AI |
| GPT-4o mini | `gpt-4o-mini` | Direct OpenAI |
| Custom | configurable | Any OpenAI-compatible endpoint |

Keys stored in `flutter_secure_storage`. For non-Custom providers, `baseUrl` is never read from storage (fixed by clearing stale Hyperspace URLs on `saveSettings`).

### Bugs fixed in real-device testing (Android Xiaomi)

| Bug | Root cause | Fix |
|---|---|---|
| ALL API calls fail on Android | Missing `<uses-permission android:name="android.permission.INTERNET"/>` | Added to AndroidManifest.xml |
| Search kept loading | `FutureProvider.family` spawned new instance per keystroke | Rewrote to direct async call + 350ms debounce |
| FTS5 broken on some Android SQLite | FTS5 query syntax unsupported | LIKE fallback on exception |
| HSK badge missing | `characters.hsk_level` never populated | `getHskLevel()` queries from `compound_words` |
| Compound sheet cut off | `showModalBottomSheet` default height | `DraggableScrollableSheet` + `ListView` |
| Compound sheet chars not tappable | Plain Text widget | `GestureDetector` per character |
| Bookmark not appearing in Decks | Wrong JOIN + provider never invalidated | Fixed JOIN + `ref.invalidate(bookmarkedSymbolsProvider)` |
| Claude API routing to wrong server | Stale Hyperspace base URL in secure storage | `_callClaude` never uses baseUrl; `saveSettings` clears it for non-Custom |
| Collection nav leaves detail on stack | `Navigator.pop` then `tabIndexProvider.set(0)` | Capture `NavigatorState` before async gap; `nav.popUntil((r) => r.isFirst)` |
| 0 words added to new deck | ID mismatch: `starred.contains(charId)` vs starred containing `charId ?? wordId` | Match ID resolution in both places |
| Riverpod v3 breaking changes | `StateProvider`, `AsyncNotifier.update()`, `FamilyNotifier` removed | `NotifierProvider`, `.save()`, `NotifierProvider.family((id) => Notifier(id))` |

---

## Phase 2 — Graph Explorer ✅ Complete

`lib/features/graph/` — custom `CustomPainter` canvas with `InteractiveViewer`.

### Architecture

- **`GraphState`**: `nodes`, `edges`, `compoundPages` (pagination map), `isLoading`
- **`GraphNodeType`**: `character`, `component`, `sibling`, `compound`, `showMore`
- **`GraphProvider`**: `NotifierProvider<GraphNotifier, GraphState>`

### Graph seeding

- Opens on a default character (晨) with its component and character ring pre-expanded
- Radical picker (214 Kangxi radicals) lets user start from any radical
- `setFocalWord(wordSimplified, charSymbols)`: places compound word at center with each char as sibling node

### Interaction

| Action | Result |
|---|---|
| Tap component node | Expand sibling characters that share the component |
| Tap sibling character | Expand its compound words (paginated, HV resonance ordered) |
| Tap focal character | Expand/collapse its compound words |
| Tap compound node | `_GraphWordSheet` with tappable characters |
| `+` button | Load next page of compound words (5 per page) |
| `−` button | Remove last page of compound words (type-filtered: only compound/showMore nodes, leaves components intact) |
| Radical picker chip | Open 214-radical scrollable panel; tap radical → set as focal |

### Key fixes

- **GestureDetector inside InteractiveViewer** (not wrapping it) — essential for correct hit testing
- **`expandFocalCompounds`** separate from `expandSibling` — focal node expansion doesn't wipe components
- **`removeLastCompoundPage`** type-filtered — only removes `compound` and `showMore` nodes, not component/sibling nodes
- **ShowMore ID extraction**: strips both `'sib:'` and `'focal:'` prefixes before charId lookup

### Colour coding

- Focal node: amber (HV color)
- Component nodes: emerald (semantic), blue (phonetic), purple (iconic)
- Sibling characters: sky blue
- Compound words: violet
- Show-more chips: grey

---

## Phase 3 — Smart Reader ✅ Complete

`lib/features/reader/` — Chinese text annotation with vocabulary harvest.

### Architecture

- **`ReaderState`**: `tokens`, `rawText`, `annotationMode`, `starred`, `aiTranslation`, `isTranslating`, `isAnnotating`, `history`
- **`AnnotationMode`**: `hanviet`, `pinyin`, `both`, `none` (independent toggles)
- **`ReaderToken`**: `text`, `charId`, `wordId`, `hanViet`, `pinyin`, `englishDef`, `isKnown`

### Segmentation

Greedy longest-match (up to 8 chars) against `compound_words` table. Falls back to single character if no match. Runs in `Isolate.run` to avoid UI jank.

### Features

| Feature | Detail |
|---|---|
| PY / HV toggles | Independent; PY is default; can reach `none` mode |
| Inline annotation | Pinyin below token, HV reading above token |
| Tap token | `TokenDetailSheet` with tappable characters |
| Long-press token | Navigate to token's Component Graph |
| AI translation | Claude/Gemini/GPT-4o mini; cached in `ai_cache` table; `translateWithAi()` checks cache first |
| Word-by-word gloss | Always available offline; collapsible below AI translation |
| Vocabulary harvest | Star tokens → bulk save to bookmarks or new deck via `HarvestPanel` |
| Reading history | All annotated texts auto-saved; `ref.invalidate(readerHistoryProvider)` after save |
| Sample snippet | Pre-seeded text labelled "Sample" |
| Custom snippet | Paste area: full-width outlined button |
| Settings shortcut | Settings button in header → `Navigator.push(SettingsScreen)` |

### `HarvestPanel`

Bottom sheet showing starred tokens with checkboxes. "Save to Decks" opens deck picker (existing decks + "Create New"). ID resolution: `token.charId ?? token.wordId ?? token.text` (must match `_HarvestRow` ID check).

---

## Phase 4 — Decks & Collections ✅ Complete

`lib/features/collections/` — three collection types plus bookmarks.

### HSK Decks

7 decks (HSK 1–7, where HSK 7 = levels 7-9 combined). `HskDetailScreen`: paginated 50/page, memorize check-off, reset button. Memorized state stored in `user_collection_words` with `collection_id = 'memorized'`.

### Topic Collections

12 topic packs implemented via keyword SQL LIKE queries on `english_def` — no DB migration required:

| Topic | Keywords |
|---|---|
| Nature & Cosmos | mountain, water, sky, flower, tree, earth, river, cloud, wind, season |
| Body & Mind | body, heart, head, hand, eye, face, mind, blood |
| City & Places | city, street, building, road, house, place, market, shop |
| Emotions & Character | happy, sad, angry, love, fear, hope, feel, emotion |
| Time & History | time, day, year, history, period, century, moment, hour |
| Family & Society | family, father, mother, child, brother, sister, society, people |
| Learning & Knowledge | learn, study, school, knowledge, teach, book, language |
| Travel & Transport | travel, transport, car, train, road, trip, airport, ship |
| Food & Drink | food, eat, drink, cook, rice, fruit, meat, dish |
| Business & Economy | business, money, work, economy, trade, company, price, market |
| Strong HV Cognates | `is_cognate_anchor = 1` (1,764 words) |
| Popular Song Vocab | `hsk_level <= 3 AND han_viet_resonance = 'medium'` |

`TopicDetailScreen` mirrors `HskDetailScreen` (paginated, memorize-able). `CollectionDao._topicWhere` static map drives all queries.

### User Collections (My Decks)

Create named decks from Decks tab. Words added via Reader's `HarvestPanel`. `CollectionDetailScreen` uses UNION query covering both char IDs and compound word IDs. Word sheet chars are tappable → opens Dict Card via pre-captured `NavigatorState` + `nav.popUntil((r) => r.isFirst)`.

### Bookmarks

Bookmark button on compound list rows and character hero. `bookmarkedSymbolsProvider` (public) auto-refreshes grid.

---

## Settings ✅ Complete

`lib/features/settings/settings_screen.dart` — full LLM config screen.

- Provider selection: Claude / Gemini / GPT-4o mini / Custom
- API key field (masked), base URL + model name (Custom only)
- `LlmSettings.isConfigured`: false if key empty OR (custom AND baseUrl empty)
- `saveSettings()`: deletes `llm_base_url` + `llm_custom_model` from storage for non-Custom providers
- No Hyperspace references in the app UI

---

## Android / iOS Status

| Platform | Status |
|---|---|
| Android | ✅ APK built and tested on Xiaomi device |
| iOS | ❌ Xcode setup incomplete — not yet built |

Build: `cd app && flutter build apk --release`  
Output: `build/app/outputs/flutter-apk/app-release.apk` (~130 MB)

> Play Store limit is 100 MB for initial download — need Play Asset Delivery to split the 83 MB DB for store submission.

---

## GitHub

Repo: https://github.com/utn100/sinosphere (public, account utn100)  
117 files committed. `.gitignore` excludes: `data/db/`, `data/raw/`, `app/assets/sinosphere.db`, `app/assets/icon.png`, `.claude/`.

---

## Remaining Work

### Near-term
- [ ] Rebuild APK to include all recent fixes (graph `-` fix, topic collections, nav fix)
- [ ] Finish etymology generation: HSK 7-9 at 82% → target 95%+
- [ ] App icon + splash screen asset (currently default Flutter icon)
- [ ] iOS build (CocoaPods + Xcode setup)

### Deferred features
- [ ] Synonym / antonym "related words" (needs separate data source — not in CC-CEDICT)
- [ ] Graph "My Words" filter layer (learned words shown differently)
- [ ] AI grammar notes / register detection in Reader
- [ ] Play Asset Delivery for Play Store submission (83 MB DB)
---

## Recent Enhancements (2026-08-14)

### Image OCR in Reader Tab
- New "From image" button beside "Paste text" in Reader input area
- Uses `google_mlkit_text_recognition` (on-device, no API key, Chinese script model)
- Gallery or camera pick via `image_picker`; extracted text populates input field for user review before annotating
- Camera permission added to `AndroidManifest.xml`; all 5 ML Kit script model deps added to `build.gradle.kts` (required by R8)
- New `lib/core/services/ocr_service.dart`; `isExtractingOcr` state in `ReaderState`

### Topic Collections — DB Migration + Word Count
- New `pipeline/tag_topics.py`: uses `\b` word-boundary regex (not `LIKE '%keyword%'`) to tag words accurately. Run against `data/db/sinosphere.db` before rebuilding APK.
- `compound_words` table now has `topic_tag TEXT` column (Drift schema v2 migration)
- `_topicWhere` in `CollectionDao` rewritten to query `topic_tag LIKE '%topicId%'` — zero false positives from substring collisions
- `topicWordCountProvider` added; `_TopicRow` updated to `ConsumerWidget` showing live word count (e.g. "342 words") below topic name

### Word Enrichment in Bottom Sheets
- New `pipeline/generate_word_details.py`: generates synonyms, antonyms, example sentence per word via Claude Haiku. Run with `--resume` flag. Supports `--word`, `--limit`, `--priority`, `--status`.
- `compound_words` gains 3 new columns: `synonyms TEXT`, `antonyms TEXT`, `example_sentence TEXT` (Drift schema v3 migration)
- New `lib/features/dict_card/widgets/word_enrichment.dart` — `WordEnrichmentSection` widget with shimmer loading and on-device AI generation fallback
- Applied to all 3 bottom sheets: `_WordBottomSheet` (Dict Card), `_CollectionWordSheet` (Decks), `TokenDetailSheet` (Reader)
- `showCollectionWordSheet()` gains optional `wordId` param; passed through from HSK and Topic detail screens
- New `CompoundDao.getById()` and `updateWordDetails()` methods
- New `AiService.generateWordDetails()` method; `WordDetails` record class

### Schema versions
| Version | Migration |
|---|---|
| 1 | Initial |
| 2 | `topic_tag TEXT` on `compound_words` |
| 3 | `synonyms`, `antonyms`, `example_sentence` TEXT on `compound_words` |

### Pipeline workflow (after these changes)
```bash
# 1. Tag topics (required for topic collections to work correctly)
python3 pipeline/tag_topics.py

# 2. Pre-generate word enrichment for HSK 1-6 (optional but recommended)
ANTHROPIC_API_KEY=sk-ant-... python3 pipeline/generate_word_details.py --resume --priority

# 3. Copy updated DB to app assets
cp data/db/sinosphere.db app/assets/sinosphere.db

# 4. Build APK (Drift migration runs automatically on first launch)
cd app && flutter build apk --release
```

---

## Phase 5 — Korean Learner Mode ✅ Complete (2026-08-15)

Korean mode toggle (`[ZH] / [KR]` pill in app bar) that switches the entire app experience. Persisted to `sinosphere_lang_mode` via `shared_preferences`.

### Phase 5a — DB Pipeline ✅
- New `pipeline/generate_romaja.py` — rule-based Revised Romanization; populates `compound_words.romaja` (119,443 rows)
- New `pipeline/tag_sino_korean.py` — populates `is_sino_korean` and `batchim` (rule-based, fast)
- New `pipeline/tag_topik.py` — populates `topik_level` via HSK proxy mapping; supports `--csv` for real TOPIK word list
- All scripts default to dry-run; use `--apply` to write; `--limit N` for sample testing

### Phase 5b — Flutter infrastructure ✅
- Schema v4: 4 new columns on `compound_words` (`romaja`, `topik_level`, `is_sino_korean`, `batchim`)
- New `lib/core/services/lang_mode_provider.dart` — `LangMode` enum + `langModeProvider` (persisted to `SharedPreferences`)
- `AppShell` updated to `ConsumerStatefulWidget` with animated `[ZH/KR]` pill in `AppBar`; inits from `SharedPreferences` on first frame
- `SearchResult` extended with `hangul`, `romaja`, `topikLevel`; new `searchKorean()` and `getByHangul()` on `CompoundDao`
- `CollectionDao` gains `getTopikWordCount()` and `getTopikWords()` methods

### Phase 5c — Dict card Korean mode ✅
- `activeKrWordProvider` tracks the currently shown Korean word; selecting a search result sets it directly (no modal)
- `_KoreanWordCard` renders inline in the Dict body: large Hangul hero, romaja (indigo), tappable Hanja chips (cross-navigate to ZH), TOPIK badge, bookmark
- Search bar shows hangul+romaja in indigo; chip shows hangul+romaja after selection; badge shows T1/T2 vs HSK
- `WordEnrichmentSection` (Chinese synonyms/antonyms) suppressed in Korean mode

### Phase 5d — Reader Korean mode ✅
- `AnnotationMode.romaja` added; Korean reader shows single `[RJ On/Off]` chip (indigo) instead of PY/HV chips
- `_KrEntry` in-memory index built at `ReaderNotifier.build()` from single SQL query (~119k rows); `_segmentKorean()` does O(1) map lookups — no DB hits in inner loop (fixes annotation speed)
- `AnnotatedText` renders `token.romaja` in indigo above tokens in romaja mode
- `TokenDetailSheet` shows romaja (indigo) + tappable Hanja cross-link in Korean mode
- New `seeded_texts_kr.dart` with 3 Korean sample snippets; samples row shows correct set per mode

### Phase 5e — Decks Korean mode ✅
- `CollectionsScreen` shows TOPIK grid (6 levels, indigo) in KR mode; HSK grid hidden
- New `TopikDetailScreen`: lists words by TOPIK level with hangul+romaja primary display
- `_TopikCard` tappable → navigates to `TopikDetailScreen`
- `HskDetailScreen`, `TopicDetailScreen`, `showCollectionWordSheet` / `_CollectionWordSheet` all show hangul+romaja as primary in KR mode; `WordEnrichmentSection` suppressed for Korean words
- Topic collections subtitle swaps to `% Sino-Korean` label

### Schema versions
| Version | Migration |
|---|---|
| 1 | Initial |
| 2 | `topic_tag TEXT` on `compound_words` |
| 3 | `synonyms`, `antonyms`, `example_sentence` TEXT on `compound_words` |
| 4 | `romaja`, `topik_level`, `is_sino_korean`, `batchim` on `compound_words` |

### Pipeline workflow (full rebuild)
```bash
python3 pipeline/generate_romaja.py --apply
python3 pipeline/tag_sino_korean.py --apply
python3 pipeline/tag_topik.py --apply
cp data/db/sinosphere.db app/assets/sinosphere.db
cd app && flutter build apk --release
```

### Known limitations
- `topik_level` derived from HSK proxy (approximate). For accurate levels, obtain a TOPIK word list CSV and re-run `tag_topik.py --csv topik_words.csv --apply`
- Korean Graph mode (Hanja Family Tree) deferred to Phase 6

---

## Phase 6 — Korean Depth 🚧 Planned

### Phase 6a — Korean Dict card enrichment ✅ Complete (2026-08-15)
- New `KoreanHanjaPanel`: per-syllable Hanja Analysis — hanja glyph (tappable → ZH), hangul syllable (indigo), Han-Viet, pinyin, English, component pills (semantic/phonetic)
- New `KoreanCompoundsPanel`: related Korean compounds sharing the same hanja root — hangul primary, romaja, hanja, TOPIK badge; tap navigates card in-place
- Both panels shown only for Sino-Korean words; native Korean words (no hanja) show minimal hero card
- New `getKoreanRelated()` on `CompoundDao`; new `koreanRelatedProvider`

### Phase 6d — Korean Graph mode ✅ Complete (2026-08-15)
- Canvas-based pivot graph: amber pivot node center, indigo Korean nodes right, red Chinese nodes left
- 8 pivot chips (학/学, 수/水, 심/心 etc.) for quick switching; Focus Lens slider fades ZH/KR nodes
- Tap KR node → inspector bar with "Dict" button → Korean Dict card
- Tap ZH node → inspector bar with "Graph" button → switches to ZH mode + opens that word's Chinese graph
- Data quality: only `topik_level IS NOT NULL` words shown (filters mechanical transliterations)
- KR/ZH node counts balanced (6 each max)
- Conjugation sub-view retained in Graph tab (code preserved for reuse); will be moved to Dict card in Phase 6b when KDict provides verb/part-of-speech labels

### Phase 6b — KDict native Korean vocabulary + verb conjugation in Dict card 🚧 Planned
- Import KDict (Korean government open dictionary, CC license) as `korean_words` table
- KDict includes part-of-speech tags (verb, noun, adjective etc.) — use to label words in DB
- `topik_level` from KDict metadata (replaces HSK proxy for native words)
- `searchKorean()` UNIONs `compound_words` (Sino-Korean) and `korean_words` (native)
- **Verb Conjugation section** added to Korean Dict card when `word.partOfSpeech == 'verb'`
  - Reuses `ConjugationView` logic from `lib/features/graph/widgets/conjugation_view.dart`
  - Shows stem + 3 formality levels × 3 tenses inline in the card

### Phase 6c — TOPIK level accuracy
- Source real TOPIK word list CSV (NIIED / community datasets)
- Run `tag_topik.py --csv topik_words.csv --apply` to replace HSK-proxy levels
- Also tag `korean_words` table with TOPIK levels from KDict metadata

### Phase 6d — Korean Graph mode
The Graph tab has a Korean content section in the HTML prototype. Implement in Flutter:
- Hanja Family Tree: pivot node (學/학) at center, Korean compounds right (indigo), Chinese cognates left (faded red), grammar chain bottom (emerald)
- Pivot selector chip row; Focus Lens slider (ZH ↔ KR); TOPIK filter pills (All / T1-2 / T3+)
- Conjugation sub-view: promote existing conjugation tree alongside Hanja Roots

---

## Phase 7 — Polish & Bug Fixes ✅ Complete (2026-08-17)

- [x] Synonym/antonym chips tappable — open full word sheet with tappable chars + bookmark
- [x] HSK deck word counts loaded from DB at runtime (`hskWordCountProvider`)
- [x] Korean reader segmentation improved — single-syllable tokens now matched (len ≥ 1)
- [x] App icon — `flutter_launcher_icons`, icon.png in assets
- [x] Splash screen — `flutter_native_splash`, dark `#0D1117` bg
- [x] Light mode default fixed (`ThemeModeNotifier.cached = ThemeMode.light`)
- [x] TOPIK collections loading fixed (UNION ALL subquery for SQLite ORDER BY)
- [x] KR word sheet: Hanja chips show Chinese chars, tap switches to ZH mode
- [x] "View in ZH Graph" button for Sino-Korean words in collections
- [x] Radical pill resets on graph navigation
- [x] ZH HSK/Topic collections no longer show KR layout
- [x] Settings screen: back button added (iOS compatible)
- [x] Reader: max-width constraint for iPad (720px centered)
- [ ] Graph "My Words" filter layer — deferred
- [ ] AI grammar notes in Reader — deferred
- [ ] Finish etymology generation: HSK 7-9 at 82% — deferred
- [ ] Performance audit — deferred

---

## Phase 8 — Distribution 🚧 In Progress

### Phase 8a — Android / Play Store ✅ Ready to submit

**One-time setup (already done):**
- Release signing config wired via `key.properties` (gitignored)
- Keystore: `~/sinosphere-release.jks` — **back this up safely, you cannot update the app without it**
- Password stored in `app/android/key.properties` (gitignored)
- AAB size: **114.5 MB** (under 150 MB Play Store limit — no Play Asset Delivery needed)
- Privacy policy: `docs/privacy.html` → enable GitHub Pages in repo settings → source: main branch `/docs`
  URL: `https://utn100.github.io/sinosphere/privacy.html`

**Build signed AAB:**
```bash
cd app && flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab (114.5 MB)
```

**Rebuild APK (for direct device install):**
```bash
cd app && flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Play Console submission steps:**
1. Go to play.google.com/console → Create app
2. App name: **Sinosphere** · Language: English · Free · Accept policies
3. Left sidebar → Testing → Internal testing → Create new release
4. Upload `app-release.aab` → Add release notes → Save
5. Left sidebar → Store presence → Main store listing
   - Short description (80 chars): "Learn Chinese & Korean vocabulary with Hán-Việt mnemonics"
   - Full description: describe the app features
   - Add at least 2 phone screenshots (1080×1920 or 16:9)
6. Left sidebar → Policy → App content → Content rating → Start questionnaire → Education
7. Left sidebar → Policy → App content → Privacy policy → enter `https://utn100.github.io/sinosphere/privacy.html`
8. Left sidebar → Testing → Internal testing → publish → share test link with your device
9. When ready for public: Promote release → Production

### Phase 8b — iOS / Device Testing 🚧 In Progress

**Prerequisites completed (in code):**
- `Info.plist`: `CFBundleDisplayName = Sinosphere`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` added
- `flutter_launcher_icons` + `flutter_native_splash`: `ios: true` enabled, assets generated
- `Podfile`: `platform :ios, '15.5'` set, post_install hook enforces deployment target

**Steps to build on device (manual — requires Xcode):**

1. **Run pod install** (once, or after `flutter pub get`):
```bash
cd app/ios && pod install
```

2. **Open Xcode workspace** (must use `.xcworkspace`, not `.xcodeproj`):
```bash
open app/ios/Runner.xcworkspace
```

3. **Set deployment target to 15.5** (required by MLKit):
   - Click blue **Runner** icon (top of left panel)
   - TARGETS → Runner → Build Settings → search "deployment"
   - Set `iOS Deployment Target` = **15.5**

4. **Set signing team** (free Apple ID works for device testing):
   - TARGETS → Runner → Signing & Capabilities
   - Team → add Apple ID if needed → select it
   - Xcode auto-registers the device + creates provisioning profile

5. **Connect iPhone via USB** → select it as target → hit ▶ Run

Or from terminal (device must be connected and trusted):
```bash
cd app && flutter run
```

**App Store submission** (requires paid Apple Developer account, $99/yr):
- Archive in Xcode → Distribute App → App Store Connect
- Add screenshots (6.5" iPhone required), description, keywords

---

## Phase 9 — Handwriting Practice ✅ Complete (2026-08-18)

`lib/features/practice/` — canvas-based character writing practice.

### Features
- **PracticeScreen**: single-character canvas from Dict card (pencil icon on CharacterHero)
  - Guide character shown faintly (opacity 0.07, scales by char count)
  - Quadratic bezier stroke smoothing
  - Stroke width slider, clear button, attempt counter
  - Theme-aware (light/dark mode)

- **DailyPracticeScreen**: 10-word session from bookmarks/memorized words
  - English def + pinyin prompt → user writes → tap Reveal
  - **Try again** → clears canvas, queues word for retry at end
  - **Next →** → skips word
  - **Got it ✓** → marks correct, advances
  - After all words: retry round surfaces "Try again" words (purple progress bar)
  - Session summary with score and % correct
  - Fallback to random HSK 1-3 if fewer than 10 bookmarks

- Entry points: pencil button on Dict card + "Daily Practice" banner in Decks tab
- Works with finger, stylus, Apple Pencil on all platforms

### New files
```
app/lib/features/practice/
├── practice_screen.dart        ← single-char canvas
├── daily_practice_screen.dart  ← 10-word session
└── stroke_painter.dart         ← CustomPainter with bezier smoothing
```

---

---

## Phase 10 — Polish & Engagement ✅ Complete (2026-08-18)

### Deck progress bars
- HSK and TOPIK deck cards show memorization % and a colored progress bar inline
- New `getMemorizedCountByHsk()` and `getMemorizedCountByTopik()` DAO methods
- Progress persists in `user_collection_words` (existing `memorized` collection)

### Search history
- Search bar shows last 10 queries as chips when focused and empty (no query typed)
- Persisted via `shared_preferences`; chips are tappable to re-run the search

### Daily word notification
- `lib/core/services/notification_service.dart` — `flutter_local_notifications` + `timezone`
- Notification scheduled daily at user-configured hour (default 15:00 local)
- Tap opens that word's Dict card, aligned to current language mode (ZH or KR)
- Structured payload: `zh|<simplified>`, `krs|<id>` (Sino-Korean), `krn|<id>` (native Korean)
- Android 13+ POST_NOTIFICATIONS runtime permission requested on first install
- Notification settings in Settings screen: enable/disable toggle, hour picker, "notify on open" toggle
- `notifDebugToUi` flag for diagnosing release-only notification failures without adb
- Rotating tagline titles (5 strings, chosen deterministically by day-of-year)

### Mascot, icon, animated splash, wordmark
- New app icon (`ic_launcher`, `ic_notification` monochrome silhouette for status bar)
- `lib/features/splash/splash_animation_screen.dart` — animated splash with mascot and wordmark
- Native splash (`splashscreen.png`) used as fallback; Flutter animated splash removed when unnecessary

### Bug fixes in this phase
| Bug | Fix |
|---|---|
| Notifications showed wrong word on black screen | `requestNotificationsPermission` moved out of `initNotifications` |
| App startup hang | `initNotifications` moved after `runApp`; `600-location loop` removed |
| Splash black screen | `runApp` immediately with loading screen while DB copies in Isolate |
| Notification permission dialog never appeared | Isolated permission request in its own guarded block before scheduling logic |
| Daily word tap opened wrong language mode | Payload structured as `zh|`, `krs|`, `krn|` prefix; Dict screen routes by prefix |
| Memorized folder staleness | `invalidate(collectionItemsProvider)` on every toggle/reset |
| TOPIK/HSK memorized state bleeding into each other | `memorized_zh` and `memorized_kr` kept separate in logic |
| Progress bars and KR daily practice issues | Multiple targeted fixes across `collections_screen.dart` and `daily_practice_screen.dart` |

---

## Phase 11 — Notification Reliability ✅ Complete (2026-08-20)

Fixed the daily-word notification not firing on Android and made scheduling timezone-correct.

### Timezone fix
- Added `flutter_timezone: 4.1.0` — resolves the device's real IANA zone (single platform-channel call, **not** the old 600-entry loop that caused the startup freeze). Falls back to UTC on failure.
- `initNotifications()` sets `tz.local` to the real zone; `_nextInstanceOf(hour, minute)` now does plain local-time math (no manual UTC-offset juggling).
- **Alias mapping** (`_canonicalZone`): some OEMs report deprecated IANA aliases the tz DB no longer holds. Vietnam devices report `Asia/Saigon` but the DB only has `Asia/Ho_Chi_Minh` — the lookup threw and silently fell back to UTC (shifting a 10am alarm to 5pm local). Maps Saigon→Ho_Chi_Minh plus ~11 other common aliases (Calcutta→Kolkata, Rangoon→Yangon, etc.).

### Exact alarms
- `AndroidManifest.xml`: added `USE_EXACT_ALARM` + `SCHEDULE_EXACT_ALARM`
- `zonedSchedule` now uses `AndroidScheduleMode.exactAllowWhileIdle` (fires precisely even in Doze; was `inexactAllowWhileIdle` which the OS batched by minutes-to-hours)
- `scheduleWordOfDay` checks `canScheduleExactNotifications()` and calls `requestExactAlarmsPermission()` if not granted

### Custom notification time
- Settings now uses the native `showTimePicker` (any hour+minute) instead of a fixed 8-option radio list
- New `kNotifMinute` pref; minute threaded through the whole schedule path
- **Rescheduling on save**: `_saveNotifPrefs()` now calls `scheduleWordOfDay(container, showNow: false)` — previously changing the time only took effect on next cold start. `showNow` flag suppresses the on-open notification when merely re-saving settings.

### Debugging notifications (how to re-enable)
Two flags are OFF by default. To debug notification delivery from an **installed release APK** (where `print()` is stripped and there's no adb):
1. `notifDebugToUi = true` in `app/lib/core/services/notification_service.dart` — surfaces every notification step as an on-screen SnackBar.
2. `_showNotifDiagnostics = true` in `app/lib/features/settings/settings_screen.dart` — reveals three buttons under Settings → Notifications:
   - **Diagnostics** — dialog showing `notifsEnabled`, `canScheduleExact`, resolved `zone`, and next fire time
   - **Send test now** — fires immediately (tests delivery pipeline)
   - **Test in 1 minute** — schedules an exact-alarm test (tests scheduled delivery without waiting until tomorrow)

Rebuild the APK after flipping. Remember to set both back to `false` before release.

### OEM caveat
On aggressive OEMs (Xiaomi/MIUI), the user must also set the app's battery saver to "No restrictions" for scheduled alarms to survive Doze.

---

## Remaining Work

### Near-term
- [ ] Play Store submission (Phase 8a) — AAB ready, needs Play Console setup + screenshots
- [ ] iOS App Store — needs paid Apple Developer account ($99/yr)
- [ ] Finish etymology generation: HSK 7-9 at 82% → target 95%+

### Deferred features
- [ ] Stroke order animation (Phase 9b) — needs Make Me a Hanzi stroke path data
- [ ] Spaced repetition (SRS) — replace simple check-off with Anki-style scheduling
- [ ] Graph "My Words" filter layer
- [ ] AI grammar notes in Reader
- [ ] Play Asset Delivery (only needed if AAB exceeds 150 MB — currently 114.5 MB so not needed)
- [ ] iPad split view (Dict + Graph side by side)
