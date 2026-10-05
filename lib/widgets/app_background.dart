import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Launch field: a moving orbital map that gives every page a recognizable
/// LaunchPad backdrop instead of a generic flat canvas.
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
    _ctrl = AnimationController(vsync: this, duration: AppDurations.orbCycle)
      ..repeat();
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
        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _GridPainter())),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) => CustomPaint(
              painter: _MeshPainter(
                t: _ctrl.value,
                tintColor: widget.tintColor,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.info.withValues(alpha: 0.045)
      ..strokeWidth = 0.65;
    const gap = 34.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.studentPrimary.withValues(alpha: 0.11);
    final anchor = Offset(size.width * 0.86, size.height * 0.13);
    canvas.drawCircle(anchor, 58, orbit);
    canvas.drawCircle(anchor, 102, orbit);
    canvas.drawCircle(anchor, 148, orbit);

    final trajectory = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.businessPrimary.withValues(alpha: 0.10);
    final path = Path()
      ..moveTo(-20, size.height * 0.72)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.46,
        size.width * 0.52,
        size.height * 0.86,
        size.width + 30,
        size.height * 0.48,
      );
    canvas.drawPath(path, trajectory);

    final node = Paint()
      ..color = AppColors.signalYellow.withValues(alpha: 0.55);
    for (final point in [
      Offset(size.width * 0.14, size.height * 0.66),
      Offset(size.width * 0.58, size.height * 0.68),
      anchor,
    ]) {
      canvas.drawCircle(point, 2.3, node);
      canvas.drawCircle(
        point,
        7,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = node.color.withValues(alpha: 0.28),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    _drawOrb(
      canvas,
      Offset(x2, y2),
      w * 0.6,
      tintColor != null
          ? tintColor!.withValues(alpha: 0.07)
          : AppColors.meshAmber,
    );

    final x3 = w * (0.52 + 0.22 * math.sin(t * tau * 1.3 + 1.2));
    final y3 = h * (0.48 + 0.18 * math.cos(t * tau * 0.8 + 2.1));
    _drawOrb(canvas, Offset(x3, y3), w * 0.45, tintColor ?? AppColors.meshCyan);

    final scanY = h * t;
    final scan = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.info.withValues(alpha: 0.11),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 1, w, 2));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 1, w, 2), scan);
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_MeshPainter old) =>
      old.t != t || old.tintColor != tintColor;
}
