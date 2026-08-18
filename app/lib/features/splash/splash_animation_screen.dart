import 'dart:math';
import 'package:flutter/material.dart';
import '../shell/app_shell.dart';

class SplashAnimationScreen extends StatefulWidget {
  const SplashAnimationScreen({super.key});

  @override
  State<SplashAnimationScreen> createState() => _SplashAnimationScreenState();
}

class _SplashAnimationScreenState extends State<SplashAnimationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Magnifying glass sweep: slides from left to right
  late final Animation<Offset> _magSlide;

  // 8 graph nodes illuminate in sequence
  late final List<Animation<double>> _nodeOpacity;

  // Overall image fade-in
  late final Animation<double> _imageFade;

  // Word mark fade in
  late final Animation<double> _wordFade;

  static const _nodeLabelColors = [
    Color(0xFFEF4444), // 語 red
    Color(0xFFF97316), // 學 orange
    Color(0xFFEC4899), // 詞 pink
    Color(0xFF8B5CF6), // 漢 purple
    Color(0xFF22C55E), // 말 green
    Color(0xFF8B5CF6), // 글 purple
    Color(0xFF22D3EE), // 어 teal
    Color(0xFF3B82F6), // 한 blue
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _imageFade = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.0, 0.3, curve: Curves.easeIn)));

    _magSlide = Tween<Offset>(
      begin: const Offset(-0.6, 0),
      end: const Offset(0.6, 0),
    ).animate(CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.05, 0.55, curve: Curves.easeInOut)));

    // Stagger 8 nodes from t=0.2 to t=0.85
    _nodeOpacity = List.generate(8, (i) {
      final start = 0.2 + i * 0.08;
      final end = (start + 0.15).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: Interval(start, end, curve: Curves.easeOut)));
    });

    _wordFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.7, 1.0, curve: Curves.easeIn)));

    _ctrl.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AppShell(),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(fit: StackFit.expand, children: [
        // Background splash image fades in
        FadeTransition(
          opacity: _imageFade,
          child: Image.asset('assets/splashscreen.png',
              fit: BoxFit.contain),
        ),

        // Magnifying glass sweep overlay
        Positioned.fill(
          child: SlideTransition(
            position: _magSlide,
            child: Align(
              alignment: Alignment.center,
              child: Opacity(
                opacity: 0.0, // purely driven by the image; sweep is visual only
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        // Graph node glow dots around the mascot
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return CustomPaint(
              painter: _NodesPainter(
                opacities: _nodeOpacity.map((a) => a.value).toList(),
                colors: _nodeLabelColors,
                center: Offset(size.width / 2, size.height * 0.38),
                radius: size.width * 0.38,
              ),
            );
          },
        ),

        // Wordmark at bottom
        Positioned(
          bottom: size.height * 0.12,
          left: 0, right: 0,
          child: FadeTransition(
            opacity: _wordFade,
            child: Column(children: [
              Text('SINOSPHERE',
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  )),
              const SizedBox(height: 8),
              const Text('Decode Words. Discover Meaning.',
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  )),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _NodesPainter extends CustomPainter {
  final List<double> opacities;
  final List<Color> colors;
  final Offset center;
  final double radius;

  _NodesPainter({required this.opacities, required this.colors,
      required this.center, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < opacities.length; i++) {
      if (opacities[i] <= 0) continue;
      final angle = (i / opacities.length) * 2 * pi - pi / 2;
      final pos = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      // Glow
      final glowPaint = Paint()
        ..color = colors[i].withAlpha((80 * opacities[i]).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(pos, 22, glowPaint);
      // Node ring
      final ringPaint = Paint()
        ..color = colors[i].withAlpha((200 * opacities[i]).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(pos, 18, ringPaint);
      // Connection line to center
      if (i > 0 && opacities[i - 1] > 0) {
        final prevAngle = ((i - 1) / opacities.length) * 2 * pi - pi / 2;
        final prevPos = Offset(
          center.dx + radius * cos(prevAngle),
          center.dy + radius * sin(prevAngle),
        );
        final linePaint = Paint()
          ..color = colors[i].withAlpha((60 * opacities[i]).round())
          ..strokeWidth = 1;
        canvas.drawLine(prevPos, pos, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_NodesPainter old) => true;
}
