import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/database_provider.dart';
import '../../core/services/lang_mode_provider.dart';
import '../collections/collections_screen.dart'
    show bookmarkedItemsProvider, bookmarkedSymbolsProvider;
import 'models/token.dart';

enum AnnotationMode { hanviet, pinyin, both, none, romaja }

class ReaderState {
  final List<Token> tokens;
  final String rawText;
  final String title;
  final AnnotationMode mode;
  final bool showHarvest;
  final Set<String> starred;
  final bool isAnnotating;
  final bool isExtractingOcr;
  final String? aiTranslation;
  final bool isTranslating;

  const ReaderState({
    this.tokens = const [],
    this.rawText = '',
    this.title = '',
    this.mode = AnnotationMode.pinyin,
    this.showHarvest = false,
    this.starred = const {},
    this.isAnnotating = false,
    this.isExtractingOcr = false,
    this.aiTranslation,
    this.isTranslating = false,
  });

  ReaderState copyWith({
    List<Token>? tokens, String? rawText, String? title,
    AnnotationMode? mode, bool? showHarvest,
    Set<String>? starred, bool? isAnnotating,
    bool? isExtractingOcr,
    String? aiTranslation, bool? isTranslating,
    bool clearAiTranslation = false,
  }) => ReaderState(
    tokens: tokens ?? this.tokens,
    rawText: rawText ?? this.rawText,
    title: title ?? this.title,
    mode: mode ?? this.mode,
    showHarvest: showHarvest ?? this.showHarvest,
    starred: starred ?? this.starred,
    isAnnotating: isAnnotating ?? this.isAnnotating,
    isExtractingOcr: isExtractingOcr ?? this.isExtractingOcr,
    aiTranslation: clearAiTranslation ? null : (aiTranslation ?? this.aiTranslation),
    isTranslating: isTranslating ?? this.isTranslating,
  );
}

class ReaderNotifier extends Notifier<ReaderState> {
  // In-memory index for Korean segmentation: hangul → CompoundWord data
  // Loaded once at startup so _segmentKorean never hits the DB in its inner loop.
  Map<String, _KrEntry> _krIndex = {};
  bool _krIndexLoaded = false;

  @override
  ReaderState build() {
    _loadKrIndex(); // fire-and-forget — ready before user first taps annotate
    return const ReaderState();
  }

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> _loadKrIndex() async {
    if (_krIndexLoaded) return;

    // Load Sino-Korean words from compound_words
    final sinoRows = await _db.customSelect(
      'SELECT id, simplified, hangul, han_viet, english_def, romaja, is_sino_korean '
      'FROM compound_words WHERE hangul IS NOT NULL AND kr_verified = 1',
      readsFrom: {_db.compoundWords},
    ).get();

    // Load native Korean words from korean_words
    final nativeRows = await _db.customSelect(
      'SELECT id, hangul, hangul AS simplified, \'\' AS han_viet, english_def, romaja '
      'FROM korean_words WHERE hangul IS NOT NULL',
      readsFrom: {_db.koreanWords},
    ).get();

    final index = <String, _KrEntry>{
      for (final r in sinoRows)
        r.read<String>('hangul'): _KrEntry(
          id:           r.read<String>('id'),
          simplified:   r.read<String>('simplified'),
          hangul:       r.read<String>('hangul'),
          hanViet:      r.read<String>('han_viet'),
          englishDef:   r.read<String>('english_def'),
          romaja:       r.readNullable<String>('romaja'),
          isSinoKorean: (r.readNullable<int>('is_sino_korean') ?? 0) == 1,
        ),
    };
    // Add native Korean entries (don't overwrite Sino-Korean if same hangul)
    for (final r in nativeRows) {
      final h = r.read<String>('hangul');
      if (!index.containsKey(h)) {
        index[h] = _KrEntry(
          id:           r.read<String>('id'),
          simplified:   h,
          hangul:       h,
          hanViet:      '',
          englishDef:   r.read<String>('english_def'),
          romaja:       r.readNullable<String>('romaja'),
          isSinoKorean: false,
        );
      }
    }
    _krIndex = index;
    _krIndexLoaded = true;
  }

  Future<void> annotate(String text, {String? title}) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(isAnnotating: true, rawText: text);

    final tokens = await _segment(text);
    final autoTitle = title ?? _autoTitle(text);

    // Save to history
    final tokenJson = jsonEncode(tokens.map((t) => {
      'text': t.text, 'hv': t.hanViet, 'py': t.pinyin,
      'def': t.englishDef, 'cjk': t.isCjk, 'compound': t.isCompound,
      'known': t.isKnown, 'wid': t.wordId, 'cid': t.charId,
      'romaja': t.romaja, 'sino': t.isSinoKorean, 'simp': t.simplified,
    }).toList());

    await _db.readerDao.saveHistory(
      id: const Uuid().v4(), title: autoTitle,
      rawText: text, tokenJson: tokenJson,
    );
    ref.invalidate(readerHistoryProvider); // refresh history list

    state = state.copyWith(
      tokens: tokens, title: autoTitle,
      isAnnotating: false, showHarvest: false, starred: {},
    );
  }

  void setMode(AnnotationMode m) => state = state.copyWith(mode: m);

  void setExtractingOcr(bool v) => state = state.copyWith(isExtractingOcr: v);

  void toggleHarvest() => state = state.copyWith(showHarvest: !state.showHarvest);

  Future<void> translateWithAi() async {
    if (state.rawText.isEmpty || state.isTranslating) return;
    final ai       = ref.read(aiServiceProvider);
    final settings = await ref.read(llmSettingsProvider.future);
    if (!settings.isConfigured) return;

    // Check cache first
    final cacheKey = 'translate:${state.rawText.hashCode}';
    final cached   = await _db.getCachedAiResponse(cacheKey);
    if (cached != null) {
      state = state.copyWith(aiTranslation: cached);
      return;
    }

    state = state.copyWith(isTranslating: true);
    final translation = await ai.translateText(state.rawText, settings);
    if (translation != null) {
      await _db.cacheAiResponse(cacheKey, translation);
    }
    state = state.copyWith(
      aiTranslation: translation, isTranslating: false);
  }

  void toggleStar(String id) {
    final s = Set<String>.from(state.starred);
    if (s.contains(id)) { s.remove(id); } else { s.add(id); }
    state = state.copyWith(starred: s);
  }

  Future<void> addStarredToBookmarks() async {
    await _db.collectionDao.ensureBookmarksCollection();
    for (final token in state.tokens) {
      // Use same 3-part key as toggleStar/harvest_panel to match correctly
      final starKey = token.charId ?? token.wordId ?? token.text;
      if (!state.starred.contains(starKey)) continue;
      // Only save tokens with a real DB id (skip text-only fallback tokens)
      final dbId = token.charId ?? token.wordId;
      if (dbId == null) continue;
      await _db.collectionDao.addToCollection(bookmarksCollectionId, dbId);
    }
    ref.invalidate(bookmarkedItemsProvider);
    ref.invalidate(bookmarkedSymbolsProvider);
    state = state.copyWith(showHarvest: false, starred: {});
  }

  Future<void> loadFromHistory(ReadingHistoryData h) async {
    final list = jsonDecode(h.tokenJson) as List;
    final tokens = list.map((m) => Token(
      text: m['text'] as String,
      hanViet: m['hv'] as String? ?? '',
      pinyin: m['py'] as String? ?? '',
      englishDef: m['def'] as String? ?? '',
      isCjk: m['cjk'] as bool? ?? false,
      isCompound: m['compound'] as bool? ?? false,
      isKnown: m['known'] as bool? ?? false,
      wordId: m['wid'] as String?,
      charId: m['cid'] as String?,
      romaja: m['romaja'] as String?,
      isSinoKorean: m['sino'] as bool? ?? false,
      simplified: m['simp'] as String?,
    )).toList();
    state = state.copyWith(tokens: tokens, rawText: h.rawText, title: h.title,
        isAnnotating: false, showHarvest: false, starred: {});
  }

  // ── Segmentation ─────────────────────────────────────────────────────────────

  Future<List<Token>> _segment(String text) async {
    final langMode = ref.read(langModeProvider);
    return langMode == LangMode.korean
        ? await _segmentKorean(text)
        : await _segmentChinese(text);
  }

  Future<List<Token>> _segmentChinese(String text) async {
    final tokens = <Token>[];
    var i = 0;
    while (i < text.length) {
      final ch = text[i];
      if (!_isCjk(ch)) {
        var run = ch;
        var j = i + 1;
        while (j < text.length && !_isCjk(text[j])) { run += text[j]; j++; }
        tokens.add(Token(text: run, isCjk: false));
        i = j;
        continue;
      }

      CompoundWord? match;
      int matchLen = 1;
      for (int len = min(8, text.length - i); len > 1; len--) {
        final candidate = text.substring(i, i + len);
        final cw = await _db.compoundDao.getBySimplified(candidate);
        if (cw != null) { match = cw; matchLen = len; break; }
      }

      if (match != null) {
        tokens.add(Token(
          text: match.simplified, hanViet: match.hanViet,
          pinyin: match.pinyin, englishDef: match.englishDef,
          isCjk: true, isCompound: true, isKnown: true, wordId: match.id,
        ));
        i += matchLen;
      } else {
        final char = await _db.characterDao.getBySymbol(ch);
        tokens.add(Token(
          text: ch, hanViet: char?.hanViet ?? '',
          pinyin: char?.pinyin ?? '', englishDef: char?.englishDef ?? '',
          isCjk: true, isCompound: false,
          isKnown: char != null, charId: char?.id,
        ));
        i++;
      }
    }
    return tokens;
  }

  Future<List<Token>> _segmentKorean(String text) async {
    if (!_krIndexLoaded) await _loadKrIndex();

    final tokens = <Token>[];
    var i = 0;
    while (i < text.length) {
      final ch = text[i];
      if (!_isHangul(ch)) {
        var run = ch;
        var j = i + 1;
        while (j < text.length && !_isHangul(text[j])) { run += text[j]; j++; }
        tokens.add(Token(text: run, isCjk: false));
        i = j;
        continue;
      }

      // Greedy longest match — O(1) map lookups, no DB hits in inner loop
      _KrEntry? match;
      int matchLen = 1;
      for (int len = min(5, text.length - i); len >= 1; len--) {
        final entry = _krIndex[text.substring(i, i + len)];
        if (entry != null) { match = entry; matchLen = len; break; }
      }

      if (match != null) {
        tokens.add(Token(
          text:         match.hangul,
          hanViet:      match.hanViet,     // correct HV reading, not the hangul string
          pinyin:       '',
          englishDef:   match.englishDef,
          isCjk:        true, isCompound: true, isKnown: true,
          wordId:       match.id,
          romaja:       match.romaja,
          isSinoKorean: match.isSinoKorean,
          simplified:   match.simplified,
        ));
        i += matchLen;
      } else {
        tokens.add(Token(text: ch, isCjk: true, isCompound: false));
        i++;
      }
    }
    return tokens;
  }

  bool _isCjk(String ch) {
    if (ch.isEmpty) return false;
    final cp = ch.runes.first;
    return (cp >= 0x4E00 && cp <= 0x9FFF)
        || (cp >= 0x3400 && cp <= 0x4DBF)
        || (cp >= 0xF900 && cp <= 0xFAFF)
        || (cp >= 0x20000 && cp <= 0x2A6DF);
  }

  bool _isHangul(String ch) {
    if (ch.isEmpty) return false;
    final cp = ch.runes.first;
    return cp >= 0xAC00 && cp <= 0xD7A3;
  }

  String _autoTitle(String text) {
    final langMode = ref.read(langModeProvider);
    if (langMode == LangMode.korean) {
      final hangul = text.replaceAll(RegExp(r'[^가-힣]'), '');
      return hangul.length > 12 ? '${hangul.substring(0, 12)}…' : hangul;
    }
    final cjk = text.replaceAll(RegExp(r'[^一-鿿㐀-䶿]'), '');
    return cjk.length > 12 ? '${cjk.substring(0, 12)}…' : cjk;
  }
}

final readerProvider = NotifierProvider<ReaderNotifier, ReaderState>(ReaderNotifier.new);

final readerHistoryProvider = FutureProvider<List<ReadingHistoryData>>((ref) async {
  return ref.read(databaseProvider).readerDao.getHistory();
});

// Lightweight struct for the in-memory Korean index — avoids holding full CompoundWord objects
class _KrEntry {
  final String id;
  final String simplified;
  final String hangul;
  final String hanViet;
  final String englishDef;
  final String? romaja;
  final bool isSinoKorean;

  const _KrEntry({
    required this.id,
    required this.simplified,
    required this.hangul,
    required this.hanViet,
    required this.englishDef,
    this.romaja,
    this.isSinoKorean = false,
  });
}
