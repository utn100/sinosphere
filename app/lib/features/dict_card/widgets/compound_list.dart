import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database.dart';
import '../../../core/services/database_provider.dart';
import '../../collections/collections_screen.dart' show bookmarkedSymbolsProvider;

// Per-word bookmark state
final _wordBookmarkProvider = FutureProvider.family<bool, String>((ref, wordId) async {
  return ref.read(databaseProvider).collectionDao.isWordBookmarked(wordId);
});

class CompoundList extends StatelessWidget {
  final List<CompoundWord> compounds;
  final void Function(CompoundWord) onTap;
  const CompoundList({super.key, required this.compounds, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (compounds.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('FREQUENT COMPOUNDS',
                style: TextStyle(color: c.textMuted, fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withAlpha(26),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('${compounds.length} words',
                  style: const TextStyle(color: Color(0xFF38BDF8),
                      fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        ...compounds.asMap().entries.map((e) {
          final i    = e.key;
          final word = e.value;
          return Column(children: [
            if (i > 0) Divider(height: 0.5, thickness: 0.5, color: c.border, indent: 16, endIndent: 16),
            _CompoundRow(word: word, onTap: () => onTap(word)),
          ]);
        }),
        const SizedBox(height: 4),
      ]),
    );
  }
}

class _CompoundRow extends ConsumerWidget {
  final CompoundWord word;
  final VoidCallback onTap;
  const _CompoundRow({required this.word, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c          = context.colors;
    final dot        = AppTheme.resonanceDot(word.hanVietResonance);
    final bookmarked = ref.watch(_wordBookmarkProvider(word.id))
        .when(data: (v) => v, loading: () => false, error: (_, _) => false);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          // Left: simplified + pinyin — constrained so it doesn't push right side off screen
          Expanded(
            flex: 2,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(word.simplified,
                  style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(word.pinyin,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          // Right: HV + definition — also constrained
          Expanded(
            flex: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 5, height: 5,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Flexible(child: Text(word.hanViet,
                    style: const TextStyle(color: AppTheme.hanviet, fontSize: 11,
                        fontWeight: FontWeight.w800),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              Text(
                word.englishDef.length > 30
                    ? '${word.englishDef.substring(0, 30)}…' : word.englishDef,
                style: TextStyle(color: c.textSub, fontSize: 10),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ]),
          ),
          const SizedBox(width: 8),
          // M5: bookmark button on compound rows
          GestureDetector(
            onTap: () async {
              final db = ref.read(databaseProvider);
              await db.collectionDao.toggleWordBookmark(word.id);
              ref.invalidate(_wordBookmarkProvider(word.id));
              ref.invalidate(bookmarkedSymbolsProvider);
            },
            child: Icon(
              bookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: bookmarked ? AppTheme.hanviet : c.textMuted,
              size: 16,
            ),
          ),
        ]),
      ),
    );
  }
}
