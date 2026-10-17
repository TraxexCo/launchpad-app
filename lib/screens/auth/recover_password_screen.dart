import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../core/form_validation.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Password-recovery screen. Lets the user choose a new password after
/// opening a Supabase email recovery link.
class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  bool _showConfirm = false;

  /// Zxcvbn-style 0-4 strength score based on simple heuristics.
  int get _strength {
    final value = _password.text;
    var score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score;
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AuthService().updateRecoveredPassword(_password.text);
      final user = await AuthService().getCurrentUser();
      if (!mounted) return;
      context.go(user?.role == 'business' ? '/business' : '/student');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update password: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const strengthLabels = ['Very weak', 'Weak', 'Good', 'Strong', 'Excellent'];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.violet.withValues(alpha: 0.06),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: AppColors.studentPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Secure your account',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Choose a password you do not use anywhere else.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // ── Password field ─────────────────────────────
                      AppTextField(
                        label: 'New password',
                        controller: _password,
                        obscureText: !_showPassword,
                        onChanged: (_) => setState(() {}),
                        prefixIcon: const Icon(Icons.password_rounded),
                        suffixIcon: IconButton(
                          tooltip: _showPassword
                              ? 'Hide password'
                              : 'Show password',
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                        validator: FormValidation.strongPassword,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // ── Strength meter ─────────────────────────────
                      Row(
                        children: List.generate(
                          4,
                          (index) => Expanded(
                            child: AnimatedContainer(
                              duration: AppDurations.fast,
                              height: 4,
                              margin: EdgeInsets.only(
                                right: index == 3 ? 0 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: index < _strength
                                    ? (_strength < 3
                                          ? AppColors.warning
                                          : AppColors.success)
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        strengthLabels[_strength],
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // ── Confirm password ───────────────────────────
                      AppTextField(
                        label: 'Confirm password',
                        controller: _confirm,
                        obscureText: !_showConfirm,
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                        suffixIcon: IconButton(
                          tooltip: _showConfirm
                              ? 'Hide password'
                              : 'Show password',
                          onPressed: () =>
                              setState(() => _showConfirm = !_showConfirm),
                          icon: Icon(
                            _showConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                        validator: (value) => value != _password.text
                            ? 'Passwords do not match.'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: 'Update password',
                        icon: Icons.shield_outlined,
                        isLoading: _busy,
                        onPressed: _save,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'You will return to your dashboard after the password is saved.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
