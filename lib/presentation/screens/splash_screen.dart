import 'dart:math';
import 'package:flutter/material.dart';

class AetherisSplashScreen extends StatefulWidget {
  const AetherisSplashScreen({super.key});

  @override
  State<AetherisSplashScreen> createState() => _AetherisSplashScreenState();
}

class _AetherisSplashScreenState extends State<AetherisSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;
  late final AnimationController _rotateController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0221),
              Color(0xFF150734),
              Color(0xFF1A0A3E),
              Color(0xFF0D0221),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: CustomPaint(
                    size: Size(
                      MediaQuery.of(context).size.width * 0.7,
                      MediaQuery.of(context).size.width * 0.7,
                    ),
                    painter: _OrbitalRingsPainter(),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.6),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                          blurRadius: 80,
                          spreadRadius: 30,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF7C4DFF),
                    Color(0xFF448AFF),
                    Color(0xFF00E5FF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.8),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 40,
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.3,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF7C4DFF),
                          Color(0xFF00E5FF),
                          Color(0xFF7C4DFF),
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'AETHERIS',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'INTELLIGENT SECURITY SYSTEM',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 6,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF7C4DFF).withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ),
            ...List.generate(20, (index) {
              final random = Random(index);
              final size = random.nextDouble() * 3 + 1;
              final top = random.nextDouble() *
                  MediaQuery.of(context).size.height;
              final left = random.nextDouble() *
                  MediaQuery.of(context).size.width;
              return Positioned(
                top: top,
                left: left,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: random.nextDouble() * 0.3 + 0.1,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _OrbitalRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    paint.shader = const LinearGradient(
      colors: [Color(0xFF7C4DFF), Color(0xFF00E5FF)],
    ).createShader(
      Rect.fromCircle(center: center, radius: size.width / 2),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.9,
        height: size.height * 0.4,
      ),
      paint,
    );

    paint.shader = const LinearGradient(
      colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
    ).createShader(
      Rect.fromCircle(center: center, radius: size.width / 2),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.5,
        height: size.height * 0.8,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
