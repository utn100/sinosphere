import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../core/services/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../dict_card/dict_card_provider.dart';
import '../shell/app_shell.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final collectionItemsProvider =
    FutureProvider.family<List<CollectionItem>, String>((ref, collectionId) =>
        ref.read(databaseProvider).collectionDao.getCollectionItems(collectionId));

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
    final c     = context.colors;
    final items = ref.watch(collectionItemsProvider(collectionId));

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
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text('No words in this deck yet.',
                style: TextStyle(color: c.textMuted, fontStyle: FontStyle.italic)));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, _) =>
                Divider(height: 0.5, thickness: 0.5, color: c.border, indent: 16),
            itemBuilder: (_, i) => _ItemRow(
              item: list[i],
              onTap: () => showCollectionWordSheet(context, ref,
                display: list[i].display,
                hanViet: list[i].hanViet,
                pinyin: list[i].pinyin,
                englishDef: list[i].englishDef,
              ),
            ),
          );
        },
        ),  // SafeArea
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final CollectionItem item;
  final VoidCallback onTap;
  const _ItemRow({required this.item, required this.onTap});

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
            child: Text(item.display,
                style: TextStyle(color: c.text,
                    fontSize: item.display.length == 1 ? 28 : 18,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(item.hanViet.isEmpty ? '—' : item.hanViet,
                  style: const TextStyle(color: AppTheme.hanviet,
                      fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Text(item.pinyin,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
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
    await ref.read(databaseProvider).collectionDao.toggleMemorized(wordId);
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
                      onTap: () => showCollectionWordSheet(context, ref,
                        display: word.simplified,
                        hanViet: word.hanViet,
                        pinyin: word.pinyin,
                        englishDef: word.englishDef,
                        hskLabel: widget.hskLevel == 7
                            ? 'HSK 7-9' : 'HSK ${widget.hskLevel}',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(children: [
                          SizedBox(
                            width: 56,
                            child: Text(word.simplified,
                                style: TextStyle(color: c.text, fontSize: 20,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Text(word.hanViet,
                                  style: const TextStyle(
                                      color: AppTheme.hanviet, fontSize: 12,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(width: 8),
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
                        ]),
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
}) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    builder: (ctx) {
      // Capture NavigatorState before any async gap to avoid use-after-dispose
      final nav = Navigator.of(context);
      return DraggableScrollableSheet(
      initialChildSize: 0.45, minChildSize: 0.3, maxChildSize: 0.85,
      expand: false,
      builder: (_, ctrl) => _CollectionWordSheet(
        display: display, hanViet: hanViet, pinyin: pinyin,
        englishDef: englishDef, hskLabel: hskLabel,
        scrollController: ctrl,
        onCharTap: (ch) {
          Navigator.pop(ctx);
          ref.read(activeSymbolProvider.notifier).set(ch);
          ref.read(tabIndexProvider.notifier).set(0);
          nav.popUntil((route) => route.isFirst);
        },
      ),
    );
    },
  );
}

class _CollectionWordSheet extends StatelessWidget {
  final String display, hanViet, pinyin, englishDef;
  final String? hskLabel;
  final ScrollController scrollController;
  final void Function(String ch) onCharTap;

  const _CollectionWordSheet({
    required this.display, required this.hanViet, required this.pinyin,
    required this.englishDef, required this.scrollController,
    required this.onCharTap, this.hskLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c     = context.colors;
    final chars = display.split('');

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),

        // Tappable character row
        Wrap(
          spacing: 4, runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: chars.map((ch) => GestureDetector(
            onTap: () => onCharTap(ch),
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
        const SizedBox(height: 8),
        Text(englishDef, style: TextStyle(color: c.text, fontSize: 14, height: 1.5)),
        if (hskLabel != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.hanviet.withAlpha(38),
                borderRadius: BorderRadius.circular(8)),
            child: Text(hskLabel!,
                style: const TextStyle(color: AppTheme.hanviet, fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ],
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
    final total     = await db.collectionDao.getTopicWordCount(widget.topicId);
    final words     = await db.collectionDao.getTopicWords(
        widget.topicId, offset: page * _pageSize, limit: _pageSize);
    // Reuse memorized storage keyed by a pseudo-level — use -1 * topicId.hashCode
    final memorized = <String>{};
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
              onPressed: () => setState(() => _memorized = {}),
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
                          TextButton(onPressed: () => setState(() => _memorized = {}),
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
                              onTap: () => showCollectionWordSheet(context, ref,
                                display: word.simplified,
                                hanViet: word.hanViet,
                                pinyin: word.pinyin,
                                englishDef: word.englishDef,
                                hskLabel: word.hskLevel != null
                                    ? 'HSK ${word.hskLevel == 7 ? '7-9' : word.hskLevel}'
                                    : null,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Row(children: [
                                  SizedBox(
                                    width: 56,
                                    child: Text(word.simplified,
                                        style: TextStyle(color: c.text, fontSize: 20,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                    Row(children: [
                                      Text(word.hanViet,
                                          style: const TextStyle(color: AppTheme.hanviet,
                                              fontSize: 12, fontWeight: FontWeight.w800)),
                                      const SizedBox(width: 8),
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
                                ]),
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
