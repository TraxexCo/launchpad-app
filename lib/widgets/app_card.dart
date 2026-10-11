import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Restrained content group. State colors belong to content inside the card.
class AppCard extends StatelessWidget {
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
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: onTap == null
            ? null
            : const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: backgroundColor ?? AppColors.surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    ),
  );
}
