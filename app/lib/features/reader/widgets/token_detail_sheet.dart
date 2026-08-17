import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/lang_mode_provider.dart';
import '../../dict_card/dict_card_provider.dart';
import '../../dict_card/widgets/word_enrichment.dart';
import '../../dict_card/widgets/bookmark_button.dart';
import '../../shell/app_shell.dart';
import '../models/token.dart';

class TokenDetailSheet extends ConsumerWidget {
  final Token token;
  final ScrollController scrollController;

  const TokenDetailSheet({
    super.key, required this.token, required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c        = context.colors;
    final chars    = token.text.split('');
    final isKorean = ref.watch(langModeProvider) == LangMode.korean;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),

        // Hero text
        Text(token.text,
            style: TextStyle(color: c.text, fontSize: 48,
                fontWeight: FontWeight.w700, height: 1.1)),
        const SizedBox(height: 12),

        if (isKorean) ...[
          // Romaja (indigo)
          if (token.romaja != null)
            Text(token.romaja!,
                style: const TextStyle(color: Color(0xFF818CF8), fontSize: 20,
                    fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          // Tappable hanja character chips — only for Sino-Korean tokens
          if (token.simplified != null && token.simplified != token.text) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text('Hanja  ', style: TextStyle(color: c.textMuted, fontSize: 11,
                  fontWeight: FontWeight.w600)),
              ...token.simplified!.split('').map((ch) => GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  ref.read(langModeProvider.notifier).set(LangMode.chinese);
                  ref.read(activeSymbolProvider.notifier).set(ch);
                  ref.read(tabIndexProvider.notifier).set(0);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.hanviet.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.hanviet.withAlpha(80)),
                  ),
                  child: Text(ch, style: const TextStyle(
                      color: AppTheme.hanviet, fontSize: 24, fontWeight: FontWeight.w700)),
                ),
              )),
            ]),
          ],
        ] else ...[
          // HV + pinyin (Chinese mode)
          Row(crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic, children: [
            Flexible(child: Text(token.hanViet,
                style: const TextStyle(color: AppTheme.hanviet, fontSize: 20,
                    fontWeight: FontWeight.w900, letterSpacing: 1),
                softWrap: true)),
            const SizedBox(width: 12),
            Flexible(child: Text(token.pinyin,
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 14))),
          ]),
          // Tappable character row
          const SizedBox(height: 8),
          Wrap(
            spacing: 4, runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: chars.map((ch) => GestureDetector(
              onTap: () {
                Navigator.pop(context);
                ref.read(activeSymbolProvider.notifier).set(ch);
                ref.read(tabIndexProvider.notifier).set(0);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8), color: Colors.transparent),
                child: Text(ch, style: TextStyle(
                    color: c.text, fontSize: 36, fontWeight: FontWeight.w700, height: 1.1)),
              ),
            )).toList(),
          ),
        ],
        const SizedBox(height: 8),

        Text(token.englishDef,
            style: TextStyle(color: c.text, fontSize: 14, height: 1.5)),

        if (token.wordId != null) ...[
          const SizedBox(height: 10),
          BookmarkButton(wordId: token.wordId!),
          WordEnrichmentSection(
            wordId:     token.wordId!,
            simplified: token.text,
            pinyin:     token.pinyin,
            englishDef: token.englishDef,
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
              isKorean
                  ? 'Tap a Hanja character above to open its Chinese dictionary'
                  : 'Tap any character above to open its dictionary card',
              style: TextStyle(color: c.textMuted, fontSize: 11),
            )),
          ]),
        ),
      ],
    );
  }
}
