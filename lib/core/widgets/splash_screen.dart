import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const SplashScreen({super.key, required this.onAnimationComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;
  late Animation<double> _leafRotation;
  late Animation<double> _leafOpacity;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _cardOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    _cardScale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));

    _leafOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    ));

    _leafRotation = Tween<double>(
      begin: -0.15,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    ));

    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeInOutCubic),
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final cardSize = isMobile ? size.width * 0.55 : 200.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFD8E0D0),
                  Color(0xFFC5D1BC),
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: AnimatedBuilder(
                    animation: _expandAnimation,
                    builder: (context, child) {
                      final expandValue = _expandAnimation.value;
                      final targetSize = size.width * 2.5;
                      final currentSize = cardSize + (targetSize - cardSize) * expandValue;

                      return Transform.scale(
                        scale: _cardScale.value,
                        child: Opacity(
                          opacity: _cardOpacity.value * (1.0 - expandValue * 0.8),
                          child: Container(
                            width: currentSize,
                            height: currentSize,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F0E1),
                              borderRadius: BorderRadius.circular(
                                30.0 * (1.0 - expandValue * 0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08 * (1.0 - expandValue)),
                                  blurRadius: 30 * (1.0 - expandValue * 0.5),
                                  offset: Offset(0, 10 * (1.0 - expandValue * 0.5)),
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  top: -cardSize * 0.15,
                                  right: -cardSize * 0.1,
                                  child: Transform.rotate(
                                    angle: _leafRotation.value,
                                    child: Opacity(
                                      opacity: _leafOpacity.value,
                                      child: CustomPaint(
                                        size: Size(cardSize * 0.45, cardSize * 0.45),
                                        painter: LeafPainter(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_expandAnimation.value > 0.3)
                  Positioned(
                    bottom: size.height * 0.15,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: (_expandAnimation.value - 0.3) / 0.7,
                      child: const Text(
                        'Komorebi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 4,
                          color: Color(0xFF6B7D5E),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFF8FAE7E),
          Color(0xFF6B8F5E),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, h * 0.05);
    path.cubicTo(
      w * 0.85, h * 0.1,
      w * 0.95, h * 0.4,
      w * 0.8, h * 0.7,
    );
    path.cubicTo(
      w * 0.65, h * 0.95,
      w * 0.3, h * 0.95,
      w * 0.15, h * 0.7,
    );
    path.cubicTo(
      w * 0.0, h * 0.4,
      w * 0.15, h * 0.1,
      w * 0.5, h * 0.05,
    );
    path.close();

    canvas.drawPath(path, paint);

    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(w * 0.5, h * 0.1),
      Offset(w * 0.5, h * 0.85),
      veinPaint,
    );

    for (int i = 0; i < 5; i++) {
      final y = h * (0.2 + i * 0.12);
      final leftOffset = w * (0.25 + i * 0.03);
      final rightOffset = w * (0.75 - i * 0.03);
      canvas.drawLine(
        Offset(w * 0.5, y),
        Offset(leftOffset, y - h * 0.04),
        veinPaint,
      );
      canvas.drawLine(
        Offset(w * 0.5, y),
        Offset(rightOffset, y - h * 0.04),
        veinPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
