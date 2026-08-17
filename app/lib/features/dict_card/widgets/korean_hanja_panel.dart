import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../dict_card_provider.dart';

class KoreanHanjaPanel extends ConsumerWidget {
  final String hanja;   // e.g. '學校'
  final String hangul;  // e.g. '학교'
  final void Function(String symbol) onHanjaTap;

  const KoreanHanjaPanel({
    super.key,
    required this.hanja,
    required this.hangul,
    required this.onHanjaTap,
  });

  static const _krColor = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c          = context.colors;
    final hanjaChars = hanja.split('');
    final hangulChars = hangul.split('');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('HANJA ANALYSIS',
              style: TextStyle(color: c.textMuted, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _krColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('한자 분석',
                style: TextStyle(color: _krColor, fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        ...List.generate(hanjaChars.length, (i) {
          final symbol  = hanjaChars[i];
          final syllable = i < hangulChars.length ? hangulChars[i] : '';
          return _HanjaTile(
            symbol:   symbol,
            syllable: syllable,
            onTap:    () => onHanjaTap(symbol),
            ref:      ref,
          );
        }),
      ]),
    );
  }
}

class _HanjaTile extends ConsumerWidget {
  final String symbol;
  final String syllable;
  final VoidCallback onTap;
  final WidgetRef ref;

  const _HanjaTile({
    required this.symbol,
    required this.syllable,
    required this.onTap,
    required this.ref,
  });

  static const _krColor = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final c       = context.colors;
    final detail  = ref.watch(characterDetailProvider(symbol));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.surf,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.hanviet.withAlpha(50), width: 0.5),
          ),
          child: Row(children: [
            // Hanja glyph — tappable
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppTheme.hanviet.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.hanviet.withAlpha(80)),
              ),
              child: Center(
                child: Text(symbol,
                    style: const TextStyle(color: AppTheme.hanviet, fontSize: 26,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: detail.when(
              loading: () => Container(height: 14, width: 120,
                  decoration: BoxDecoration(color: c.border,
                      borderRadius: BorderRadius.circular(4))),
              error: (_, _) => Text(symbol,
                  style: TextStyle(color: c.textMuted, fontSize: 13)),
              data: (d) {
                if (d == null) {
                  return Text(symbol,
                      style: TextStyle(color: c.textMuted, fontSize: 13));
                }
                final char = d.character;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    // Hangul syllable
                    Text(syllable,
                        style: const TextStyle(color: _krColor, fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    // HanViet reading
                    Text(char.hanViet,
                        style: TextStyle(color: c.textMuted, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text(char.pinyin,
                        style: const TextStyle(color: Color(0xFF38BDF8),
                            fontSize: 11)),
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    char.englishDef.length > 55
                        ? '${char.englishDef.substring(0, 55)}…'
                        : char.englishDef,
                    style: TextStyle(color: c.text, fontSize: 12, height: 1.3),
                  ),
                  if (d.components.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Wrap(spacing: 4, runSpacing: 4,
                        children: d.components.take(3).map((comp) {
                      final isPhonetic = comp.componentType == 'phonetic';
                      final color = isPhonetic
                          ? const Color(0xFF38BDF8)
                          : AppTheme.semantic;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withAlpha(26),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${comp.component.symbol} ${isPhonetic ? "phon." : "sem."}',
                          style: TextStyle(color: color, fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      );
                    }).toList()),
                  ],
                ]);
              },
            )),
            const Icon(Icons.open_in_new, size: 14, color: AppTheme.hanviet),
          ]),
        ),
      ),
    );
  }
}
