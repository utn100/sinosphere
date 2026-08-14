import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class GraphLegend extends StatelessWidget {
  const GraphLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.cardBg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _chip('Biểu ý', AppTheme.semantic),
        const SizedBox(width: 8),
        _chip('Biểu âm', AppTheme.phonetic),
        const SizedBox(width: 8),
        _chip('Tượng hình', AppTheme.iconic),
        const SizedBox(width: 8),
        _chip('Liên quan', AppTheme.sky),
      ]),
    );
  }

  Widget _chip(String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
  ]);
}
