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
  late final Animation<double> _wordFade;
  late final List<Animation<double>> _nodeOpacity;

  static const _colors = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF22C55E),
    Color(0xFF8B5CF6),
    Color(0xFF22D3EE),
    Color(0xFF3B82F6),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _nodeOpacity = List.generate(8, (i) {
      final start = 0.1 + i * 0.07;
      final end = (start + 0.2).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: Interval(start, end, curve: Curves.easeOut)));
    });

    _wordFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.65, 0.95, curve: Curves.easeIn)));

    _ctrl.forward();

    // Navigate after fixed delay — don't rely on animation completion
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AppShell(),
            transitionDuration: const Duration(milliseconds: 500),
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
        // Splash image — always visible immediately
        Image.asset('assets/splashscreen.png', fit: BoxFit.contain),

        // Animated graph nodes
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            painter: _NodesPainter(
              opacities: _nodeOpacity.map((a) => a.value).toList(),
              colors: _colors,
              center: Offset(size.width / 2, size.height * 0.37),
              radius: size.width * 0.37,
            ),
          ),
        ),

        // Wordmark fade in
        Positioned(
          bottom: size.height * 0.10,
          left: 0, right: 0,
          child: FadeTransition(
            opacity: _wordFade,
            child: const Column(children: [
              Text('SINOSPHERE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  )),
              SizedBox(height: 8),
              Text('Decode Words. Discover Meaning.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
      if (opacities[i] <= 0.01) continue;
      final angle = (i / opacities.length) * 2 * pi - pi / 2;
      final pos = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      // Glow
      canvas.drawCircle(pos, 22, Paint()
        ..color = colors[i].withAlpha((80 * opacities[i]).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      // Ring
      canvas.drawCircle(pos, 18, Paint()
        ..color = colors[i].withAlpha((220 * opacities[i]).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
      // Line to previous node
      if (i > 0 && opacities[i - 1] > 0.01) {
        final prevAngle = ((i - 1) / opacities.length) * 2 * pi - pi / 2;
        final prevPos = Offset(
          center.dx + radius * cos(prevAngle),
          center.dy + radius * sin(prevAngle),
        );
        canvas.drawLine(prevPos, pos, Paint()
          ..color = colors[i].withAlpha((60 * opacities[i]).round())
          ..strokeWidth = 1.5);
      }
    }
  }

  @override
  bool shouldRepaint(_NodesPainter old) => opacities != old.opacities;
}
