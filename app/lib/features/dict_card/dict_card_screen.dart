import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database.dart';
import '../../core/services/database_provider.dart';
import '../search/search_bar.dart';
import '../collections/collections_screen.dart' show bookmarkedSymbolsProvider;
import '../shell/app_shell.dart' show tabIndexProvider;
import '../graph/graph_provider.dart' show graphProvider;
import 'dict_card_provider.dart';
import 'widgets/character_hero.dart';
import 'widgets/component_tree.dart';
import 'widgets/etymology_card.dart';
import 'widgets/compound_list.dart';

class DictCardScreen extends ConsumerWidget {
  const DictCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c      = context.colors;
    final symbol = ref.watch(activeSymbolProvider);
    final detail = ref.watch(characterDetailProvider(symbol));

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SinosphereSearchBar(
              onResultSelected: (result) {
                if (result.simplified.length == 1) {
                  ref.read(activeSymbolProvider.notifier).set(result.simplified);
                } else {
                  _showSearchResultSheet(context, ref, result);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: detail.when(
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

          // Tappable character row
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: chars.map((ch) => GestureDetector(
              onTap: () => onCharTap(ch),
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
            },
          );
        }),
        const SizedBox(height: 12),

        if (detail.components.isNotEmpty || char.decomposition != null)
          ComponentTree(
            components: detail.components,
            decomposition: char.decomposition ?? '',
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

          // Tappable character row
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: word.simplified.split('').map((ch) => GestureDetector(
              onTap: () => onCharTap(ch),
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
