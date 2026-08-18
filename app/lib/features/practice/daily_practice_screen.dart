import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../core/services/database_provider.dart';
import '../../core/services/lang_mode_provider.dart';
import '../../core/theme/app_theme.dart';
import 'stroke_painter.dart';

class DailyPracticeScreen extends ConsumerStatefulWidget {
  const DailyPracticeScreen({super.key});

  @override
  ConsumerState<DailyPracticeScreen> createState() => _DailyPracticeScreenState();
}

class _DailyPracticeScreenState extends ConsumerState<DailyPracticeScreen> {
  static const _sessionSize = 10;

  List<CompoundWord> _words = [];
  List<CompoundWord> _retryQueue = [];
  int _index = 0;
  bool _revealed = false;
  bool _loading = true;
  bool _inRetryRound = false;
  int _correct = 0;
  bool _done = false;

  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;
  double _strokeWidth = 5.0;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final isKorean = ref.read(langModeProvider) == LangMode.korean;
    final words = isKorean
        ? await ref.read(databaseProvider).collectionDao
            .getRandomKrPracticeWords(_sessionSize)
        : await ref.read(databaseProvider).collectionDao
            .getRandomPracticeWords(_sessionSize);
    if (mounted) setState(() { _words = words; _loading = false; });
  }

  CompoundWord get _current => _words[_index];

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

  void _clearCanvas() => setState(() { _strokes.clear(); _currentStroke = null; });

  void _reveal() => setState(() => _revealed = true);

  void _tryAgain() {
    // Stay on same word — just clear canvas and hide the revealed answer
    setState(() { _strokes.clear(); _currentStroke = null; _revealed = false; });
  }

  void _gotIt() => _advanceOrFinish(markCorrect: true, addToRetry: false);

  void _next() => _advanceOrFinish(markCorrect: false, addToRetry: false);

  void _advanceOrFinish({required bool markCorrect, required bool addToRetry}) {
    if (markCorrect) setState(() => _correct++);

    final nextIndex = _index + 1;
    if (nextIndex < _words.length) {
      setState(() {
        _index = nextIndex;
        _revealed = false;
        _strokes.clear();
      });
    } else if (_retryQueue.isNotEmpty) {
      // Start retry round
      setState(() {
        _words = List.from(_retryQueue);
        _retryQueue = [];
        _index = 0;
        _revealed = false;
        _strokes.clear();
        _inRetryRound = true;
      });
    } else {
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strokeColor = isDark ? Colors.white : Colors.black87;
    final guideColor  = isDark ? Colors.white : Colors.black;
    final isKorean = ref.watch(langModeProvider) == LangMode.korean;

    if (_loading) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.hanviet)),
      );
    }

    if (_words.isEmpty) {
      return Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(backgroundColor: c.bg, elevation: 0,
            leading: IconButton(icon: Icon(Icons.close, color: c.text),
                onPressed: () => Navigator.pop(context))),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/logo.png', width: 120, height: 120),
          const SizedBox(height: 16),
          Text('No words to practice yet.\nBookmark some words first!',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textMuted, fontSize: 16)),
        ])),
      );
    }

    if (_done) return _buildSummary(context, c);

    final word = _current;
    final displayChar = isKorean && word.hangul != null ? word.hangul! : word.simplified;
    final guideChar = isKorean && word.hangul != null ? word.hangul! : word.simplified;
    final progressLabel = _inRetryRound
        ? 'Retry ${_index + 1} of ${_words.length}'
        : '${_index + 1} of ${_words.length}';

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
          Text(_inRetryRound ? 'Retry Round' : 'Daily Practice',
              style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w800)),
          Text(progressLabel, style: TextStyle(color: c.textMuted, fontSize: 12)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_index + 1) / _words.length,
            backgroundColor: c.border,
            color: _inRetryRound ? const Color(0xFF818CF8) : AppTheme.hanviet,
          ),
        ),
      ),
      body: Column(children: [
        // Prompt card
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(word.englishDef,
                style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(children: [
              if (!isKorean)
                Text(word.hanViet,
                    style: const TextStyle(color: AppTheme.hanviet,
                        fontSize: 13, fontWeight: FontWeight.w800)),
              if (!isKorean) const SizedBox(width: 8),
              if (!isKorean)
                Text(word.pinyin,
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
              if (isKorean && word.romaja != null) ...[
                Text(word.romaja!,
                    style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12)),
              ],
            ]),
            if (_revealed) ...[
              const SizedBox(height: 6),
              Text(displayChar,
                  style: const TextStyle(color: AppTheme.hanviet,
                      fontSize: 28, fontWeight: FontWeight.w900)),
            ],
          ]),
        ),

        // Canvas — LayoutBuilder caps height so toolbar never overflows
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
                          guideChar: _revealed ? guideChar : '',
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          color: c.bg,
          child: _revealed
              ? Row(children: [
                  // Try again — clear canvas, stay on word
                  Expanded(
                    child: GestureDetector(
                      onTap: _tryAgain,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withAlpha(70)),
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, color: Colors.redAccent, size: 16),
                              SizedBox(width: 4),
                              Text('Try again', style: TextStyle(color: Colors.redAccent,
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                            ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Next — advance without marking correct
                  Expanded(
                    child: GestureDetector(
                      onTap: _next,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: c.surf,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Next', style: TextStyle(color: c.text,
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward, color: c.text, size: 16),
                            ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Got it — mark correct, advance
                  Expanded(
                    child: GestureDetector(
                      onTap: _gotIt,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withAlpha(70)),
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, color: Colors.greenAccent, size: 16),
                              SizedBox(width: 4),
                              Text('Got it', style: TextStyle(color: Colors.greenAccent,
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                            ]),
                      ),
                    ),
                  ),
                ])
              : Row(children: [
                  Icon(Icons.edit, color: c.textMuted, size: 16),
                  Expanded(
                    child: Slider(
                      value: _strokeWidth, min: 2, max: 12,
                      activeColor: AppTheme.hanviet,
                      inactiveColor: c.border,
                      onChanged: (v) => setState(() => _strokeWidth = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _clearCanvas,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: c.surf,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: Text('Clear',
                          style: TextStyle(color: c.text,
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _reveal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.hanviet,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Reveal',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ]),
        ),  // Container
        ),  // SafeArea
      ]),
    );
  }

  Widget _buildSummary(BuildContext context, dynamic c) {
    final pct = (_correct / _sessionSize * 100).clamp(0, 100).round();
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(pct >= 80 ? '🎉' : pct >= 50 ? '💪' : '📚',
                  style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text('$_correct / $_sessionSize',
                  style: TextStyle(color: c.text, fontSize: 48,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('$pct% correct',
                  style: TextStyle(color: c.textMuted, fontSize: 18)),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _index = 0; _correct = 0; _done = false; _inRetryRound = false;
                    _revealed = false; _strokes.clear(); _retryQueue = [];
                    _loading = true;
                  });
                  _loadWords();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.hanviet,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('Practice again',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text('Done', style: TextStyle(color: c.textMuted, fontSize: 16)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
