import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database.dart';
import '../../core/services/database_provider.dart';
import '../../core/services/lang_mode_provider.dart';
import '../search/search_bar.dart';
import '../collections/collections_screen.dart' show bookmarkedSymbolsProvider, bookmarkedItemsProvider;
import '../shell/app_shell.dart' show tabIndexProvider;
import '../graph/graph_provider.dart' show graphProvider, koreanGraphSearchProvider;
import '../practice/practice_screen.dart';
import 'dict_card_provider.dart';
import 'widgets/character_hero.dart';
import 'widgets/component_tree.dart';
import 'widgets/etymology_card.dart';
import 'widgets/compound_list.dart';
import 'widgets/word_enrichment.dart';
import 'widgets/bookmark_button.dart';
import 'widgets/korean_hanja_panel.dart';
import 'widgets/korean_compounds_panel.dart';

class DictCardScreen extends ConsumerWidget {
  const DictCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c          = context.colors;
    final symbol     = ref.watch(activeSymbolProvider);
    final detail     = ref.watch(characterDetailProvider(symbol));
    final langMode   = ref.watch(langModeProvider);
    final isKorean   = langMode == LangMode.korean;
    final krWord     = ref.watch(activeKrWordProvider);
    final prevSymbol = ref.watch(previousSymbolProvider);

    // Handle notification tap. Payload is 'kind|value' (see notification_service):
    //   zh|<simplified>  -> ZH mode; single char -> activeSymbol, else word sheet
    //   krs|<id>         -> KR mode; Sino-Korean word from compound_words
    //   krn|<id>         -> KR mode; native word from korean_words
    ref.listen<String?>(pendingNotifWordProvider, (_, raw) async {
      if (raw == null || raw.isEmpty) return;
      ref.read(pendingNotifWordProvider.notifier).clear();
      final sep   = raw.indexOf('|');
      final kind  = sep >= 0 ? raw.substring(0, sep) : 'zh';
      final value = sep >= 0 ? raw.substring(sep + 1) : raw;
      if (value.isEmpty) return;
      final db = ref.read(databaseProvider);

      switch (kind) {
        case 'krs': // Sino-Korean compound
          final w = await db.compoundDao.getById(value);
          if (w == null) return;
          ref.read(langModeProvider.notifier).set(LangMode.korean);
          ref.read(activeKrWordProvider.notifier).set(_krResultFromCompound(w));
          return;
        case 'krn': // native Korean word
          final w = await db.compoundDao.getKoreanWordById(value);
          if (w == null) return;
          ref.read(langModeProvider.notifier).set(LangMode.korean);
          ref.read(activeKrWordProvider.notifier).set(_krResultFromKorean(w));
          return;
        default: // 'zh' (or legacy plain payload)
          ref.read(langModeProvider.notifier).set(LangMode.chinese);
          if (value.length == 1) {
            ref.read(activeSymbolProvider.notifier).set(value);
            return;
          }
          final word = await db.compoundDao.getBySimplified(value);
          if (word == null || !context.mounted) return;
          _showZhWordSheet(context, ref, word);
          return;
      }
    });

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SinosphereSearchBar(
              placeholder: isKorean
                  ? 'Search: 학교 / hak-gyo / school...'
                  : 'Search: 晨 / chén / morning / THẦN...',
              searchOverride: isKorean
                  ? (q) => ref.read(databaseProvider).compoundDao.searchKorean(q)
                  : null,
              onResultSelected: (result) {
                // Clear back navigation when doing a new search
                ref.read(previousSymbolProvider.notifier).clear();
                if (!isKorean && result.simplified.length == 1) {
                  ref.read(activeSymbolProvider.notifier).set(result.simplified);
                } else if (isKorean) {
                  ref.read(activeKrWordProvider.notifier).set(result);
                } else {
                  _showSearchResultSheet(context, ref, result);
                }
              },
            ),
          ),
          // Back navigation chip — ZH mode, when drilled into a component
          if (!isKorean && prevSymbol != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: GestureDetector(
                onTap: () {
                  ref.read(activeSymbolProvider.notifier).set(prevSymbol);
                  ref.read(previousSymbolProvider.notifier).clear();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.hanviet.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.hanviet.withAlpha(60)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.arrow_back_ios, size: 12, color: AppTheme.hanviet),
                    const SizedBox(width: 4),
                    Text('Back to $prevSymbol',
                        style: const TextStyle(color: AppTheme.hanviet,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: isKorean
                ? (krWord == null
                    ? const _KoreanEmptyState()
                    : _KoreanWordCard(
                        result: krWord,
                        onHanjaTap: (ch) {
                          ref.read(langModeProvider.notifier).set(LangMode.chinese);
                          ref.read(activeSymbolProvider.notifier).set(ch);
                        },
                      ))
                : detail.when(
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (e, _) => Center(
                        child: Text('Error loading character',
                            style: TextStyle(color: c.textMuted))),
                    data: (d) => d == null
                        ? _EmptyState(symbol: symbol)
                        : _CharacterCardBody(detail: d),
                  ),
          ),
        ]),
      ),
    );
  }

  void _showSearchResultSheet(BuildContext context, WidgetRef ref, SearchResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => _SearchResultSheet(
          result: result,
          scrollController: controller,
          onCharTap: (ch) {
            Navigator.pop(ctx);
            ref.read(activeSymbolProvider.notifier).set(ch);
          },
        ),
      ),
    );
  }

  // ZH compound-word bottom sheet opened from a notification tap. Tapping a
  // character switches to ZH mode (fixes the case where a tap left the card on
  // the KR branch and showed nothing until a manual toggle).
  void _showZhWordSheet(BuildContext context, WidgetRef ref, CompoundWord word) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.9,
        expand: false,
        builder: (_, ctrl) => _WordBottomSheet(
          word: word,
          scrollController: ctrl,
          onCharTap: (ch) {
            Navigator.pop(ctx);
            ref.read(langModeProvider.notifier).set(LangMode.chinese);
            ref.read(activeSymbolProvider.notifier).set(ch);
          },
        ),
      ),
    );
  }

  // Map a Sino-Korean CompoundWord to the SearchResult the KR card renders.
  SearchResult _krResultFromCompound(CompoundWord w) => SearchResult(
        id: w.id,
        simplified: w.simplified,
        pinyin: w.pinyin,
        hanViet: w.hanViet,
        englishDef: w.englishDef,
        hskLevel: w.hskLevel,
        frequencyRank: w.frequencyRank,
        hangul: w.hangul,
        romaja: null,
        pos: w.pos,
        isNativeKorean: false,
      );

  // Map a native KoreanWord to the SearchResult the KR card renders.
  SearchResult _krResultFromKorean(KoreanWord w) => SearchResult(
        id: w.id,
        simplified: w.hangul,
        pinyin: '',
        hanViet: '',
        englishDef: w.englishDef,
        frequencyRank: w.frequencyRank,
        hangul: w.hangul,
        romaja: w.romaja,
        topikLevel: w.topikLevel,
        pos: w.pos,
        isNativeKorean: true,
        krSynonyms: w.synonyms,
        krAntonyms: w.antonyms,
        krExample: w.exampleSentence,
      );
}

// ── Search result word sheet ──────────────────────────────────────────────────
class _SearchResultSheet extends StatelessWidget {
  final SearchResult result;
  final ScrollController scrollController;
  final void Function(String ch) onCharTap;

  const _SearchResultSheet({
    required this.result,
    required this.scrollController,
    required this.onCharTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final chars = result.simplified.split('');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Handle
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),

          // Tappable character row — long-press to copy the word
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: chars.map((ch) => GestureDetector(
              onTap: () => onCharTap(ch),
              onLongPress: () => copyToClipboard(context, result.simplified),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.transparent,
                ),
                child: Text(ch,
                    style: TextStyle(
                        color: c.text, fontSize: 48,
                        fontWeight: FontWeight.w700, height: 1.1)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),

          // HV + pinyin row
          Row(crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
            Text(result.hanViet,
                style: const TextStyle(color: AppTheme.hanviet, fontSize: 20,
                    fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(width: 12),
            Text(result.pinyin,
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 14)),
          ]),
          const SizedBox(height: 8),

          // Definition
          Text(result.englishDef,
              style: TextStyle(color: c.text, fontSize: 14, height: 1.5)),

          // HSK badge
          if (result.hskLevel != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.hanviet.withAlpha(38),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('HSK ${result.hskLevel}',
                    style: const TextStyle(color: AppTheme.hanviet,
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],

          // Bookmark + Synonyms / antonyms / examples
          if (result.id.isNotEmpty) ...[
            const SizedBox(height: 10),
            BookmarkButton(wordId: result.id),
          ],
          WordEnrichmentSection(
            wordId:     result.id,
            simplified: result.simplified,
            pinyin:     result.pinyin,
            englishDef: result.englishDef,
          ),

          const SizedBox(height: 16),

          // Hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.surf,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Row(children: [
              Icon(Icons.touch_app_outlined, size: 14, color: c.textMuted),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Tap any character above to open its dictionary card',
                style: TextStyle(color: c.textMuted, fontSize: 11),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Korean word card — persistent inline body ─────────────────────────────────
class _KoreanWordCard extends ConsumerWidget {
  final SearchResult result;
  final void Function(String ch) onHanjaTap;

  const _KoreanWordCard({required this.result, required this.onHanjaTap});

  static const _krColor    = Color(0xFF818CF8);
  static const _hanjaColor = AppTheme.hanviet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c      = context.colors;
    final hangul = result.hangul ?? result.simplified;
    final romaja = result.romaja ?? '';
    final hanja  = result.simplified;
    final topik  = result.topikLevel;
    final pos    = result.pos;
    // A word has Hanja if the simplified Chinese form differs from the hangul
    final hasSinoKorean = hanja != hangul && hanja.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Hero card
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.cardBg, c.bg],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _krColor.withAlpha(60), width: 0.5),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Large hangul hero
            Text(hangul,
                style: TextStyle(color: c.text, fontSize: 60,
                    fontWeight: FontWeight.w700, height: 1.0)),
            const SizedBox(height: 6),
            if (romaja.isNotEmpty)
              Text(romaja,
                  style: const TextStyle(color: _krColor, fontSize: 20,
                      fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            // Hanja root row — only for Sino-Korean words
            if (hasSinoKorean) ...[
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text('Hanja  ',
                    style: TextStyle(color: c.textMuted, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                ...hanja.split('').map((ch) => GestureDetector(
                  onTap: () => onHanjaTap(ch),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _hanjaColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _hanjaColor.withAlpha(80)),
                    ),
                    child: Text(ch, style: const TextStyle(
                        color: _hanjaColor, fontSize: 26, fontWeight: FontWeight.w700)),
                  ),
                )),
              ]),
              const SizedBox(height: 12),
            ],
            Text(result.englishDef,
                style: TextStyle(color: c.text, fontSize: 15, height: 1.5)),
            if (topik != null || pos != null || result.id.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                if (topik != null)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: _krColor.withAlpha(38),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('TOPIK $topik',
                        style: const TextStyle(color: _krColor,
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                if (pos != null)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(38),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(_capitalise(pos),
                        style: const TextStyle(color: Color(0xFF10B981),
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                const Spacer(),
                if (result.id.isNotEmpty)
                  BookmarkButton(wordId: result.id, compact: true),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PracticeScreen(
                      symbol:     hangul,
                      pinyin:     romaja,
                      hanViet:    result.hanViet,
                      englishDef: result.englishDef,
                    ),
                  )),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: _krColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.edit_outlined, color: _krColor, size: 20),
                  ),
                ),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 12),

        // Hanja Analysis — Sino-Korean only
        if (hasSinoKorean) ...[
          KoreanHanjaPanel(
            hanja: hanja,
            hangul: hangul,
            onHanjaTap: onHanjaTap,
          ),
          const SizedBox(height: 12),
        ],

        // Korean Compounds — Sino-Korean only (native words have no related compounds)
        if (hasSinoKorean && result.id.isNotEmpty) ...[
          KoreanCompoundsPanel(
            hanja: hanja,
            excludeId: result.id,
            onWordTap: (r) => ref.read(activeKrWordProvider.notifier).set(r),
          ),
          const SizedBox(height: 12),
        ],

        // Korean graph teaser — Sino-Korean only
        if (hasSinoKorean) ...[
          _KoreanGraphTeaser(
            hangul: hangul,
            hanja: hanja,
            onTap: () {
              ref.read(koreanGraphSearchProvider.notifier).set(
                  (simplified: hanja, hangul: hangul));
              ref.read(tabIndexProvider.notifier).set(1);
            },
          ),
          const SizedBox(height: 12),
        ],

        // Native Korean enrichment (synonyms / antonyms / example from korean_words)
        if (result.isNativeKorean && result.id.isNotEmpty) ...[
          _KoreanNativeEnrichment(wordId: result.id),
          const SizedBox(height: 12),
        ],

        // Sino-Korean enrichment (synonyms / antonyms / example from KDict via compound_words)
        if (!result.isNativeKorean && hasSinoKorean && result.id.isNotEmpty) ...[
          _KoreanSinoEnrichment(wordId: result.id),
          const SizedBox(height: 12),
        ],

        // Cross-link hint — Sino-Korean only
        if (hasSinoKorean)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _krColor.withAlpha(15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _krColor.withAlpha(40), width: 0.5),
            ),
            child: Row(children: [
              const Icon(Icons.open_in_new, size: 14, color: _krColor),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Tap a Hanja character above to explore its Chinese etymology',
                style: TextStyle(color: c.textMuted, fontSize: 11),
              )),
            ]),
          ),
      ],
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Korean graph teaser ───────────────────────────────────────────────────────
class _KoreanGraphTeaser extends StatelessWidget {
  final String hangul;
  final String hanja;
  final VoidCallback onTap;
  const _KoreanGraphTeaser({required this.hangul, required this.hanja, required this.onTap});

  static const _krColor = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _krColor.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _krColor.withAlpha(51), width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: _krColor.withAlpha(38),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.hub_outlined, color: _krColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Explore Hanja Graph',
                style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w700)),
            Text('Pivot network — $hangul · $hanja',
                style: TextStyle(color: c.textMuted, fontSize: 11)),
          ])),
          Icon(Icons.chevron_right, color: c.textMuted, size: 20),
        ]),
      ),
    );
  }
}

// ── Sino-Korean enrichment (from KDict via compound_words.kr_* columns) ──────
class _KoreanSinoEnrichment extends ConsumerWidget {
  final String wordId;
  const _KoreanSinoEnrichment({required this.wordId});

  static const _krColor = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c    = context.colors;
    final word = ref.watch(krEnrichmentProvider(wordId));

    return word.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, _) => const SizedBox.shrink(),
      data: (w) {
        if (w == null) return const SizedBox.shrink();
        final hasSyn = w.krSynonyms != null && w.krSynonyms!.isNotEmpty;
        final hasAnt = w.krAntonyms != null && w.krAntonyms!.isNotEmpty;
        final hasEx  = w.krExample  != null && w.krExample!.isNotEmpty;
        if (!hasSyn && !hasAnt && !hasEx) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('WORD RELATIONS',
              style: TextStyle(color: c.textMuted, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _krColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('KDict',
                style: TextStyle(color: _krColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
        if (hasSyn) ...[
          const SizedBox(height: 10),
          Text('Synonyms', style: TextStyle(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4,
            children: w.krSynonyms!.split(', ').map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _krColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _krColor.withAlpha(60))),
              child: Text(s.trim(), style: const TextStyle(color: _krColor,
                  fontSize: 12, fontWeight: FontWeight.w600)),
            )).toList()),
        ],
        if (hasAnt) ...[
          const SizedBox(height: 10),
          Text('Antonyms', style: TextStyle(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4,
            children: w.krAntonyms!.split(', ').map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFEF4444).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444).withAlpha(60))),
              child: Text(s.trim(), style: const TextStyle(color: Color(0xFFEF4444),
                  fontSize: 12, fontWeight: FontWeight.w600)),
            )).toList()),
        ],
        if (hasEx) ...[
          const SizedBox(height: 10),
          Text('Example', style: TextStyle(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...w.krExample!.split('\n').map((line) =>
            Padding(padding: const EdgeInsets.only(bottom: 2),
              child: Text(line, style: TextStyle(color: c.text, fontSize: 13, height: 1.5)))),
        ],
      ]),
        );
      },
    );
  }
}

// ── Native Korean word enrichment (synonyms/antonyms/example from KDict) ─────
class _KoreanNativeEnrichment extends ConsumerWidget {
  final String wordId;
  const _KoreanNativeEnrichment({required this.wordId});

  static const _krColor = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c    = context.colors;
    final word = ref.watch(koreanWordProvider(wordId));

    return word.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, _) => const SizedBox.shrink(),
      data: (w) {
        if (w == null) return const SizedBox.shrink();
        final hasSyn = w.synonyms != null && w.synonyms!.isNotEmpty;
        final hasAnt = w.antonyms != null && w.antonyms!.isNotEmpty;
        final hasEx  = w.exampleSentence != null && w.exampleSentence!.isNotEmpty;
        if (!hasSyn && !hasAnt && !hasEx) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('WORD RELATIONS',
                  style: TextStyle(color: c.textMuted, fontSize: 10,
                      fontWeight: FontWeight.w700, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _krColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('KDict',
                    style: TextStyle(color: _krColor, fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            if (hasSyn) ...[
              const SizedBox(height: 10),
              Text('Synonyms', style: TextStyle(color: c.textMuted, fontSize: 11,
                  fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 4,
                children: w.synonyms!.split(', ').map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _krColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _krColor.withAlpha(60)),
                  ),
                  child: Text(s.trim(), style: const TextStyle(
                      color: _krColor, fontSize: 12, fontWeight: FontWeight.w600)),
                )).toList()),
            ],
            if (hasAnt) ...[
              const SizedBox(height: 10),
              Text('Antonyms', style: TextStyle(color: c.textMuted, fontSize: 11,
                  fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 4,
                children: w.antonyms!.split(', ').map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444).withAlpha(60)),
                  ),
                  child: Text(s.trim(), style: const TextStyle(
                      color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600)),
                )).toList()),
            ],
            if (hasEx) ...[
              const SizedBox(height: 10),
              Text('Example', style: TextStyle(color: c.textMuted, fontSize: 11,
                  fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(w.exampleSentence!,
                  style: TextStyle(color: c.text, fontSize: 13, height: 1.5)),
            ],
          ]),
        );
      },
    );
  }
}

// ── Korean empty state (shown in dict body when KR mode, no search yet) ───────
class _KoreanEmptyState extends StatelessWidget {
  const _KoreanEmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('한', style: TextStyle(color: Color(0xFF818CF8), fontSize: 64,
          fontWeight: FontWeight.w300)),
      const SizedBox(height: 8),
      Text('Search Korean words above', style: TextStyle(color: c.textMuted, fontSize: 14)),
      const SizedBox(height: 4),
      Text('e.g. 학교 · hak-gyo · school', style: TextStyle(color: c.textMuted, fontSize: 12)),
    ]));
  }
}

class _CharacterCardBody extends ConsumerWidget {
  final CharacterDetail detail;
  const _CharacterCardBody({required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final char = detail.character;
    final db   = ref.read(databaseProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Hero card
        Consumer(builder: (ctx, ref, _) {
          final bookmarkAsync = ref.watch(bookmarkProvider(char.id));
          final isBookmarked  = bookmarkAsync.when(
              data: (v) => v, loading: () => false, error: (_, _) => false);
          return CharacterHero(
            character: char,
            hskLevel: detail.hskLevel,
            isBookmarked: isBookmarked,
            onBookmarkTap: () async {
              await db.collectionDao.toggleBookmark(char.id);
              ref.invalidate(bookmarkProvider(char.id));
              ref.invalidate(bookmarkedSymbolsProvider);
              ref.invalidate(bookmarkedItemsProvider);
            },
            onPracticeTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PracticeScreen(
                symbol:     char.symbol,
                pinyin:     char.pinyin,
                hanViet:    char.hanViet,
                englishDef: char.englishDef,
              ),
            )),
          );
        }),
        const SizedBox(height: 12),

        if (detail.components.isNotEmpty || char.decomposition != null)
          ComponentTree(
            components: detail.components,
            decomposition: char.decomposition ?? '',
            onComponentTap: (compSymbol) {
              // Save current symbol for back navigation, then navigate to component
              ref.read(previousSymbolProvider.notifier).set(char.symbol);
              ref.read(activeSymbolProvider.notifier).set(compSymbol);
            },
          ),
        const SizedBox(height: 12),

        EtymologyCard(character: char, components: detail.components),
        const SizedBox(height: 12),

        if (detail.compounds.isNotEmpty)
          CompoundList(
            compounds: detail.compounds,
            onTap: (word) => _showWordSheet(context, ref, word),
          ),
        const SizedBox(height: 12),

        _GraphTeaser(symbol: char.symbol, hanViet: char.hanViet),
      ],
    );
  }

  void _showWordSheet(BuildContext context, WidgetRef ref, CompoundWord word) {
    // Single-character compound → navigate directly to its Dict Card
    if (word.simplified.length == 1) {
      ref.read(activeSymbolProvider.notifier).set(word.simplified);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => _WordBottomSheet(
          word: word,
          scrollController: controller,
          onCharTap: (ch) {
            Navigator.pop(ctx);
            ref.read(activeSymbolProvider.notifier).set(ch);
          },
        ),
      ),
    );
  }
}

class _WordBottomSheet extends StatelessWidget {
  final CompoundWord word;
  final ScrollController scrollController;
  final void Function(String ch) onCharTap;
  const _WordBottomSheet({required this.word, required this.scrollController, required this.onCharTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),

          // Tappable character row — long-press any char to copy the full word
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: word.simplified.split('').map((ch) => GestureDetector(
              onTap: () => onCharTap(ch),
              onLongPress: () => copyToClipboard(context, word.simplified),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8), color: Colors.transparent),
                child: Text(ch, style: TextStyle(color: c.text, fontSize: 48,
                    fontWeight: FontWeight.w700, height: 1.1)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),

          // HV + pinyin
          Row(crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
            Flexible(child: Text(word.hanViet,
                style: const TextStyle(color: AppTheme.hanviet, fontSize: 20,
                    fontWeight: FontWeight.w900, letterSpacing: 1),
                softWrap: true)),
            const SizedBox(width: 12),
            Flexible(child: Text(word.pinyin,
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 14))),
          ]),
          const SizedBox(height: 8),

          Text(word.englishDef, style: TextStyle(color: c.text, fontSize: 14, height: 1.5)),

          if (word.vietnameseNote != null) ...[
            const SizedBox(height: 4),
            Text('VN: ${word.vietnameseNote}',
                style: TextStyle(color: c.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
          ],

          if (word.hskLevel != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.hanviet.withAlpha(38),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('HSK ${word.hskLevel}',
                    style: const TextStyle(color: AppTheme.hanviet,
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],

          // Bookmark
          const SizedBox(height: 10),
          BookmarkButton(wordId: word.id),

          // Synonyms / antonyms / example sentence
          WordEnrichmentSection(
            wordId:          word.id,
            simplified:      word.simplified,
            pinyin:          word.pinyin,
            englishDef:      word.englishDef,
            initialSynonyms: word.synonyms,
            initialAntonyms: word.antonyms,
            initialExample:  word.exampleSentence,
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.surf,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Row(children: [
              Icon(Icons.touch_app_outlined, size: 14, color: c.textMuted),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Tap any character above to open its dictionary card',
                style: TextStyle(color: c.textMuted, fontSize: 11),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

class _GraphTeaser extends ConsumerWidget {
  final String symbol, hanViet;
  const _GraphTeaser({required this.symbol, required this.hanViet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return GestureDetector(
      onTap: () async {
        await ref.read(graphProvider.notifier).setFocal(symbol);
        ref.read(tabIndexProvider.notifier).set(1);
      },
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.semantic.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.semantic.withAlpha(51), width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: AppTheme.semantic.withAlpha(38),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.hub_outlined, color: AppTheme.semantic, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Explore Component Graph',
              style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w700)),
          Text('3-tier radical network — $symbol · $hanViet',
              style: TextStyle(color: c.textMuted, fontSize: 11)),
        ])),
        Icon(Icons.chevron_right, color: c.textMuted, size: 20),
      ]),
    ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String symbol;
  const _EmptyState({required this.symbol});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(symbol, style: TextStyle(color: c.textMuted, fontSize: 64, fontWeight: FontWeight.w300)),
      const SizedBox(height: 8),
      Text('Character not found', style: TextStyle(color: c.textMuted, fontSize: 14)),
    ]));
  }
}
