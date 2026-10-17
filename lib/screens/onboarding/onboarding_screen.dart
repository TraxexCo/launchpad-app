import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  UserRole? _role;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackground(
      tintColor: AppColors.studentPrimary,
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _role == null ? _rolePicker() : _authChoice(_role!),
        ),
      ),
    ),
  );

  Widget _brand() => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.borderHigh),
        ),
        child: Image.asset(
          'assets/branding/launchpad_mark.png',
          semanticLabel: 'LaunchPad logo',
        ),
      ),
      const SizedBox(width: 10),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LaunchPad',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -.3,
            ),
          ),
          Text(
            'Student talent for local business',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    ],
  );

  Widget _rolePicker() => AppEntrance(
    key: const ValueKey('roles'),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brand(),
          const Spacer(),
          Container(width: 44, height: 3, color: AppColors.studentPrimary),
          const SizedBox(height: 18),
          Text(
            'Work starts closer\nthan you think.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 10),
          const Text(
            'LaunchPad connects student talent with real projects from local businesses.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _roleRow(
            icon: Icons.school_outlined,
            title: 'I am a student',
            description:
                'Find paid projects, submit work, and build a verified portfolio.',
            onTap: () => _select(UserRole.student),
          ),
          const SizedBox(height: 10),
          _roleRow(
            icon: Icons.storefront_outlined,
            title: 'I represent a business',
            description:
                'Post a project, hire student talent, and manage delivery.',
            onTap: () => _select(UserRole.business),
          ),
          const Spacer(flex: 2),
          const Text(
            'Built for classroom demonstration with PayMongo test payments.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );

  Widget _roleRow({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) => Semantics(
    button: true,
    label: title,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 22, color: AppColors.studentPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    ),
  );

  Widget _authChoice(UserRole role) {
    final student = role == UserRole.student;
    final slug = student ? 'student' : 'business';
    return AppEntrance(
      key: const ValueKey('auth'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              tooltip: 'Choose another role',
              onPressed: () => setState(() => _role = null),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const Spacer(),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                student ? Icons.school_outlined : Icons.storefront_outlined,
                size: 28,
                color: AppColors.studentPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              student ? 'Student workspace' : 'Business workspace',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 10),
            Text(
              student
                  ? 'Browse nearby work, send proposals, manage deliverables, and grow your project history.'
                  : 'Publish project needs, compare proposals, fund accepted work, and review delivery.',
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Create $slug account',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: () => context.go('/register?role=$slug'),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Sign in',
              icon: Icons.login_rounded,
              outlined: true,
              foregroundColor: AppColors.studentPrimary,
              onPressed: () => context.go('/login?role=$slug'),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  void _select(UserRole role) {
    HapticFeedback.selectionClick();
    setState(() => _role = role);
  }
}
