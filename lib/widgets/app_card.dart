import 'package:flutter/material.dart';
import '../core/constants.dart';

/// LaunchPad mission tile with clipped opposing corners and a signal rail.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? accentColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius = AppRadius.lg,
    this.onTap,
    this.width,
    this.height,
    this.backgroundColor,
    this.accentColor,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.only(
      topLeft: Radius.circular(widget.borderRadius * 0.45),
      topRight: Radius.circular(widget.borderRadius * 1.55),
      bottomLeft: Radius.circular(widget.borderRadius * 1.55),
      bottomRight: Radius.circular(widget.borderRadius * 0.45),
    );
    final accent = widget.accentColor ?? AppColors.info;
    final card = AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: shape,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.10),
              blurRadius: 24,
              spreadRadius: -12,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: shape,
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: widget.onTap == null ? null : (_) => _ctrl.forward(),
            onTapUp: widget.onTap == null ? null : (_) => _ctrl.reverse(),
            onTapCancel: widget.onTap == null ? null : () => _ctrl.reverse(),
            splashColor: AppColors.studentPrimary.withValues(alpha: 0.06),
            highlightColor: AppColors.studentPrimary.withValues(alpha: 0.03),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.backgroundColor ?? AppColors.surfaceHigh,
                    widget.backgroundColor ?? AppColors.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 18,
                    child: Container(
                      width: 34,
                      height: 2,
                      color: accent.withValues(alpha: 0.8),
                    ),
                  ),
                  Padding(
                    padding: widget.padding ?? EdgeInsets.zero,
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return card;
  }
}
