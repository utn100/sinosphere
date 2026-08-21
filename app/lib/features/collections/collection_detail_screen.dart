import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../core/services/database_provider.dart';
import '../../core/services/lang_mode_provider.dart';
import '../../core/theme/app_theme.dart';
import '../dict_card/dict_card_provider.dart';
import '../dict_card/widgets/word_enrichment.dart' show copyToClipboard, WordEnrichmentSection;
import '../dict_card/widgets/bookmark_button.dart';
import '../graph/graph_provider.dart' show koreanGraphSearchProvider;
import '../shell/app_shell.dart';
import '../practice/practice_screen.dart';
import 'collections_screen.dart' show hskMemorizedCountProvider, topikMemorizedCountProvider, userCollectionsProvider, totalMemorizedCountProvider;

// ── Providers ─────────────────────────────────────────────────────────────────

final collectionItemsProvider =
    FutureProvider.family<List<CollectionItem>, String>((ref, collectionId) =>
        ref.read(databaseProvider).collectionDao.getCollectionItems(collectionId));

// All memorized words for the current mode (keyed by isKorean) — Memorized drill-in.
final memorizedItemsProvider =
    FutureProvider.family<List<CollectionItem>, bool>((ref, isKorean) =>
        ref.read(databaseProvider).collectionDao.getMemorizedItems(isKorean: isKorean));

// ── User collection detail ────────────────────────────────────────────────────

class CollectionDetailScreen extends ConsumerWidget {
  final String collectionId;
  final String collectionName;

  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
    required this.collectionName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c        = context.colors;
    final items    = ref.watch(collectionItemsProvider(collectionId));
    final isKorean = ref.watch(langModeProvider) == LangMode.korean;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text(collectionName,
            style: TextStyle(color: c.text, fontWeight: FontWeight.w800)),
        backgroundColor: c.surf,
        iconTheme: IconThemeData(color: c.text),
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: items.when(
        loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.hanviet)),
        error: (_, _) => const SizedBox.shrink(),
        data: (allItems) {
          // Filter by lang mode: ZH hides native KR words; KR hides Chinese chars with no hangul
          final list = allItems.where((item) {
            if (isKorean) {
              // Hide Chinese characters and Chinese-only compound words (no hangul)
              return item.hangul != null;
            } else {
              // Hide native Korean words (hangul == display, no hanViet)
              return !(item.hanViet.isEmpty && item.hangul != null && item.hangul == item.display);
            }
          }).toList();
          if (list.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Image.asset('assets/logo.png', width: 120, height: 120),
              const SizedBox(height: 12),
              Text('No words in this deck yet.',
                  style: TextStyle(color: c.textMuted, fontStyle: FontStyle.italic)),
            ]));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, _) =>
                Divider(height: 0.5, thickness: 0.5, color: c.border, indent: 16),
            itemBuilder: (_, i) {
              final item = list[i];
              final display = isKorean && item.hangul != null ? item.hangul! : item.display;
              return _ItemRow(
                item: item,
                display: display,
                isKorean: isKorean,
                onTap: () => showCollectionWordSheet(context, ref,
                  display:    display,
                  simplified: item.display,
                  hanViet:    item.hanViet,
                  pinyin:     item.pinyin,
                  englishDef: item.englishDef,
                  hangul:     isKorean ? item.hangul : null,
                  romaja:     isKorean ? item.pinyin : null,
                ),
              );
            },
          );
        },
        ),  // SafeArea
      ),
    );
  }
}

/// Read-only drill-in for the "Memorized" folder. Lists every memorized word for
/// the CURRENT language mode (ZH → Chinese, KR → Korean), never mixed. Backed by
/// getMemorizedItems, which unions all deck buckets and de-dupes by word.
class MemorizedDetailScreen extends ConsumerWidget {
  const MemorizedDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c        = context.colors;
    final isKorean = ref.watch(langModeProvider) == LangMode.korean;
    final items    = ref.watch(memorizedItemsProvider(isKorean));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text('Memorized',
            style: TextStyle(color: c.text, fontWeight: FontWeight.w800)),
        backgroundColor: c.surf,
        iconTheme: IconThemeData(color: c.text),
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: items.when(
          loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.hanviet)),
          error: (_, _) => const SizedBox.shrink(),
          data: (list) {
            if (list.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/logo.png', width: 120, height: 120),
                const SizedBox(height: 12),
                Text('No memorized words yet.',
                    style: TextStyle(color: c.textMuted, fontStyle: FontStyle.italic)),
              ]));
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 0.5, thickness: 0.5, color: c.border, indent: 16),
              itemBuilder: (_, i) {
                final item = list[i];
                final display = isKorean && item.hangul != null ? item.hangul! : item.display;
                return _ItemRow(
                  item: item,
                  display: display,
                  isKorean: isKorean,
                  onTap: () => showCollectionWordSheet(context, ref,
                    display:    display,
                    simplified: item.display,
                    hanViet:    item.hanViet,
                    pinyin:     item.pinyin,
                    englishDef: item.englishDef,
                    hangul:     isKorean ? item.hangul : null,
                    romaja:     isKorean ? item.pinyin : null,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final CollectionItem item;
  final String display;
  final bool isKorean;
  final VoidCallback onTap;
  const _ItemRow({required this.item, required this.display,
      required this.isKorean, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          SizedBox(
            width: 48,
            child: Text(display,
                style: TextStyle(color: c.text,
                    fontSize: display.length == 1 ? 28 : 18,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (!isKorean)
                Text(item.hanViet.isEmpty ? '—' : item.hanViet,
                    style: const TextStyle(color: AppTheme.hanviet,
                        fontSize: 13, fontWeight: FontWeight.w800)),
              if (!isKorean) const SizedBox(width: 8),
              if (!isKorean)
                Text(item.pinyin,
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
              if (isKorean && item.pinyin.isNotEmpty)
                Text(item.pinyin,
                    style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12)),
            ]),
            if (item.englishDef.isNotEmpty)
              Text(
                item.englishDef.length > 50
                    ? '${item.englishDef.substring(0, 50)}…' : item.englishDef,
                style: TextStyle(color: c.textSub, fontSize: 11),
              ),
          ])),
          Icon(Icons.chevron_right, color: c.textMuted, size: 16),
        ]),
      ),
    );
  }
}

// ── HSK level detail ──────────────────────────────────────────────────────────

class HskDetailScreen extends ConsumerStatefulWidget {
  final int hskLevel;
  const HskDetailScreen({super.key, required this.hskLevel});

  @override
  ConsumerState<HskDetailScreen> createState() => _HskDetailScreenState();
}

class _HskDetailScreenState extends ConsumerState<HskDetailScreen> {
  static const _pageSize = 50;
  final _scrollCtrl = ScrollController();

  int _page = 0;
  int _total = 0;
  List<CompoundWord> _words = [];
  Set<String> _memorized = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPage(int page) async {
    setState(() => _loading = true);
    final db = ref.read(databaseProvider);
    final total      = await db.collectionDao.getHskWordCount(widget.hskLevel);
    final words      = await db.collectionDao.getHskWords(
        widget.hskLevel, offset: page * _pageSize, limit: _pageSize);
    final memorized  = await db.collectionDao.getMemorizedWordIds(widget.hskLevel);
    if (!mounted) return;
    setState(() {
      _page       = page;
      _total      = total;
      _words      = words;
      _memorized  = memorized;
      _loading    = false;
    });
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _toggleMemorized(String wordId) async {
    await ref.read(databaseProvider).collectionDao
        .toggleMemorized(CollectionDao.hskScope(widget.hskLevel), wordId);
    ref.invalidate(hskMemorizedCountProvider(widget.hskLevel));
    ref.invalidate(userCollectionsProvider);
    ref.invalidate(totalMemorizedCountProvider);
    ref.invalidate(memorizedItemsProvider);
    setState(() {
      if (_memorized.contains(wordId)) {
        _memorized = Set.from(_memorized)..remove(wordId);
      } else {
        _memorized = Set.from(_memorized)..add(wordId);
      }
    });
  }

  Future<void> _resetMemorized() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset memorized?'),
        content: const Text('All checked-off words will be restored to this list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset', style: TextStyle(color: Colors.orange))),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).collectionDao.resetMemorized(widget.hskLevel);
    ref.invalidate(hskMemorizedCountProvider(widget.hskLevel));
    ref.invalidate(totalMemorizedCountProvider);
    ref.invalidate(memorizedItemsProvider);
    setState(() => _memorized = {});
  }

  @override
  Widget build(BuildContext context) {
    final c          = context.colors;
    final pageCount  = (_total / _pageSize).ceil();
    final label      = widget.hskLevel == 7 ? 'HSK 7-9' : 'HSK ${widget.hskLevel}';
    // Filter out memorized words from the displayed list
    final visible    = _words.where((w) => !_memorized.contains(w.id)).toList();
    final memorizedCount = _words.where((w) => _memorized.contains(w.id)).length;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text(label,
            style: TextStyle(color: c.text, fontWeight: FontWeight.w800)),
        backgroundColor: c.surf,
        iconTheme: IconThemeData(color: c.text),
        elevation: 0,
        actions: [
          if (_memorized.isNotEmpty)
            TextButton.icon(
              onPressed: _resetMemorized,
              icon: const Icon(Icons.refresh, size: 16, color: AppTheme.hanviet),
              label: Text('Reset (${ _memorized.length})',
                  style: const TextStyle(color: AppTheme.hanviet, fontSize: 12)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              strokeWidth: 2, color: AppTheme.hanviet))
          : SafeArea(
              top: false,
              child: Column(children: [
              if (memorizedCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('$memorizedCount word${memorizedCount > 1 ? 's' : ''} memorised on this page',
                      style: TextStyle(color: AppTheme.semantic, fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              Expanded(
                child: visible.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppTheme.semantic, size: 48),
                        const SizedBox(height: 12),
                        Text('All words on this page memorised!',
                            style: TextStyle(color: c.textMuted, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _resetMemorized,
                            child: const Text('Reset', style: TextStyle(color: AppTheme.hanviet))),
                      ]))
                    : ListView.separated(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => Divider(
                      height: 0.5, thickness: 0.5, color: c.border, indent: 16),
                  itemBuilder: (_, i) {
                    final word = visible[i];
                    return InkWell(
                      onTap: () {
                        final isKorean = ref.read(langModeProvider) == LangMode.korean;
                        showCollectionWordSheet(context, ref,
                          display:   isKorean && word.hangul != null ? word.hangul! : word.simplified,
                          simplified: word.simplified,
                          hanViet:   word.hanViet,
                          pinyin:    word.pinyin,
                          englishDef: word.englishDef,
                          hskLabel:  isKorean
                              ? (word.topikLevel != null ? 'TOPIK ${word.topikLevel}' : null)
                              : (widget.hskLevel == 7 ? 'HSK 7-9' : 'HSK ${widget.hskLevel}'),
                          wordId:    word.id,
                          hangul:    isKorean ? word.hangul : null,
                          romaja:    isKorean ? word.romaja : null,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Consumer(builder: (ctx, ref, _) {
                          final isKorean = ref.watch(langModeProvider) == LangMode.korean;
                          return Row(children: [
                          SizedBox(
                            width: 56,
                            child: Text(
                              isKorean && word.hangul != null ? word.hangul! : word.simplified,
                              style: TextStyle(color: c.text, fontSize: 20,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              if (isKorean && word.romaja != null)
                                Text(word.romaja!,
                                    style: const TextStyle(
                                        color: Color(0xFF818CF8), fontSize: 12,
                                        fontWeight: FontWeight.w700))
                              else
                                Text(word.hanViet,
                                    style: const TextStyle(
                                        color: AppTheme.hanviet, fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              const SizedBox(width: 8),
                              if (!isKorean)
                                Text(word.pinyin,
                                    style: const TextStyle(
                                        color: Color(0xFF38BDF8), fontSize: 12)),
                            ]),
                            Text(
                              word.englishDef.length > 50
                                  ? '${word.englishDef.substring(0, 50)}…'
                                  : word.englishDef,
                              style: TextStyle(color: c.textSub, fontSize: 11),
                            ),
                          ])),
                          // Check off button
                          GestureDetector(
                            onTap: () => _toggleMemorized(word.id),
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.semantic.withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check,
                                  color: AppTheme.semantic, size: 16),
                            ),
                          ),
                        ]);
                        }),
                      ),
                    );
                  },
                ),
              ),

              // Page navigation footer
              if (pageCount > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.surf,
                    border: Border(top: BorderSide(color: c.border, width: 0.5)),
                  ),
                  child: Row(children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _page > 0 ? AppTheme.hanviet : c.border),
                        foregroundColor: _page > 0 ? AppTheme.hanviet : c.textMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _page > 0 ? () => _loadPage(_page - 1) : null,
                      child: const Text('← Prev'),
                    ),
                    Expanded(
                      child: Text('Page ${_page + 1} of $pageCount',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.textMuted, fontSize: 12)),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: _page < pageCount - 1 ? AppTheme.hanviet : c.border),
                        foregroundColor: _page < pageCount - 1
                            ? AppTheme.hanviet : c.textMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _page < pageCount - 1
                          ? () => _loadPage(_page + 1) : null,
                      child: const Text('Next →'),
                    ),
                  ]),
                ),
            ]),
          ), // SafeArea
    );
  }
}

// ── Shared word detail sheet ─────────────────────────────────────────────────

void showCollectionWordSheet(BuildContext context, WidgetRef ref, {
  required String display,
  required String hanViet,
  required String pinyin,
  required String englishDef,
  String? hskLabel,
  String? wordId,
  String? hangul,
  String? romaja,
  String? simplified,
}) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    builder: (ctx) {
      final nav = Navigator.of(context);
      return DraggableScrollableSheet(
      initialChildSize: 0.45, minChildSize: 0.3, maxChildSize: 0.85,
      expand: false,
      builder: (_, ctrl) => _CollectionWordSheet(
        display: display, hanViet: hanViet, pinyin: pinyin,
        englishDef: englishDef, hskLabel: hskLabel,
        wordId: wordId, hangul: hangul, romaja: romaja,
        simplified: simplified,
        scrollController: ctrl,
        onCharTap: (ch) {
          Navigator.pop(ctx);
          ref.read(langModeProvider.notifier).set(LangMode.chinese);
          ref.read(activeSymbolProvider.notifier).set(ch);
          ref.read(tabIndexProvider.notifier).set(0);
          nav.popUntil((route) => route.isFirst);
        },
        onViewZhGraph: (hangul != null && simplified != null && simplified != hangul)
          ? () {
              Navigator.pop(ctx);
              ref.read(koreanGraphSearchProvider.notifier)
                  .set((simplified: simplified!, hangul: hangul!));
              ref.read(tabIndexProvider.notifier).set(1);
              nav.popUntil((route) => route.isFirst);
            }
          : null,
      ),
    );
    },
  );
}

class _CollectionWordSheet extends StatelessWidget {
  final String display, hanViet, pinyin, englishDef;
  final String? hskLabel;
  final String? wordId;
  final String? hangul;
  final String? romaja;
  final String? simplified;
  final VoidCallback? onViewZhGraph;
  final ScrollController scrollController;
  final void Function(String ch) onCharTap;

  const _CollectionWordSheet({
    required this.display, required this.hanViet, required this.pinyin,
    required this.englishDef, required this.scrollController,
    required this.onCharTap, this.hskLabel, this.wordId,
    this.hangul, this.romaja, this.simplified, this.onViewZhGraph,
  });

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final chars  = display.split('');
    final isKr   = hangul != null;
    final krColor = const Color(0xFF818CF8);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        // Handle + practice button row
        Row(children: [
          const Spacer(),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PracticeScreen(
                symbol: simplified ?? display,
                pinyin: pinyin,
                hanViet: hanViet,
                englishDef: englishDef,
              ),
            )),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.edit_outlined, color: c.textMuted, size: 20),
            ),
          ),
        ]),
        const SizedBox(height: 20),

        // Hero: hangul (large) or tappable Chinese chars
        if (isKr) ...[
          Text(hangul!,
              style: TextStyle(color: c.text, fontSize: 48,
                  fontWeight: FontWeight.w700, height: 1.1)),
          const SizedBox(height: 6),
          if (romaja != null)
            Text(romaja!,
                style: TextStyle(color: krColor, fontSize: 18,
                    fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          // Hanja row — only for Sino-Korean words (simplified differs from hangul)
          if (simplified != null && simplified != hangul) Row(children: [
            Text('Hanja  ', style: TextStyle(color: c.textMuted, fontSize: 11)),
            ...(simplified ?? display).split('').map((ch) => GestureDetector(
              onTap: () => onCharTap(ch),
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.hanviet.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.hanviet.withAlpha(80)),
                ),
                child: Text(ch, style: const TextStyle(
                    color: AppTheme.hanviet, fontSize: 22, fontWeight: FontWeight.w700)),
              ),
            )),
          ]),
        ] else ...[
          Wrap(
            spacing: 4, runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: chars.map((ch) => GestureDetector(
              onTap: () => onCharTap(ch),
              onLongPress: () => copyToClipboard(context, display),
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
            Flexible(child: Text(hanViet,
                style: const TextStyle(color: AppTheme.hanviet, fontSize: 20,
                    fontWeight: FontWeight.w900))),
            const SizedBox(width: 12),
            Flexible(child: Text(pinyin,
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 14))),
          ]),
        ],
        const SizedBox(height: 8),
        Text(englishDef, style: TextStyle(color: c.text, fontSize: 14, height: 1.5)),
        if (hskLabel != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: (isKr ? krColor : AppTheme.hanviet).withAlpha(38),
                borderRadius: BorderRadius.circular(8)),
            child: Text(hskLabel!,
                style: TextStyle(
                    color: isKr ? krColor : AppTheme.hanviet,
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],

        if (wordId != null) ...[
          const SizedBox(height: 10),
          BookmarkButton(wordId: wordId!),
        ],
        if (isKr && onViewZhGraph != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onViewZhGraph,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: krColor.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: krColor.withAlpha(51), width: 0.5),
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: krColor.withAlpha(38),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.hub_outlined, color: krColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Explore Hanja Graph',
                      style: TextStyle(color: krColor, fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text('Open Pivot network',
                      style: TextStyle(color: c.textMuted, fontSize: 11)),
                ])),
                Icon(Icons.chevron_right, color: krColor, size: 20),
              ]),
            ),
          ),
        ],
        if (wordId != null && !isKr)
          WordEnrichmentSection(
            wordId:     wordId!,
            simplified: display,
            pinyin:     pinyin,
            englishDef: englishDef,
          ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.surf, borderRadius: BorderRadius.circular(12),
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
    );
  }
}

// ── Topic collection detail ───────────────────────────────────────────────────

class TopicDetailScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String topicName;
  const TopicDetailScreen({super.key, required this.topicId, required this.topicName});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  static const _pageSize = 50;
  final _scrollCtrl = ScrollController();

  int _page = 0;
  int _total = 0;
  List<CompoundWord> _words = [];
  Set<String> _memorized = {};
  bool _loading = true;
  LangMode? _lastLangMode;

  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mode = ref.read(langModeProvider);
    if (_lastLangMode != null && _lastLangMode != mode) _loadPage(0);
    _lastLangMode = mode;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPage(int page) async {
    setState(() => _loading = true);
    final db = ref.read(databaseProvider);
    final isKorean = ref.read(langModeProvider) == LangMode.korean;
    final total     = await db.collectionDao.getTopicWordCount(widget.topicId, krOnly: isKorean);
    final words     = await db.collectionDao.getTopicWords(
        widget.topicId, offset: page * _pageSize, limit: _pageSize, krOnly: isKorean);
    // Load memorized state scoped to THIS topic bucket (never other decks)
    final memorized = await db.collectionDao
        .getMemorizedWordIdsByScope(CollectionDao.topicScope(widget.topicId));
    // Store full set (not page-scoped) so marks persist across page navigation
    if (!mounted) return;
    setState(() {
      _page      = page;
      _total     = total;
      _words     = words;
      _memorized = memorized;
      _loading   = false;
    });
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _toggleMemorized(String wordId) async {
    await ref.read(databaseProvider).collectionDao
        .toggleMemorized(CollectionDao.topicScope(widget.topicId), wordId);
    ref.invalidate(userCollectionsProvider);
    ref.invalidate(totalMemorizedCountProvider);
    ref.invalidate(memorizedItemsProvider);
    setState(() {
      if (_memorized.contains(wordId)) {
        _memorized = Set.from(_memorized)..remove(wordId);
      } else {
        _memorized = Set.from(_memorized)..add(wordId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c          = context.colors;
    final pageCount  = (_total / _pageSize).ceil();
    final visible    = _words.where((w) => !_memorized.contains(w.id)).toList();
    final memCount   = _words.where((w) => _memorized.contains(w.id)).length;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text(widget.topicName,
            style: TextStyle(color: c.text, fontWeight: FontWeight.w800)),
        backgroundColor: c.surf,
        iconTheme: IconThemeData(color: c.text),
        elevation: 0,
        actions: [
          if (_memorized.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                await ref.read(databaseProvider).collectionDao
                    .resetMemorizedByScope(CollectionDao.topicScope(widget.topicId));
                ref.invalidate(userCollectionsProvider);
                ref.invalidate(totalMemorizedCountProvider);
    ref.invalidate(memorizedItemsProvider);
                setState(() => _memorized = {});
              },
              icon: const Icon(Icons.refresh, size: 16, color: AppTheme.hanviet),
              label: Text('Reset (${_memorized.length})',
                  style: const TextStyle(color: AppTheme.hanviet, fontSize: 12)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              strokeWidth: 2, color: AppTheme.hanviet))
          : SafeArea(
              top: false,
              child: Column(children: [
                if (memCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text('$memCount word${memCount > 1 ? 's' : ''} memorised on this page',
                        style: const TextStyle(color: AppTheme.semantic, fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                Expanded(
                  child: visible.isEmpty
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.check_circle_outline,
                              color: AppTheme.semantic, size: 48),
                          const SizedBox(height: 12),
                          Text('All words on this page memorised!',
                              style: TextStyle(color: c.textMuted, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              await ref.read(databaseProvider).collectionDao
                                  .resetMemorizedByScope(CollectionDao.topicScope(widget.topicId));
                              ref.invalidate(userCollectionsProvider);
                              ref.invalidate(totalMemorizedCountProvider);
    ref.invalidate(memorizedItemsProvider);
                              setState(() => _memorized = {});
                            },
                            child: const Text('Reset', style: TextStyle(color: AppTheme.hanviet))),
                        ]))
                      : ListView.separated(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => Divider(
                              height: 0.5, thickness: 0.5, color: c.border, indent: 16),
                          itemBuilder: (_, i) {
                            final word = visible[i];
                            return InkWell(
                              onTap: () {
                                final isKorean = ref.read(langModeProvider) == LangMode.korean;
                                showCollectionWordSheet(context, ref,
                                  display:    isKorean && word.hangul != null ? word.hangul! : word.simplified,
                                  simplified: word.simplified,
                                  hanViet:    word.hanViet,
                                  pinyin:     word.pinyin,
                                  englishDef: word.englishDef,
                                  hskLabel:   isKorean
                                      ? (word.topikLevel != null ? 'TOPIK ${word.topikLevel}' : null)
                                      : (word.hskLevel != null
                                          ? 'HSK ${word.hskLevel == 7 ? '7-9' : word.hskLevel}'
                                          : null),
                                  wordId:  word.id,
                                  hangul:  isKorean ? word.hangul : null,
                                  romaja:  isKorean ? word.romaja : null,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Consumer(builder: (ctx, ref, _) {
                                  final isKorean = ref.watch(langModeProvider) == LangMode.korean;
                                  return Row(children: [
                                  SizedBox(
                                    width: 56,
                                    child: Text(
                                      isKorean && word.hangul != null ? word.hangul! : word.simplified,
                                      style: TextStyle(color: c.text, fontSize: 20,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                    Row(children: [
                                      if (isKorean && word.romaja != null)
                                        Text(word.romaja!,
                                            style: const TextStyle(color: Color(0xFF818CF8),
                                                fontSize: 12, fontWeight: FontWeight.w700))
                                      else
                                        Text(word.hanViet,
                                            style: const TextStyle(color: AppTheme.hanviet,
                                                fontSize: 12, fontWeight: FontWeight.w800)),
                                      const SizedBox(width: 8),
                                      if (!isKorean)
                                        Text(word.pinyin,
                                            style: const TextStyle(
                                                color: Color(0xFF38BDF8), fontSize: 12)),
                                    ]),
                                    Text(
                                      word.englishDef.length > 50
                                          ? '${word.englishDef.substring(0, 50)}…'
                                          : word.englishDef,
                                      style: TextStyle(color: c.textSub, fontSize: 11),
                                    ),
                                  ])),
                                  GestureDetector(
                                    onTap: () => _toggleMemorized(word.id),
                                    child: Container(
                                      width: 32, height: 32,
                                      decoration: BoxDecoration(
                                        color: AppTheme.semantic.withAlpha(26),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.check,
                                          color: AppTheme.semantic, size: 16),
                                    ),
                                  ),
                                ]);
                                }),
                              ),
                            );
                          },
                        ),
                ),
                if (pageCount > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.surf,
                      border: Border(top: BorderSide(color: c.border, width: 0.5)),
                    ),
                    child: Row(children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: _page > 0 ? AppTheme.hanviet : c.border),
                          foregroundColor: _page > 0 ? AppTheme.hanviet : c.textMuted,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _page > 0 ? () => _loadPage(_page - 1) : null,
                        child: const Text('← Prev'),
                      ),
                      Expanded(child: Text('Page ${_page + 1} of $pageCount',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.textMuted, fontSize: 12))),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: _page < pageCount - 1 ? AppTheme.hanviet : c.border),
                          foregroundColor:
                              _page < pageCount - 1 ? AppTheme.hanviet : c.textMuted,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _page < pageCount - 1
                            ? () => _loadPage(_page + 1) : null,
                        child: const Text('Next →'),
                      ),
                    ]),
                  ),
              ]),
            ),
    );
  }
}

// ── TOPIK Detail Screen ───────────────────────────────────────────────────────

class TopikDetailScreen extends ConsumerStatefulWidget {
  final List<int> topikLevels; // e.g. [1] for A, [3] for B, [5,6] for C
  final String band;           // 'A', 'B', 'C'
  final String desc;

  const TopikDetailScreen({
    super.key,
    required this.topikLevels,
    required this.band,
    required this.desc,
  });

  // Convenience getter for single-level compatibility
  int get topikLevel => topikLevels.first;

  @override
  ConsumerState<TopikDetailScreen> createState() => _TopikDetailScreenState();
}

class _TopikDetailScreenState extends ConsumerState<TopikDetailScreen> {
  static const _pageSize = 50;
  static const _krColor  = Color(0xFF818CF8);

  List<CompoundWord> _words    = [];
  Set<String>        _memorized = {};
  int     _total   = 0;
  int     _page    = 0;
  bool    _loading = true;
  String? _error;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPage(int page) async {
    setState(() { _loading = true; _error = null; });
    try {
      final db    = ref.read(databaseProvider);
      final levels = widget.topikLevels;
      final total = levels.length == 1
          ? await db.collectionDao.getTopikWordCount(levels.first)
          : await db.collectionDao.getTopikWordCountMulti(levels);
      final words = levels.length == 1
          ? await db.collectionDao.getTopikWords(levels.first, offset: page * _pageSize, limit: _pageSize)
          : await db.collectionDao.getTopikWordsMulti(levels, offset: page * _pageSize, limit: _pageSize);
      final allMem = await db.collectionDao
          .getMemorizedWordIdsByTopikLevels(levels);
      if (!mounted) return;
      setState(() {
        _page      = page;
        _total     = total;
        _words     = words;
        _memorized = allMem;
        _loading   = false;
      });
    } catch (e, st) {
      debugPrint('TopikDetailScreen._loadPage error: $e\n$st');
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _toggleMemorized(String wordId) async {
    await ref.read(databaseProvider).collectionDao
        .toggleMemorized(CollectionDao.topikScope(widget.topikLevels), wordId);
    ref.invalidate(topikMemorizedCountProvider(widget.topikLevels.join(',')));
    ref.invalidate(userCollectionsProvider);
    ref.invalidate(totalMemorizedCountProvider);
    ref.invalidate(memorizedItemsProvider);
    setState(() {
      if (_memorized.contains(wordId)) {
        _memorized = Set.from(_memorized)..remove(wordId);
      } else {
        _memorized = Set.from(_memorized)..add(wordId);
      }
    });
  }

  Future<void> _resetMemorized() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset memorized?'),
        content: const Text('All checked-off words will be restored to this list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset', style: TextStyle(color: Colors.orange))),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).collectionDao
        .resetMemorizedByScope(CollectionDao.topikScope(widget.topikLevels));
    ref.invalidate(topikMemorizedCountProvider(widget.topikLevels.join(',')));
    ref.invalidate(totalMemorizedCountProvider);
    ref.invalidate(memorizedItemsProvider);
    setState(() => _memorized = {});
  }

  @override
  Widget build(BuildContext context) {
    final c          = context.colors;
    final pageCount  = (_total / _pageSize).ceil();
    final visible    = _words.where((w) => !_memorized.contains(w.id)).toList();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text('TOPIK ${widget.band} · ${widget.desc}',
            style: TextStyle(color: c.text, fontWeight: FontWeight.w800)),
        backgroundColor: c.surf,
        iconTheme: IconThemeData(color: c.text),
        elevation: 0,
        actions: [
          if (_memorized.isNotEmpty)
            TextButton.icon(
              onPressed: _resetMemorized,
              icon: const Icon(Icons.refresh, size: 16, color: _krColor),
              label: Text('Reset (${_memorized.length})',
                  style: const TextStyle(color: _krColor, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: _krColor))
            : _error != null
            ? Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text('Load error', style: TextStyle(color: c.text,
                      fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: c.textMuted, fontSize: 12),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadPage(0),
                    child: const Text('Retry'),
                  ),
                ]),
              ))
            : Column(children: [
                // Progress bar
                if (_total > 0) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('TOPIK ${widget.band} progress',
                            style: TextStyle(color: c.textMuted, fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        Text('${_memorized.length} / $_total',
                            style: const TextStyle(color: _krColor,
                                fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _total > 0 ? _memorized.length / _total : 0,
                        backgroundColor: c.border,
                        color: _krColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ]),
                  ),
                ],
                Expanded(
                  child: visible.isEmpty
                      ? Center(child: Text(
                          _total == 0 ? 'No words found' : 'All words memorized! 🎉',
                          style: TextStyle(color: c.textMuted)))
                      : ListView.separated(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) =>
                              Divider(height: 0.5, thickness: 0.5, color: c.border, indent: 16),
                          itemBuilder: (_, i) {
                            final word = visible[i];
                            return InkWell(
                              onTap: () => showCollectionWordSheet(context, ref,
                                display:    word.hangul ?? word.simplified,
                                simplified: word.simplified,
                                hanViet:    word.hanViet,
                                pinyin:     word.pinyin,
                                englishDef: word.englishDef,
                                hskLabel:   'TOPIK ${widget.band}',
                                wordId:     word.id,
                                hangul:     word.hangul,
                                romaja:     word.romaja,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Row(children: [
                                  SizedBox(
                                    width: 64,
                                    child: Text(word.hangul ?? word.simplified,
                                        style: TextStyle(color: c.text, fontSize: 20,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                    if (word.romaja != null)
                                      Text(word.romaja!,
                                          style: const TextStyle(color: _krColor,
                                              fontSize: 12, fontWeight: FontWeight.w700)),
                                    Text(word.englishDef.length > 55
                                        ? '${word.englishDef.substring(0, 55)}…'
                                        : word.englishDef,
                                        style: TextStyle(color: c.textSub, fontSize: 11)),
                                  ])),
                                  Text(word.simplified,
                                      style: TextStyle(color: c.textMuted, fontSize: 12)),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _toggleMemorized(word.id),
                                    child: Container(
                                      width: 32, height: 32,
                                      decoration: BoxDecoration(
                                        color: AppTheme.semantic.withAlpha(26),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.check,
                                          color: AppTheme.semantic, size: 16),
                                    ),
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
                // Page navigation
                if (pageCount > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.surf,
                      border: Border(top: BorderSide(color: c.border, width: 0.5)),
                    ),
                    child: Row(children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _page > 0 ? _krColor : c.border),
                          foregroundColor: _page > 0 ? _krColor : c.textMuted,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _page > 0 ? () => _loadPage(_page - 1) : null,
                        child: const Text('← Prev'),
                      ),
                      Expanded(child: Text('Page ${_page + 1} of $pageCount',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.textMuted, fontSize: 12))),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _page < pageCount - 1 ? _krColor : c.border),
                          foregroundColor: _page < pageCount - 1 ? _krColor : c.textMuted,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _page < pageCount - 1 ? () => _loadPage(_page + 1) : null,
                        child: const Text('Next →'),
                      ),
                    ]),
                  ),
              ]),
      ),
    );
  }
}
