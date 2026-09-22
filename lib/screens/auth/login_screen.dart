import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  bool get _isStudent => widget.role == UserRole.student;
  Color get _primary => _isStudent ? AppColors.studentPrimary : AppColors.businessPrimary;

  String get _slug   => _isStudent ? 'student' : 'business';

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    
    try {
      final session = await AuthService().login(_emailCtrl.text, _passCtrl.text);
      if (!mounted) return;
      setState(() => _loading = false);
      context.go(session.role == 'student' ? '/student' : '/business');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $msg'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        tintColor: _primary.withValues(alpha: 0.04),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  GestureDetector(
                    onTap: () => context.canPop() ? context.pop() : context.go('/onboarding'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, color: _primary, size: 14),
                        const SizedBox(width: 4),
                        Text('Back', style: GoogleFonts.inter(color: _primary, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: AppSpacing.xxl),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: _primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _isStudent ? '// student.signin' : '// business.signin',
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: _primary),
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: AppSpacing.md),

                  Text('Welcome\nback.', style: Theme.of(context).textTheme.displaySmall)
                      .animate().fadeIn(duration: 500.ms, delay: 100.ms)
                      .slideY(begin: 0.2, duration: 500.ms, delay: 100.ms, curve: Curves.easeOutCubic),

                  const SizedBox(height: AppSpacing.sm),

                  Text('Sign in to continue where you left off.', style: Theme.of(context).textTheme.bodyMedium)
                      .animate().fadeIn(duration: 400.ms, delay: 220.ms),

                  const SizedBox(height: AppSpacing.xxl),

                  AppTextField(
                    label: 'Email', hint: 'you@example.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    accentColor: _primary,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icon(Icons.alternate_email_rounded, color: AppColors.textMuted, size: 18),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ).animate().fadeIn(duration: 400.ms, delay: 320.ms),

                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    label: 'Password', controller: _passCtrl,
                    obscureText: true, accentColor: _primary,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 18),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

                  const SizedBox(height: AppSpacing.md),

                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        final resetCtrl = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('Reset Password', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                            content: Text('Enter your email and we will send you a reset link.', style: GoogleFonts.inter(fontSize: 14)),
                            actions: [
                              TextField(
                                controller: resetCtrl,
                                decoration: InputDecoration(
                                  hintText: 'your@email.com',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await AuthService().resetPassword(resetCtrl.text);
                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Check your email for a reset link.'), backgroundColor: AppColors.success),
                                        );
                                      } catch (error) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('$error'), backgroundColor: AppColors.error),
                                        );
                                      }
                                    },
                                    child: const Text('Send Link'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text('Forgot password?',
                          style: GoogleFonts.inter(fontSize: 13, color: _primary, fontWeight: FontWeight.w500)),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 460.ms),

                  const SizedBox(height: AppSpacing.xl),

                  AppButton(
                    label: 'Sign In',
                    isLoading: _loading,
                    onPressed: _submit,
                  ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 520.ms).fadeIn(delay: 520.ms),

                  const SizedBox(height: AppSpacing.xl),

                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text('or', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 600.ms),

                  const SizedBox(height: AppSpacing.xl),

                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/register?role=$_slug'),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Create one',
                              style: GoogleFonts.inter(color: _primary, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 650.ms),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


