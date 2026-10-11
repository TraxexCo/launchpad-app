import 'package:flutter/material.dart';
import '../core/constants.dart';

/// LaunchPad's stable graphite canvas and slim wayfinding rail.
class AppBackground extends StatelessWidget {
  final Widget child;
  final Color? tintColor;
  const AppBackground({super.key, required this.child, this.tintColor});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF141316), AppColors.background],
        stops: [0, .42],
      ),
    ),
    child: Stack(
      children: [
        if (tintColor != null)
          const Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: 230,
            child: IgnorePointer(
              child: CustomPaint(painter: _BlueprintPainter()),
            ),
          ),
        if (tintColor != null)
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _WayfindingRail(),
          ),
        Positioned.fill(child: child),
      ],
    ),
  );
}

class _BlueprintPainter extends CustomPainter {
  const _BlueprintPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fine = Paint()
      ..color = AppColors.border.withValues(alpha: .28)
      ..strokeWidth = .5;
    for (double x = 24; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), fine);
    }
    for (double y = 18; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), fine);
    }
    final route = Paint()
      ..color = AppColors.studentPrimary.withValues(alpha: .22)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * .64, 0)
      ..lineTo(size.width * .64, 52)
      ..lineTo(size.width * .82, 52)
      ..lineTo(size.width * .82, 116)
      ..lineTo(size.width, 116);
    canvas.drawPath(path, route);
    canvas.drawCircle(
      Offset(size.width * .82, 52),
      3,
      Paint()..color = AppColors.studentPrimary.withValues(alpha: .55),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WayfindingRail extends StatelessWidget {
  const _WayfindingRail();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 3,
    child: Column(
      children: [
        const SizedBox(height: 88),
        Container(height: 42, color: AppColors.studentPrimary),
        Expanded(child: Container(color: AppColors.border)),
      ],
    ),
  );
}

/// A short route entrance used only for primary page compositions.
class AppEntrance extends StatelessWidget {
  final Widget child;
  const AppEntrance({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}
