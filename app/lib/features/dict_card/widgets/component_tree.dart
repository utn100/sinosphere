import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database.dart';

class ComponentTree extends StatelessWidget {
  final List<ComponentWithType> components;
  final String decomposition;
  const ComponentTree({super.key, required this.components, required this.decomposition});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('STRUCTURAL DECOMPOSITION',
              style: TextStyle(color: c.textMuted, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: AppTheme.semantic.withAlpha(26),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('Chiết Tự',
                style: TextStyle(color: AppTheme.semantic, fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        if (decomposition.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(decomposition,
              style: TextStyle(color: c.textMuted, fontSize: 11,
                  fontFamily: 'monospace')),
        ],
        const SizedBox(height: 12),
        if (components.isEmpty)
          Text('No component data available',
              style: TextStyle(color: c.textMuted, fontSize: 13))
        else
          ...components.map((comp) => _ComponentRow(comp: comp)),
      ]),
    );
  }
}

class _ComponentRow extends StatelessWidget {
  final ComponentWithType comp;
  const _ComponentRow({required this.comp});

  @override
  Widget build(BuildContext context) {
    final c   = context.colors;
    final type = comp.componentType ?? 'semantic';
    final col  = AppTheme.componentColor(type);
    final bg   = AppTheme.componentBg(type);
    final lbl  = AppTheme.componentLabel(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surf, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border, width: 0.3),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: col.withAlpha(102), width: 1)),
            child: Center(child: Text(comp.component.symbol,
                style: TextStyle(color: col, fontSize: 22, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(comp.component.pinyin,
                  style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              if (comp.component.hanViet.isNotEmpty)
                Text(comp.component.hanViet,
                    style: const TextStyle(color: AppTheme.hanviet, fontSize: 12,
                        fontWeight: FontWeight.w800)),
            ]),
            Text(
              comp.component.englishDef,
              style: TextStyle(color: c.textSub, fontSize: 11),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
            child: Text(lbl,
                style: TextStyle(color: col, fontSize: 9, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    );
  }
}
