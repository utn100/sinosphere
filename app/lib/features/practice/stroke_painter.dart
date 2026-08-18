import 'package:flutter/material.dart';

class StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final String guideChar;
  final Color strokeColor;
  final Color guideColor;
  final double strokeWidth;

  StrokePainter({
    required this.strokes,
    required this.guideChar,
    required this.guideColor,
    this.strokeColor = Colors.white,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Guide character — scale font size by character count so multi-char words fit
    if (guideChar.isNotEmpty) {
      final charCount = guideChar.length.clamp(1, 6);
      final fontSize = (size.width * 0.68) / charCount;
      final tp = TextPainter(
        text: TextSpan(
          text: guideChar,
          style: TextStyle(
            fontSize: fontSize,
            color: guideColor.withAlpha(18),
            fontWeight: FontWeight.w400,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      final offset = Offset(
        (size.width - tp.width) / 2,
        (size.height - tp.height) / 2,
      );
      tp.paint(canvas, offset);
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = guideColor.withAlpha(20)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), gridPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), gridPaint);
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), gridPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), gridPaint);

    // User strokes
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, strokeWidth / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length - 1; i++) {
        final mid = Offset(
          (stroke[i].dx + stroke[i + 1].dx) / 2,
          (stroke[i].dy + stroke[i + 1].dy) / 2,
        );
        path.quadraticBezierTo(stroke[i].dx, stroke[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(stroke.last.dx, stroke.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(StrokePainter old) => true; // always repaint — list is mutated in place
}
