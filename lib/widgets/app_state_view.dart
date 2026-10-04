import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';
import 'app_button.dart';

class AppStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color accentColor;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const AppStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.accentColor,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child:
              Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Icon(icon, color: accentColor, size: 34),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.55,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: 220,
                          child: AppButton(
                            label: actionLabel!,
                            icon: actionIcon,
                            onPressed: onAction!,
                            backgroundColor: accentColor,
                          ),
                        ),
                      ],
                    ],
                  )
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .scale(
                    begin: const Offset(0.96, 0.96),
                    curve: Curves.easeOutCubic,
                  ),
        ),
      ),
    );
  }
}

class AppLoadingView extends StatelessWidget {
  final String label;
  final Color color;

  const AppLoadingView({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child:
          Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      color: color,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .fade(begin: 0.65, end: 1, duration: 900.ms),
    );
  }
}
