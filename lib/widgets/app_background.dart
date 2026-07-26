import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Full-screen animated gradient mesh background.
/// Three translucent orbs drift in slow Lissajous-like paths.
class AppBackground extends StatefulWidget {
  final Widget child;
  final Color? tintColor;

  const AppBackground({super.key, required this.child, this.tintColor});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppDurations.orbCycle,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppColors.background),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) => CustomPaint(
              painter: _MeshPainter(t: _ctrl.value, tintColor: widget.tintColor),
              size: Size.infinite,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double t;
  final Color? tintColor;

  const _MeshPainter({required this.t, this.tintColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tau = math.pi * 2;

    final x1 = w * (0.15 + 0.28 * math.sin(t * tau));
    final y1 = h * (0.18 + 0.22 * math.cos(t * tau * 0.7));
    _drawOrb(canvas, Offset(x1, y1), w * 0.7, tintColor ?? AppColors.meshBlue);

    final x2 = w * (0.78 + 0.14 * math.cos(t * tau * 1.1));
    final y2 = h * (0.75 + 0.16 * math.sin(t * tau * 0.9));
    _drawOrb(canvas, Offset(x2, y2), w * 0.6,
        tintColor != null ? tintColor!.withValues(alpha: 0.07) : AppColors.meshAmber);

    final x3 = w * (0.52 + 0.22 * math.sin(t * tau * 1.3 + 1.2));
    final y3 = h * (0.48 + 0.18 * math.cos(t * tau * 0.8 + 2.1));
    _drawOrb(canvas, Offset(x3, y3), w * 0.45, tintColor ?? AppColors.meshCyan);
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.t != t || old.tintColor != tintColor;
}
