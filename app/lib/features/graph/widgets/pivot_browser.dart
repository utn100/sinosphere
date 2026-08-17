import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/services/lang_mode_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../dict_card/dict_card_provider.dart';
import '../../shell/app_shell.dart' show tabIndexProvider;
import '../graph_provider.dart';

// ── Pivot data ────────────────────────────────────────────────────────────────

typedef KrPivot = ({String hanzi, String hangul, String romaja, String meaning, String pinyin});

const kPivots = <KrPivot>[
  (hanzi: '学', hangul: '학', romaja: 'hak',  meaning: 'Learn',     pinyin: 'xué'),
  (hanzi: '水', hangul: '수', romaja: 'su',   meaning: 'Water',     pinyin: 'shuǐ'),
  (hanzi: '心', hangul: '심', romaja: 'sim',  meaning: 'Heart',     pinyin: 'xīn'),
  (hanzi: '电', hangul: '전', romaja: 'jeon', meaning: 'Electric',  pinyin: 'diàn'),
  (hanzi: '人', hangul: '인', romaja: 'in',   meaning: 'Person',    pinyin: 'rén'),
  (hanzi: '国', hangul: '국', romaja: 'guk',  meaning: 'Country',   pinyin: 'guó'),
  (hanzi: '语', hangul: '어', romaja: 'eo',   meaning: 'Language',  pinyin: 'yǔ'),
  (hanzi: '山', hangul: '산', romaja: 'san',  meaning: 'Mountain',  pinyin: 'shān'),
];

double _zhOp(double lens) => lens <= 50 ? 1.0 : max(0.25, 1.0 - (lens - 50) / 70);
double _krOp(double lens) => lens >= 50 ? 1.0 : max(0.25, 1.0 - (50 - lens) / 70);

// ── Korean node data ──────────────────────────────────────────────────────────

enum KrNodeType { pivot, korean, chinese, showMore }

class KrNode {
  final String id;
  final KrNodeType type;
  final String label;
  final String? subLabel;  // romaja (KR) or pinyin (ZH)
  final String? badge;     // TOPIK or HSK
  final String? englishDef;
  final CompoundWord? word;
  Offset position;

  KrNode({
    required this.id,
    required this.type,
    required this.label,
    this.subLabel,
    this.badge,
    this.englishDef,
    this.word,
    this.position = Offset.zero,
  });

  double get radius {
    switch (type) {
      case KrNodeType.pivot:    return 30;   // larger — only 5 nodes per side
      case KrNodeType.korean:   return 24;
      case KrNodeType.chinese:  return 21;
      case KrNodeType.showMore: return 13;
    }
  }

  Color get color {
    switch (type) {
      case KrNodeType.pivot:    return AppTheme.coral;   // brand primary
      case KrNodeType.korean:   return const Color(0xFF6366F1);
      case KrNodeType.chinese:  return AppTheme.hanviet;  // amber — ZH accent
      case KrNodeType.showMore: return const Color(0xFF64748B);
    }
  }
}

// ── Layout helper ─────────────────────────────────────────────────────────────

const kPageSize = 5;

List<KrNode> buildNodes(
    KrPivot pivot, List<CompoundWord> kr, List<CompoundWord> zh, Size size,
    {int page = 0}) {
  final cx = size.width / 2;
  final cy = size.height * 0.45;
  final nodes = <KrNode>[];

  // Pivot center
  nodes.add(KrNode(
    id: 'pivot',
    type: KrNodeType.pivot,
    label: '${pivot.hanzi}/${pivot.hangul}',
    subLabel: '${pivot.pinyin} · ${pivot.romaja}',  // both readings below circle
    badge: pivot.meaning,
    position: Offset(cx, cy),
  ));

  // Both sides slice to the same page so cognate pairs stay in sync
  final krSlice = kr.skip(page * kPageSize).take(kPageSize).toList();
  final zhSlice = zh.skip(page * kPageSize).take(kPageSize).toList();
  final count   = max(krSlice.length, zhSlice.length);
  final spacing = min(72.0, (size.height * 0.80) / max(count, 1));
  final startY  = cy - (count - 1) * spacing / 2;

  final krX = cx + size.width * 0.33;
  for (int i = 0; i < krSlice.length; i++) {
    final w = krSlice[i];
    nodes.add(KrNode(
      id: 'kr_$i',
      type: KrNodeType.korean,
      label: w.hangul ?? w.simplified,
      subLabel: w.romaja,
      badge: w.topikLevel != null ? 'T${w.topikLevel}' : null,
      englishDef: w.englishDef,
      word: w,
      position: Offset(krX, startY + i * spacing),
    ));
  }

  final zhX = cx - size.width * 0.33;
  for (int i = 0; i < zhSlice.length; i++) {
    final w = zhSlice[i];
    nodes.add(KrNode(
      id: 'zh_$i',
      type: KrNodeType.chinese,
      label: w.simplified,
      subLabel: null,  // pinyin available on tap via inspector
      badge: w.hskLevel != null ? 'H${w.hskLevel}' : null,
      englishDef: w.englishDef,
      word: w,
      position: Offset(zhX, startY + i * spacing),
    ));
  }

  return nodes;
}

// ── Painter ───────────────────────────────────────────────────────────────────

class KoreanGraphPainter extends CustomPainter {
  final List<KrNode> nodes;
  final String? selectedId;
  final String? cognateId;   // highlighted cognate of the selected node
  final double focusLens;

  KoreanGraphPainter(this.nodes, {this.selectedId, this.cognateId, required this.focusLens});

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = nodes.firstWhere((n) => n.type == KrNodeType.pivot,
        orElse: () => nodes.first);

    // Build simplified→ZH node position map for cognate lines
    final zhBySimplified = <String, Offset>{};
    for (final n in nodes.where((n) => n.type == KrNodeType.chinese)) {
      if (n.word != null) zhBySimplified[n.word!.simplified] = n.position;
    }

    // Draw pivot→leaf edges (skip showMore)
    for (final node in nodes) {
      if (node.type == KrNodeType.pivot || node.type == KrNodeType.showMore) continue;
      final opacity = node.type == KrNodeType.korean
          ? _krOp(focusLens) : _zhOp(focusLens);
      canvas.drawLine(pivot.position, node.position,
          Paint()
            ..color = node.color.withAlpha((opacity * 80).round())
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke);
    }

    // Draw nodes (front)
    for (final node in nodes) {
      _drawNode(canvas, node);
    }
  }


  void _drawNode(Canvas canvas, KrNode node) {
    final isSelected    = node.id == selectedId;
    final isCognate     = node.id == cognateId;
    final isHighlighted = isSelected || isCognate;
    final opacity = switch (node.type) {
      KrNodeType.pivot    => 1.0,
      KrNodeType.korean   => _krOp(focusLens),
      KrNodeType.chinese  => _zhOp(focusLens),
      KrNodeType.showMore => 0.8,
    };
    final color = node.color;
    final r     = node.radius;
    final pos   = node.position;

    if (node.type == KrNodeType.showMore) {
      canvas.drawCircle(pos, r,
          Paint()..color = color.withAlpha((opacity * 60).round()));
      canvas.drawCircle(pos, r,
          Paint()
            ..color = color.withAlpha((opacity * 180).round())
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke);
      _drawText(canvas, node.label, pos,
          TextStyle(color: Colors.white.withAlpha((opacity * 220).round()),
              fontSize: 9, fontWeight: FontWeight.w700),
          maxWidth: r * 2.2);
      return;
    }

    // Fill
    canvas.drawCircle(pos, r,
        Paint()..color = color.withAlpha(
            (opacity * (node.type == KrNodeType.pivot ? 220 : 150)).round()));

    // Border
    canvas.drawCircle(pos, r,
        Paint()
          ..color = isHighlighted ? Colors.white : color.withAlpha((opacity * 255).round())
          ..strokeWidth = isHighlighted ? 2.5 : 1.2
          ..style = PaintingStyle.stroke);

    // Glow — brighter for direct selection, softer for cognate
    if (isSelected) {
      canvas.drawCircle(pos, r + 6, Paint()..color = color.withAlpha(80));
    } else if (isCognate) {
      canvas.drawCircle(pos, r + 4, Paint()..color = color.withAlpha(50));
    }

    // Label — centered inside the circle (no vertical offset)
    _drawText(canvas, node.label, pos,
        TextStyle(
          color: Colors.white.withAlpha((opacity * 255).round()),
          fontSize: node.type == KrNodeType.pivot ? 13 : 10,
          fontWeight: FontWeight.w800,
        ),
        maxWidth: r * 2.2);

    // SubLabel — drawn BELOW the circle (outside), not inside
    final hasSub = node.subLabel != null && node.subLabel!.isNotEmpty;
    if (hasSub) {
      _drawText(canvas, node.subLabel!, pos,
          TextStyle(
            color: color.withAlpha((opacity * 180).round()),
            fontSize: 7,
            fontWeight: FontWeight.w600,
          ),
          maxWidth: r * 3.0, offsetY: r + 10);
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style,
      {double maxWidth = 60, double offsetY = 0}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, center + Offset(-tp.width / 2, -tp.height / 2 + offsetY));
  }

  @override
  bool shouldRepaint(KoreanGraphPainter old) =>
      old.selectedId != selectedId || old.cognateId != cognateId ||
      old.focusLens != focusLens || old.nodes != nodes;
}

// ── Canvas widget ─────────────────────────────────────────────────────────────

class PivotBrowserView extends ConsumerStatefulWidget {
  final double focusLens;
  final List<KrPivot>? dynamicPivots;
  final String? nativeWordName; // non-null = searched word is native Korean (no hanja)

  const PivotBrowserView({
    super.key,
    required this.focusLens,
    this.dynamicPivots,
    this.nativeWordName,
  });

  @override
  ConsumerState<PivotBrowserView> createState() => _PivotBrowserViewState();
}

class _PivotBrowserViewState extends ConsumerState<PivotBrowserView> {
  KrPivot _activePivot = kPivots[0];
  String? _selectedId;
  String? _cognateId;
  KrNode? _selectedNode;
  int     _page        = 0;  // current page (0-indexed, kPageSize nodes per page)

  final _transformCtrl = TransformationController();

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PivotBrowserView old) {
    super.didUpdateWidget(old);
    // When dynamic pivots change (new search), reset to first pivot
    final newPivots = widget.dynamicPivots ?? kPivots;
    final oldPivots = old.dynamicPivots ?? kPivots;
    if (newPivots != oldPivots && newPivots.isNotEmpty) {
      setState(() {
        _activePivot  = newPivots.first;
        _selectedId   = null;
        _cognateId    = null;
        _selectedNode = null;
        _page         = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;

    // Native Korean word — no hanja pivot exists, show message + default pivots
    if (widget.nativeWordName != null && widget.nativeWordName!.isNotEmpty) {
      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF818CF8).withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF818CF8).withAlpha(50)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: Color(0xFF818CF8), size: 18),
              const SizedBox(width: 10),
              Expanded(child: RichText(text: TextSpan(children: [
                TextSpan(
                  text: widget.nativeWordName,
                  style: const TextStyle(color: Color(0xFF818CF8),
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: ' is a native Korean word — no Hanja pivot graph available.',
                  style: TextStyle(color: c.textMuted, fontSize: 12),
                ),
              ]))),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Browse Sino-Korean pivots below:',
              style: TextStyle(color: c.textMuted, fontSize: 11)),
        ),
        const SizedBox(height: 8),
        // Fall through to default pivot grid using hardcoded 8 pivots
        Expanded(child: PivotBrowserView(
          focusLens: widget.focusLens,
          dynamicPivots: null, // force default pivots
        )),
      ]);
    }

    final pivots = widget.dynamicPivots ?? kPivots;
    // Ensure _activePivot is in current list (guard after list change)
    final activePivot = pivots.any((p) => p.hanzi == _activePivot.hanzi)
        ? _activePivot
        : pivots.first;
    final async = ref.watch(koreanPivotProvider(activePivot.hanzi));

    return Column(children: [
      // Pivot chip selector
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pivots.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final p      = pivots[i];
              final active = p.hanzi == activePivot.hanzi;
              return GestureDetector(
                onTap: () => setState(() {
                  _activePivot  = p;
                  _selectedId   = null;
                  _cognateId    = null;
                  _selectedNode = null;
                  _page         = 0;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.hanviet.withAlpha(38) : c.surf,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: active ? AppTheme.hanviet : c.border,
                        width: active ? 1.5 : 0.5),
                  ),
                  child: Text('${p.hanzi}/${p.hangul}',
                      style: TextStyle(
                          color: active ? AppTheme.hanviet : c.textMuted,
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 8),

      // Canvas
      Expanded(
        child: async.when(
          loading: () => Center(child: CircularProgressIndicator(
              strokeWidth: 2, color: const Color(0xFF818CF8))),
          error:   (_, _) => Center(child: Text('Error',
              style: TextStyle(color: c.textMuted))),
          data:    (words) {
            if (words.kr.isEmpty) {
              return Center(child: Text('No data for this pivot',
                  style: TextStyle(color: c.textMuted, fontSize: 13)));
            }
            final maxPage = ((max(words.kr.length, words.zh.length) - 1) / kPageSize).floor();
            final page    = _page.clamp(0, maxPage);
              return LayoutBuilder(builder: (ctx, constraints) {
              final size  = Size(constraints.maxWidth, constraints.maxHeight);
              final nodes = buildNodes(activePivot, words.kr, words.zh, size, page: page);

              // Build simplified→id maps for cognate lookup
              final krBySimplified = <String, String>{};
              final zhBySimplified = <String, String>{};
              for (final n in nodes) {
                if (n.word == null) continue;
                if (n.type == KrNodeType.korean)  krBySimplified[n.word!.simplified] = n.id;
                if (n.type == KrNodeType.chinese) zhBySimplified[n.word!.simplified] = n.id;
              }

              return InteractiveViewer(
                transformationController: _transformCtrl,
                constrained: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: GestureDetector(
                onTapUp: (details) {
                  final hit = _hitTest(details.localPosition, nodes);
                  if (hit == null || hit.type == KrNodeType.pivot) return;

                  // Find cognate on the opposite side
                  String? cognate;
                  if (hit.word != null) {
                    if (hit.type == KrNodeType.korean) {
                      cognate = zhBySimplified[hit.word!.simplified];
                    } else if (hit.type == KrNodeType.chinese) {
                      cognate = krBySimplified[hit.word!.simplified];
                    }
                  }

                  setState(() {
                    _selectedId   = hit.id;
                    _cognateId    = cognate;
                    _selectedNode = hit;
                  });
                },
                child: CustomPaint(
                  painter: KoreanGraphPainter(nodes,
                      selectedId: _selectedId,
                      cognateId:  _cognateId,
                      focusLens: widget.focusLens),
                  size: size,
                ),
              ),
              );
            });
          },
        ),
      ),

      // Page navigation buttons (+ / -)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: async.maybeWhen(
          data: (words) {
            final total   = max(words.kr.length, words.zh.length);
            final maxPage = ((total - 1) / kPageSize).floor();
            if (maxPage == 0) return const SizedBox.shrink();
            final page = _page.clamp(0, maxPage);
            return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _PageButton(
                icon: Icons.remove,
                enabled: page > 0,
                onTap: () => setState(() {
                  _page = page - 1;
                  _selectedId = null; _cognateId = null; _selectedNode = null;
                }),
              ),
              const SizedBox(width: 12),
              Text('${page + 1} / ${maxPage + 1}',
                  style: TextStyle(color: c.textMuted, fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              _PageButton(
                icon: Icons.add,
                enabled: page < maxPage,
                onTap: () => setState(() {
                  _page = page + 1;
                  _selectedId = null; _cognateId = null; _selectedNode = null;
                }),
              ),
            ]);
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ),

      // Inspector bar
      if (_selectedNode != null && _selectedNode!.type != KrNodeType.pivot)
        _InspectorBar(
          node: _selectedNode!,
          onActionTap: () {
            final w = _selectedNode!.word;
            if (w == null) return;
            if (_selectedNode!.type == KrNodeType.korean) {
              // KR node → open Korean Dict card
              ref.read(activeKrWordProvider.notifier).set(SearchResult(
                id: w.id, simplified: w.simplified, pinyin: w.pinyin,
                hanViet: w.hanViet, englishDef: w.englishDef,
                hskLevel: w.hskLevel, frequencyRank: w.frequencyRank,
                hangul: w.hangul, romaja: w.romaja, topikLevel: w.topikLevel,
              ));
              ref.read(tabIndexProvider.notifier).set(0);
            } else {
              // ZH node → switch to ZH mode and open that word's graph
              ref.read(langModeProvider.notifier).set(LangMode.chinese);
              if (w.simplified.length == 1) {
                ref.read(activeSymbolProvider.notifier).set(w.simplified);
                ref.read(graphProvider.notifier).setFocal(w.simplified);
              } else {
                ref.read(graphProvider.notifier).setFocalWord(
                    w.simplified, w.simplified.split(''));
              }
              ref.read(tabIndexProvider.notifier).set(1);
            }
          },
        )
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Text('Tap a node to inspect · KR nodes right · ZH nodes left',
              style: TextStyle(color: c.textMuted, fontSize: 10),
              textAlign: TextAlign.center),
        ),
    ]);
  }

  KrNode? _hitTest(Offset pos, List<KrNode> nodes) {
    for (final n in nodes.reversed) {
      if ((pos - n.position).distance <= n.radius + 12) return n;
    }
    return null;
  }
}

// ── Inspector bar ─────────────────────────────────────────────────────────────

class _InspectorBar extends StatelessWidget {
  final KrNode node;
  final VoidCallback onActionTap;
  const _InspectorBar({required this.node, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    final c          = context.colors;
    final isKr       = node.type == KrNodeType.korean;
    // For ZH nodes: subLabel is null (removed from canvas) but show pinyin in inspector
    final displaySub = node.subLabel ?? (node.type == KrNodeType.chinese ? node.word?.pinyin : null);
    final color   = node.color;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80), width: 0.5),
      ),
      child: Row(children: [
        Text(node.label,
            style: TextStyle(color: color, fontSize: 22,
                fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
          Row(children: [
            if (displaySub != null) ...[
              Text(displaySub,
                  style: TextStyle(
                      color: isKr ? const Color(0xFF818CF8) : const Color(0xFF38BDF8),
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
            ],
            if (node.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: color.withAlpha(38),
                    borderRadius: BorderRadius.circular(5)),
                child: Text(node.badge!,
                    style: TextStyle(color: color, fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
          ]),
          if (node.englishDef != null)
            Text(
              node.englishDef!.length > 45
                  ? '${node.englishDef!.substring(0, 45)}…'
                  : node.englishDef!,
              style: TextStyle(color: c.textSub, fontSize: 11),
            ),
        ])),
        TextButton(
          onPressed: onActionTap,
          style: TextButton.styleFrom(
            backgroundColor: color.withAlpha(38),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            node.type == KrNodeType.korean ? 'Dict' : 'Graph',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ── Page navigation button ────────────────────────────────────────────────────

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PageButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF818CF8).withAlpha(38)
              : c.surf,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? const Color(0xFF818CF8).withAlpha(80)
                : c.border,
          ),
        ),
        child: Icon(icon, size: 16,
            color: enabled ? const Color(0xFF818CF8) : c.textMuted),
      ),
    );
  }
}
