import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../widgets/app_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.studentPrimary, AppColors.studentAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.studentPrimary.withValues(alpha: 0.45),
                      blurRadius: 40,
                    ),
                    BoxShadow(
                      color: AppColors.studentAccent.withValues(alpha: 0.2),
                      blurRadius: 80,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 38),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: AppSpacing.lg),

              // Wordmark
              Text(
                'LaunchPad',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -2,
                ),
              )
                  .animate()
                  .slideY(begin: 0.4, duration: 600.ms, delay: 250.ms, curve: Curves.easeOutCubic)
                  .fadeIn(duration: 500.ms, delay: 250.ms),

              const SizedBox(height: AppSpacing.sm),

              // Mono tagline
              Text(
                '// where code meets commerce',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 650.ms),

              const SizedBox(height: AppSpacing.xxxl),

              // Loading bar
              SizedBox(
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: const LinearProgressIndicator(
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.studentPrimary),
                    minHeight: 2,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 900.ms),
            ],
          ),
        ),
      ),
    );
  }
}
