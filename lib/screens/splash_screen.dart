import 'package:flutter/material.dart';
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
    final user = await AuthService().getCurrentUser();
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
  Widget build(BuildContext context) => Container(
    width: 68,
    height: 68,
    decoration: BoxDecoration(
      color: AppColors.studentPrimary,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(Icons.north_east_rounded, color: AppColors.ink, size: 34),
  );
}
