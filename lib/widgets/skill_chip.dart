import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

/// Compact, accessible skill selector.
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
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.15)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? accentColor.withValues(alpha: 0.7)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? accentColor : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
