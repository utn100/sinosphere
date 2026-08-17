import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/services/database_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/dict_card/dict_card_provider.dart';
import '../../../features/dict_card/widgets/word_enrichment.dart';
import '../../../features/dict_card/widgets/bookmark_button.dart';
import '../../../features/shell/app_shell.dart';

final _relatedWordsProvider =
    FutureProvider.family<List<CompoundWord>, (String, String)>((ref, args) async {
  final (wordId, hanViet) = args;
  return ref.read(databaseProvider).graphDao.getRelatedWords(wordId, hanViet);
});

class WordRelationSheet extends ConsumerWidget {
  final CompoundWord word;
  final ScrollController scrollController;

  const WordRelationSheet({
    super.key,
    required this.word,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final related = ref.watch(_relatedWordsProvider((word.id, word.hanViet)));

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),

        // Header — the word itself
        Row(crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
          Text(word.simplified,
              style: TextStyle(color: c.text, fontSize: 32, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Flexible(child: Text(word.hanViet,
              style: const TextStyle(color: AppTheme.hanviet, fontSize: 18,
                  fontWeight: FontWeight.w900))),
        ]),
        Text(word.pinyin,
            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13)),
        const SizedBox(height: 4),
        Text(word.englishDef, style: TextStyle(color: c.textSub, fontSize: 13)),

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
        const SizedBox(height: 20),

        Text('RELATED WORDS',
            style: TextStyle(color: c.textMuted, fontSize: 10,
                fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 8),

        related.when(
          loading: () => const Center(
              child: Padding(padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.hanviet))),
          error: (e, _) => Text('Error loading related words',
              style: TextStyle(color: c.textMuted, fontSize: 12)),
          data: (words) {
            if (words.isEmpty) {
              return Text('No related words found',
                  style: TextStyle(color: c.textMuted, fontSize: 13,
                      fontStyle: FontStyle.italic));
            }
            return Column(
              children: words.map((w) => _RelatedWordRow(
                word: w,
                onTap: () {
                  Navigator.pop(context);
                  _openWordSheet(context, ref, w);
                },
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  void _openWordSheet(BuildContext context, WidgetRef ref, CompoundWord w) {
    if (w.simplified.length == 1) {
      ref.read(activeSymbolProvider.notifier).set(w.simplified);
      ref.read(tabIndexProvider.notifier).set(0);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.9,
          expand: false,
          builder: (_, ctrl) => WordRelationSheet(word: w, scrollController: ctrl),
        ),
      );
    }
  }
}

class _RelatedWordRow extends StatelessWidget {
  final CompoundWord word;
  final VoidCallback onTap;
  const _RelatedWordRow({required this.word, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dot = word.hanVietResonance == 'high'
        ? AppTheme.hanviet
        : word.hanVietResonance == 'medium'
            ? AppTheme.sky
            : c.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: AppTheme.hanviet.withAlpha(20),
                borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Text(
                word.simplified.length > 2 ? word.simplified.substring(0, 2) : word.simplified,
                style: TextStyle(color: c.text,
                    fontSize: word.simplified.length == 1 ? 20 : 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(word.hanViet,
                  style: const TextStyle(color: AppTheme.hanviet, fontSize: 13,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Text(word.pinyin,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
            ]),
            Text(
              word.englishDef.length > 45
                  ? '${word.englishDef.substring(0, 45)}…'
                  : word.englishDef,
              style: TextStyle(color: c.textSub, fontSize: 11),
            ),
          ])),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 5, height: 5,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            if (word.hskLevel != null)
              Text('HSK${word.hskLevel}',
                  style: TextStyle(color: c.textMuted, fontSize: 10)),
          ]),
        ]),
      ),
    );
  }
}
