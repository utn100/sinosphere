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
    final c = context.colors;
    final showHV = mode == AnnotationMode.hanviet || mode == AnnotationMode.both;
    final showPY = mode == AnnotationMode.pinyin  || mode == AnnotationMode.both;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            // Fix 4: uniform fontSize 20 for all CJK tokens
            Text(
              token.text,
              style: TextStyle(
                color: token.isKnown ? c.text : c.textMuted,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            if (showPY)
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
