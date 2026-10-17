import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../widgets/app_background.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final startedAt = DateTime.now();
    final user = await AuthService().getCurrentUser();
    final elapsed = DateTime.now().difference(startedAt);
    const minimumDisplay = Duration(milliseconds: 700);
    if (elapsed < minimumDisplay) {
      await Future<void>.delayed(minimumDisplay - elapsed);
    }
    if (!mounted) return;
    context.go(
      user == null
          ? '/onboarding'
          : user.role == 'business'
          ? '/business'
          : '/student',
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: AppBackground(
      tintColor: AppColors.studentPrimary,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LaunchMark(),
            SizedBox(height: 18),
            Text(
              'LaunchPad',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Student talent for local business',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            SizedBox(height: 28),
            SizedBox(width: 120, child: LinearProgressIndicator(minHeight: 3)),
          ],
        ),
      ),
    ),
  );
}

class _LaunchMark extends StatelessWidget {
  const _LaunchMark();

  @override
  Widget build(BuildContext context) =>
      Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderHigh),
            ),
            child: Image.asset(
              'assets/branding/launchpad_mark.png',
              fit: BoxFit.contain,
              semanticLabel: 'LaunchPad logo',
            ),
          )
          .animate()
          .fadeIn(duration: 420.ms)
          .scale(
            begin: const Offset(.88, .88),
            end: const Offset(1, 1),
            curve: Curves.easeOutBack,
            duration: 520.ms,
          );
}
