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
            horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: selected ? accentColor.withValues(alpha: 0.15) : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? accentColor.withValues(alpha: 0.7) : AppColors.border,
            width: 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 8)]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: selected ? accentColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
