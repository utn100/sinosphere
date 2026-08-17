import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/token.dart';
import '../reader_provider.dart';

class AnnotatedText extends StatelessWidget {
  final List<Token> tokens;
  final AnnotationMode mode;
  final void Function(Token) onTokenTap;
  final void Function(Token)? onTokenLongPress;

  const AnnotatedText({
    super.key,
    required this.tokens,
    required this.mode,
    required this.onTokenTap,
    this.onTokenLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      runSpacing: 10,
      alignment: WrapAlignment.start,
      children: tokens.map((t) => t.isCjk
          ? _CjkTokenWidget(
              token: t, mode: mode,
              onTap: () => onTokenTap(t),
              onLongPress: onTokenLongPress != null ? () => onTokenLongPress!(t) : null,
            )
          : _PlainTokenWidget(token: t)).toList(),
    );
  }
}

class _CjkTokenWidget extends StatelessWidget {
  final Token token;
  final AnnotationMode mode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _CjkTokenWidget({
    required this.token, required this.mode,
    required this.onTap, this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final c       = context.colors;
    final showHV  = mode == AnnotationMode.hanviet || mode == AnnotationMode.both;
    final showPY  = mode == AnnotationMode.pinyin  || mode == AnnotationMode.both;

    // In highlight mode: Sino-Korean = amber tint, native Korean = indigo tint, unknown = plain
    final isHighlight = mode == AnnotationMode.romaja;
    Color? highlightColor;
    if (isHighlight && token.isKnown) {
      highlightColor = token.isSinoKorean
          ? AppTheme.hanviet        // amber — Sino-Korean
          : const Color(0xFF818CF8); // indigo — native Korean
    }
    final highlightBg = highlightColor != null ? highlightColor.withAlpha(30) : Colors.transparent;
    final highlightBorder = highlightColor != null
        ? Border.all(color: highlightColor.withAlpha(70), width: 0.5)
        : null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isHighlight ? 3 : 1, vertical: isHighlight ? 2 : 0),
        decoration: isHighlight ? BoxDecoration(
          color: highlightBg,
          borderRadius: BorderRadius.circular(4),
          border: highlightBorder,
        ) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // In highlight mode: no annotation above text — clean reading experience
            if (!isHighlight) ...[
              if (showHV)
                Text(
                  token.hanViet.isEmpty ? '?' : token.hanViet,
                  style: TextStyle(
                    color: token.hanViet.isEmpty ? c.textMuted : AppTheme.hanviet,
                    fontSize: 8, fontWeight: FontWeight.w800,
                    letterSpacing: 0.3, height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
            Text(
              token.text,
              style: TextStyle(
                color: token.isKnown ? c.text : c.textMuted,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            if (!isHighlight && showPY)
              Text(
                token.pinyin.isEmpty ? '' : token.pinyin,
                style: const TextStyle(
                  color: Color(0xFF38BDF8), fontSize: 8, height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class _PlainTokenWidget extends StatelessWidget {
  final Token token;
  const _PlainTokenWidget({required this.token});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(token.text,
          style: TextStyle(color: c.textSub, fontSize: 16, height: 1.8)),
    );
  }
}
