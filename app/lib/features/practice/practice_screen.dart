import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'stroke_painter.dart';

class PracticeScreen extends StatefulWidget {
  final String symbol;
  final String pinyin;
  final String hanViet;
  final String englishDef;

  const PracticeScreen({
    super.key,
    required this.symbol,
    required this.pinyin,
    required this.hanViet,
    required this.englishDef,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;
  double _strokeWidth = 5.0;
  int _attempts = 0;
  bool _revealed = false;

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _currentStroke = [d.localPosition];
      _strokes.add(_currentStroke!);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _currentStroke?.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() => _currentStroke = null);
  }

  void _clear() => setState(() { _strokes.clear(); _attempts++; });

  void _toggleReveal() => setState(() => _revealed = !_revealed);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strokeColor = isDark ? Colors.white : Colors.black87;
    final guideColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: c.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.hanViet,
              style: const TextStyle(color: AppTheme.hanviet,
                  fontSize: 16, fontWeight: FontWeight.w800)),
          Text(widget.pinyin,
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(widget.englishDef,
                style: TextStyle(color: c.textMuted, fontSize: 12),
                overflow: TextOverflow.ellipsis)),
          ),
        ],
      ),
      body: Column(children: [
        // Canvas
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final size = min(constraints.maxWidth - 32,
                            constraints.maxHeight - 80).clamp(100.0, 600.0);
            return Center(
              child: SizedBox(
                width: size, height: size,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surf,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        painter: StrokePainter(
                          strokes: _strokes,
                          guideChar: _revealed ? widget.symbol : '',
                          guideColor: guideColor,
                          strokeColor: strokeColor,
                          strokeWidth: _strokeWidth,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        // Toolbar
        SafeArea(
          top: false,
          child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          color: c.bg,
          child: Row(children: [
            Icon(Icons.edit, color: c.textMuted, size: 16),
            Expanded(
              child: Slider(
                value: _strokeWidth,
                min: 2, max: 12,
                activeColor: AppTheme.hanviet,
                inactiveColor: c.border,
                onChanged: (v) => setState(() => _strokeWidth = v),
              ),
            ),
            const SizedBox(width: 8),
            if (_attempts > 0)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text('$_attempts×',
                    style: TextStyle(color: c.textMuted, fontSize: 13)),
              ),
            GestureDetector(
              onTap: _clear,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: c.surf,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Text('Clear',
                    style: TextStyle(color: c.text,
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _toggleReveal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.hanviet,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_revealed ? 'Hide' : 'Reveal',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ]),
        ),  // Container
        ),  // SafeArea
      ]),
    );
  }
}
