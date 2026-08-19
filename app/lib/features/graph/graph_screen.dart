import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/database.dart';
import '../../core/services/database_provider.dart';
import '../../core/services/lang_mode_provider.dart';
import '../../core/theme/app_theme.dart';
import '../dict_card/dict_card_provider.dart';
import '../dict_card/widgets/word_enrichment.dart';
import '../dict_card/widgets/bookmark_button.dart';
import '../shell/app_shell.dart' show tabIndexProvider;
import '../search/search_bar.dart';
import 'graph_provider.dart';
import 'graph_painter.dart';
import 'korean_graph_view.dart';
import 'models/graph_node.dart';
import 'widgets/graph_legend.dart';

class GraphScreen extends ConsumerStatefulWidget {
  const GraphScreen({super.key});

  @override
  ConsumerState<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends ConsumerState<GraphScreen> {
  String? _selectedId;
  bool    _radicalBarVisible = true;
  String  _activeRadical = '土';
  String  _activePinyin  = 'tǔ';
  final Map<String, CompoundWord> _wordCache = {};
  final _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _centerGraph();
      final symbol = ref.read(activeSymbolProvider);
      await ref.read(graphProvider.notifier).setFocal(symbol);
      // Init radical pill with the initial focal character's pinyin
      final ch = await ref.read(databaseProvider).characterDao.getBySymbol(symbol);
      if (mounted) {
        setState(() {
          _activeRadical = symbol;
          _activePinyin  = ch?.pinyin ?? '';
        });
      }
    });
  }

  void _centerGraph() {
    final size = context.size;
    if (size == null) return;
    const canvasSize = 800.0;
    final dx = (size.width  - canvasSize) / 2;
    final dy = (size.height - canvasSize) / 2;
    _transformCtrl.value = Matrix4.translationValues(dx, dy, 0);
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _onNodeTap(GraphNode node) async {
    setState(() => _selectedId = node.id);

    final notifier = ref.read(graphProvider.notifier);
    final db = ref.read(databaseProvider);

    switch (node.type) {
      case GraphNodeType.focal:
        final focalSymbol = ref.read(graphProvider).focalSymbol;
        if (focalSymbol.length == 1) {
          // Single character — open dict card
          ref.read(activeSymbolProvider.notifier).set(focalSymbol);
          ref.read(tabIndexProvider.notifier).set(0);
        } else {
          // Compound word — show bottom sheet as before
          CompoundWord? cw = _wordCache[node.id];
          if (cw == null) {
            cw = await db.compoundDao.getBySimplified(focalSymbol);
            if (cw != null) _wordCache[node.id] = cw;
          }
          if (cw != null && mounted) _showRelatedSheet(cw);
        }

      case GraphNodeType.root:
        // Root radical tap — reload (collapse expanded children)
        await notifier.setFocal(ref.read(graphProvider).focalSymbol);
        setState(() => _selectedId = null);

      case GraphNodeType.component:
        final compId = node.id.replaceFirst('comp:', '');
        // H6: look up the parent character from the node's parentId, not focalSymbol
        // parentId is 'focal:${char.id}' or 'sib:${char.id}'
        final parentNodeId = node.parentId ?? '';
        final charDbId = parentNodeId.contains(':')
            ? parentNodeId.split(':').last
            : '';
        if (charDbId.isNotEmpty) {
          await notifier.expandComponent(compId, charDbId);
        }

      case GraphNodeType.sibling:
        final charId = node.id.replaceFirst('sib:', '');
        await notifier.expandSibling(charId, node.id, node.label);

      case GraphNodeType.compound:
        CompoundWord? cw = _wordCache[node.id];
        if (cw == null) {
          cw = await db.compoundDao.getBySimplified(node.label);
          if (cw != null) _wordCache[node.id] = cw;
        }
        if (cw != null && mounted) {
          _showRelatedSheet(cw);
        }

      case GraphNodeType.showMore:
        if (node.parentId != null) {
          // Strip either 'sib:' or 'focal:' prefix to get the raw DB character id
          final charId = node.parentId!
              .replaceFirst('sib:', '')
              .replaceFirst('focal:', '');
          final parentNode = ref.read(graphProvider).nodes
              .firstWhere((n) => n.id == node.parentId, orElse: () => node);
          if (node.label == '−') {
            notifier.removeLastCompoundPage(charId, node.parentId!);
          } else {
            await notifier.loadMoreCompounds(charId, node.parentId!, parentNode.label);
          }
        }
    }
  }

  static const _graphTipKey = 'sinosphere_graph_tip_shown';

  Future<void> _onNodeLongPress(GraphNode node) async {
    if (node.type != GraphNodeType.sibling &&
        node.type != GraphNodeType.component) return;
    ref.read(activeSymbolProvider.notifier).set(node.label);
    ref.read(tabIndexProvider.notifier).set(0);
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_graphTipKey) ?? false)) {
      await prefs.setBool(_graphTipKey, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tip: long-press a character node to open its Dict card'),
          duration: Duration(seconds: 3),
        ));
      }
    }
  }

  void _showRelatedSheet(CompoundWord word) {    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.9,
        expand: false,
        builder: (_, ctrl) => _GraphWordSheet(
          word: word,
          scrollController: ctrl,
          onCharTap: (ch) {
            Navigator.pop(ctx);
            ref.read(activeSymbolProvider.notifier).set(ch);
            ref.read(tabIndexProvider.notifier).set(0);
          },
        ),
      ),
    );
  }

  GraphNode? _hitTest(Offset tapPos, List<GraphNode> nodes) {
    for (final node in nodes.reversed) {
      if ((tapPos - node.position).distance <= node.radius + 10) return node;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c        = context.colors;
    final graph    = ref.watch(graphProvider);
    final langMode = ref.watch(langModeProvider);
    final isKorean = langMode == LangMode.korean;

    // Reset radical pill whenever focal symbol changes (e.g. navigating from dict card or collections)
    ref.listen(graphProvider, (prev, next) async {
      if (next.focalSymbol.isNotEmpty && next.focalSymbol != prev?.focalSymbol) {
        final ch = await ref.read(databaseProvider).characterDao
            .getBySymbol(next.focalSymbol);
        if (mounted) setState(() {
          _activeRadical = next.focalSymbol;
          _activePinyin  = ch?.pinyin ?? '';
        });
      }
    });

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: isKorean
            ? const KoreanGraphView()
            : Column(children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SinosphereSearchBar(
              onResultSelected: (result) async {
                if (result.simplified.length == 1) {
                  ref.read(activeSymbolProvider.notifier).set(result.simplified);
                  await ref.read(graphProvider.notifier).setFocal(result.simplified);
                } else {
                  await ref.read(graphProvider.notifier).setFocalWord(
                    result.simplified,
                    result.simplified.split(''),
                  );
                }
                _centerGraph();
              },
            ),
          ),
          const SizedBox(height: 8),

          // Legend row + radical collapse pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Align(alignment: Alignment.centerLeft, child: GraphLegend()),
              const Spacer(),
              // Active-radical pill — tap to show/hide radical picker
              GestureDetector(
                onTap: () => setState(() => _radicalBarVisible = !_radicalBarVisible),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.hanviet.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.hanviet.withAlpha(80)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_activeRadical,
                        style: const TextStyle(color: AppTheme.hanviet,
                            fontSize: 13, fontWeight: FontWeight.w800)),
                    if (_activePinyin.isNotEmpty) ...[
                      const Text(' · ', style: TextStyle(color: AppTheme.hanviet, fontSize: 11)),
                      Text(_activePinyin,
                          style: const TextStyle(color: AppTheme.hanviet,
                              fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                    const SizedBox(width: 4),
                    Icon(
                      _radicalBarVisible ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.hanviet, size: 16),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),

          // Radical picker bar — collapsible
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _radicalBarVisible
                ? _RadicalBar(onTap: (radical) async {
                    ref.read(activeSymbolProvider.notifier).set(radical);
                    await ref.read(graphProvider.notifier).setFocal(radical);
                    // Look up pinyin for the pill label
                    final ch = await ref.read(databaseProvider)
                        .characterDao.getBySymbol(radical);
                    setState(() {
                      _selectedId = null;
                      _activeRadical = radical;
                      _activePinyin  = ch?.pinyin ?? '';
                    });
                    _centerGraph();
                  })
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 6),

          // Canvas
          Expanded(
            child: graph.nodes.isEmpty
                ? Center(child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.hanviet))
                : InteractiveViewer(
                    constrained: false,
                    transformationController: _transformCtrl,
                    minScale: 0.3,
                    maxScale: 3.0,
                    child: GestureDetector(
                      onTapUp: (details) {
                        final node = _hitTest(details.localPosition, graph.nodes);
                        if (node != null) _onNodeTap(node);
                      },
                      onLongPressStart: (details) {
                        final node = _hitTest(details.localPosition, graph.nodes);
                        if (node != null) _onNodeLongPress(node);
                      },
                      child: SizedBox(
                        width: 800,
                        height: 800,
                        child: CustomPaint(
                          painter: GraphPainter(graph, selectedId: _selectedId),
                          size: const Size(800, 800),
                        ),
                      ),
                    ),
                  ),
          ),

          // Hint bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Tap component → expand siblings  ·  Tap character → show words  ·  Long-press character → Dict card  ·  Tap focal → Dict card',
              style: TextStyle(color: c.textMuted, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ]),  // Column
      ),    // SafeArea
    );
  }
}

// ── Radical picker panel ──────────────────────────────────────────────────────
class _RadicalBar extends ConsumerStatefulWidget {
  final void Function(String radical) onTap;
  const _RadicalBar({required this.onTap});

  @override
  ConsumerState<_RadicalBar> createState() => _RadicalBarState();
}

class _RadicalBarState extends ConsumerState<_RadicalBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radicals = ref.watch(topRadicalsProvider);

    return radicals.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (all) {
        final shown = _expanded ? all : all.take(30).toList();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(children: [
                Text('SELECT A ROOT RADICAL (BỘ THỦ)',
                    style: TextStyle(color: c.textMuted, fontSize: 9,
                        fontWeight: FontWeight.w800, letterSpacing: 1)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.hanviet.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_expanded ? 'Collapse' : 'All ${all.length}',
                        style: const TextStyle(color: AppTheme.hanviet,
                            fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
            // Radical grid — scrollable when expanded
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: _expanded ? 220 : 120),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Wrap(
                  spacing: 6, runSpacing: 6,
                  children: shown.map((r) => _RadicalChip(
                    radical: r,
                    onTap: () => widget.onTap(r),
                  )).toList(),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _RadicalChip extends ConsumerWidget {
  final String radical;
  final VoidCallback onTap;
  const _RadicalChip({required this.radical, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    // Try to get HV from the characters table via the provider state
    final graph = ref.watch(graphProvider);   // M2: watch so highlight updates
    final isFocal = graph.focalSymbol == radical;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 52,
        decoration: BoxDecoration(
          color: isFocal
              ? AppTheme.sky.withAlpha(51)
              : AppTheme.hanviet.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFocal ? AppTheme.sky : AppTheme.hanviet.withAlpha(38),
            width: isFocal ? 1.5 : 0.5,
          ),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(radical, style: TextStyle(color: c.text, fontSize: 18,
              fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ── Graph word detail sheet ───────────────────────────────────────────────────
class _GraphWordSheet extends StatelessWidget {
  final CompoundWord word;
  final ScrollController scrollController;
  final void Function(String ch) onCharTap;

  const _GraphWordSheet({
    required this.word, required this.scrollController, required this.onCharTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Wrap(
          spacing: 4, runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: word.simplified.split('').map((ch) => GestureDetector(
            onTap: () => onCharTap(ch),
            onLongPress: () => copyToClipboard(context, word.simplified),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8), color: Colors.transparent),
              child: Text(ch, style: TextStyle(
                  color: c.text, fontSize: 48, fontWeight: FontWeight.w700, height: 1.1)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic, children: [
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
        if (word.hskLevel != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.hanviet.withAlpha(38),
                borderRadius: BorderRadius.circular(8)),
            child: Text('HSK ${word.hskLevel == 7 ? '7-9' : word.hskLevel}',
                style: const TextStyle(color: AppTheme.hanviet, fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ],
        const SizedBox(height: 10),
        BookmarkButton(wordId: word.id),
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
          decoration: BoxDecoration(color: c.surf, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border, width: 0.5)),
          child: Row(children: [
            Icon(Icons.touch_app_outlined, size: 14, color: c.textMuted),
            const SizedBox(width: 8),
            Expanded(child: Text('Tap any character to open its dictionary card',
                style: TextStyle(color: c.textMuted, fontSize: 11))),
          ]),
        ),
      ],
    );
  }
}
