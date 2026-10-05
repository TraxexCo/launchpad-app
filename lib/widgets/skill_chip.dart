import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

/// Selectable skill chip using JetBrains Mono.
class SkillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color accentColor;

  const SkillChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.accentColor = AppColors.studentPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.15)
              : AppColors.surfaceHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(4),
          ),
          border: Border.all(
            color: selected
                ? accentColor.withValues(alpha: 0.7)
                : AppColors.border,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 4,
              color: selected ? accentColor : AppColors.textMuted,
            ),
            const SizedBox(width: 7),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                letterSpacing: 0.35,
                fontWeight: FontWeight.w600,
                color: selected ? accentColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
