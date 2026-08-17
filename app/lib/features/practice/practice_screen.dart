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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
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
                style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 12),
                overflow: TextOverflow.ellipsis)),
          ),
        ],
      ),
      body: Column(children: [
        // Canvas
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(20)),
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
                          guideChar: widget.symbol,
                          strokeWidth: _strokeWidth,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Toolbar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          color: const Color(0xFF0D1117),
          child: Row(children: [
            // Stroke width
            const Icon(Icons.edit, color: Colors.white38, size: 16),
            Expanded(
              child: Slider(
                value: _strokeWidth,
                min: 2, max: 12,
                activeColor: AppTheme.hanviet,
                inactiveColor: Colors.white24,
                onChanged: (v) => setState(() => _strokeWidth = v),
              ),
            ),
            const SizedBox(width: 8),
            // Attempt counter
            if (_attempts > 0)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text('$_attempts×',
                    style: const TextStyle(color: Colors.white38, fontSize: 13)),
              ),
            // Clear
            GestureDetector(
              onTap: _clear,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                ),
                child: const Text('Clear',
                    style: TextStyle(color: Colors.white70,
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 10),
            // Done
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.hanviet.withAlpha(200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Done',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
