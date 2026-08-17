import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'models/graph_data.dart';
import 'models/graph_node.dart';
import 'models/graph_edge.dart';

class GraphPainter extends CustomPainter {
  final GraphData graph;
  final String? selectedId;

  GraphPainter(this.graph, {this.selectedId});

  @override
  void paint(Canvas canvas, Size size) {
    _drawEdges(canvas);
    _drawNodes(canvas);
  }

  void _drawEdges(Canvas canvas) {
    final nodeMap = {for (final n in graph.nodes) n.id: n};
    for (final edge in graph.edges) {
      final from = nodeMap[edge.fromId];
      final to   = nodeMap[edge.toId];
      if (from == null || to == null) continue;

      final color = _edgeColor(edge.type, from);
      final paint = Paint()
        ..color = color.withAlpha(100)
        ..strokeWidth = edge.type == GraphEdgeType.decomposition ? 1.5 : 1.0
        ..style = PaintingStyle.stroke;

      if (edge.type == GraphEdgeType.sibling) {
        // Dashed line
        _drawDashed(canvas, from.position, to.position, paint);
      } else {
        canvas.drawLine(from.position, to.position, paint);
      }
    }
  }

  void _drawNodes(Canvas canvas) {
    for (final node in graph.nodes) {
      _drawNode(canvas, node);
    }
  }

  void _drawNode(Canvas canvas, GraphNode node) {
    final isSelected = node.id == selectedId;
    final color = _nodeColor(node);
    final r = node.radius;

    // Fill
    canvas.drawCircle(node.position, r,
        Paint()..color = color.withAlpha(node.type == GraphNodeType.compound ? 38 : 200));

    // Border
    canvas.drawCircle(node.position, r,
        Paint()
          ..color = isSelected ? Colors.white : color
          ..strokeWidth = isSelected ? 2.5 : 1.2
          ..style = PaintingStyle.stroke);

    // Label (symbol)
    final fontSize = switch (node.type) {
      GraphNodeType.focal    => 22.0,
      GraphNodeType.root     => 22.0,
      GraphNodeType.component => 16.0,
      GraphNodeType.sibling  => 13.0,
      GraphNodeType.compound => 10.0,
      GraphNodeType.showMore => 10.0,
    };

    final tp = TextPainter(
      text: TextSpan(
        text: node.label,
        style: TextStyle(
          color: node.type == GraphNodeType.compound ? color : Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, node.position - Offset(tp.width / 2, tp.height / 2));

    // Sub-labels below node (HV + pinyin) — skip for compound/showMore chips
    if (node.type != GraphNodeType.compound && node.type != GraphNodeType.showMore) {      var offset = r + 3.0;

      if (node.subLabel != null) {
        final sub = TextPainter(
          text: TextSpan(
            text: node.subLabel,
            style: TextStyle(color: AppTheme.hanviet, fontSize: fontSize * 0.55,
                fontWeight: FontWeight.w800),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        sub.paint(canvas, node.position + Offset(-sub.width / 2, offset));
        offset += sub.height + 1;
      }

      if (node.pinyin != null) {
        final py = TextPainter(
          text: TextSpan(
            text: node.pinyin,
            style: TextStyle(color: const Color(0xFF38BDF8), fontSize: fontSize * 0.50),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        py.paint(canvas, node.position + Offset(-py.width / 2, offset));
      }
    }
  }

  void _drawDashed(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashLen = 5.0;
    const gapLen  = 4.0;
    final total = (p2 - p1).distance;
    final dir   = (p2 - p1) / total;
    var d = 0.0;
    while (d < total) {
      final start = p1 + dir * d;
      final end   = p1 + dir * (d + dashLen).clamp(0, total);
      canvas.drawLine(start, end, paint);
      d += dashLen + gapLen;
    }
  }

  Color _nodeColor(GraphNode node) {
    switch (node.type) {
      case GraphNodeType.focal:    return AppTheme.coral;    // brand primary
      case GraphNodeType.root:     return AppTheme.sky;
      case GraphNodeType.sibling:  return AppTheme.sky;
      case GraphNodeType.compound: return AppTheme.hanviet;  // amber — ZH compounds
      case GraphNodeType.showMore: return AppTheme.textSecond;
      case GraphNodeType.component:
        switch (node.componentType) {
          case 'semantic': return AppTheme.semantic;
          case 'phonetic': return AppTheme.phonetic;
          case 'iconic':   return AppTheme.iconic;
          default:         return AppTheme.textSecond;
        }
    }
  }

  Color _edgeColor(GraphEdgeType type, GraphNode from) {
    switch (type) {
      case GraphEdgeType.decomposition: return _nodeColor(from);
      case GraphEdgeType.sibling:       return AppTheme.sky;
      case GraphEdgeType.compound:      return AppTheme.hanviet;
    }
  }

  @override
  bool shouldRepaint(GraphPainter old) =>
      old.graph != graph || old.selectedId != selectedId;
}
