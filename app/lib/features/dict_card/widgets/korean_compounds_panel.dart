import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/database/daos/compound_dao.dart';
import '../../../core/theme/app_theme.dart';
import '../dict_card_provider.dart';

class KoreanCompoundsPanel extends ConsumerWidget {
  final String hanja;      // simplified Chinese form, e.g. '學校'
  final String excludeId;  // current word's DB id — excluded from results
  final void Function(SearchResult word) onWordTap;

  const KoreanCompoundsPanel({
    super.key,
    required this.hanja,
    required this.excludeId,
    required this.onWordTap,
  });

  static const _krColor = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c       = context.colors;
    final related = ref.watch(
        koreanRelatedProvider((hanja: hanja, excludeId: excludeId)));

    return related.when(
      loading: () => _buildShell(c, child: _shimmerList(c)),
      error:   (_, _) => const SizedBox.shrink(),
      data:    (words) {
        if (words.isEmpty) return const SizedBox.shrink();
        return _buildShell(c, child: Column(
          children: words.map((w) => _CompoundRow(
            word: w, onTap: () => onWordTap(w),
          )).toList(),
        ));
      },
    );
  }

  Widget _buildShell(dynamic c, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('KOREAN COMPOUNDS',
              style: TextStyle(color: c.textMuted, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _krColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('관련 단어',
                style: TextStyle(color: _krColor, fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }

  Widget _shimmerList(dynamic c) {
    return Shimmer.fromColors(
      baseColor: c.surf,
      highlightColor: c.border,
      child: Column(
        children: List.generate(3, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(height: 44, decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10))),
        )),
      ),
    );
  }
}

class _CompoundRow extends StatelessWidget {
  final SearchResult word;
  final VoidCallback onTap;

  const _CompoundRow({required this.word, required this.onTap});

  static const _krColor = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final hangul = word.hangul ?? word.simplified;
    final topik  = word.topikLevel;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(children: [
          // Hangul primary
          SizedBox(
            width: 52,
            child: Text(hangul,
                style: TextStyle(color: c.text, fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          // Romaja + hanja + english
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              if (word.romaja != null) ...[
                Text(word.romaja!,
                    style: const TextStyle(color: _krColor, fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
              ],
              Text(word.simplified,
                  style: const TextStyle(color: AppTheme.hanviet,
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
            Text(
              word.englishDef.length > 45
                  ? '${word.englishDef.substring(0, 45)}…'
                  : word.englishDef,
              style: TextStyle(color: c.textSub, fontSize: 11),
            ),
          ])),
          // TOPIK badge
          if (topik != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: _krColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('T$topik',
                  style: const TextStyle(color: _krColor, fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: c.textMuted, size: 16),
        ]),
      ),
    );
  }
}
