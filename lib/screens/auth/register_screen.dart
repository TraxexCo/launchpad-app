import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/skill_chip.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  final UserRole role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentStep = 0;

  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _bioCtrl     = TextEditingController();
  final _githubCtrl  = TextEditingController();
  final _bizNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final Set<String> _selectedSkills = {};
  bool _loading = false;

  bool get _isStudent => widget.role == UserRole.student;
  Color get _primary  => _isStudent ? AppColors.studentPrimary : AppColors.businessPrimary;
  static const int _totalSteps = 3;

  final List<GlobalKey<FormState>> _formKeys =
      List.generate(3, (_) => GlobalKey<FormState>());

  @override
  void dispose() {
    _pageCtrl.dispose(); _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _bioCtrl.dispose(); _githubCtrl.dispose();
    _bizNameCtrl.dispose(); _addressCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_formKeys[_currentStep].currentState!.validate()) return;
    if (_currentStep < _totalSteps - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    // Clear validation state so errors don't linger on the previous step
    _formKeys[_currentStep].currentState?.reset();
    if (_currentStep > 0) {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
      setState(() => _currentStep--);
    } else {
      context.go('/onboarding');
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    
    try {
      final role = _isStudent ? 'student' : 'business';
      final extraFields = _isStudent ? {
        'bio': _bioCtrl.text,
        'github_url': _githubCtrl.text,
        'skills': _selectedSkills.toList(),
      } : {
        'business_name': _bizNameCtrl.text,
        'location': _addressCtrl.text,
      };

      final confirmationRequired = await AuthService().register(
        role: role,
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
        extraFields: extraFields,
      );

      if (!mounted) return;
      setState(() => _loading = false);
      if (confirmationRequired) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Check your email to confirm your account, then sign in.'),
        ));
        context.go('/login?role=$role');
      } else {
        context.go(role == 'student' ? '/student' : '/business');
      }
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
          child: Column(
            children: [
              _StepHeader(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
                accentColor: _primary,
                roleLabel: _isStudent ? '// student.register' : '// business.register',
                onBack: _prevStep,
              ),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep(
                      formKey: _formKeys[0],
                      title: 'Create your\naccount.',
                      subtitle: 'Your login credentials.',
                      child: _AccountStep(nameCtrl: _nameCtrl, emailCtrl: _emailCtrl, passCtrl: _passCtrl, accentColor: _primary, isStudent: _isStudent),
                    ),
                    _buildStep(
                      formKey: _formKeys[1],
                      title: _isStudent ? 'Tell us\nabout you.' : 'Your business\ndetails.',
                      subtitle: _isStudent ? 'Your public developer profile.' : 'How clients will find you.',
                      child: _isStudent
                          ? _StudentProfileStep(bioCtrl: _bioCtrl, githubCtrl: _githubCtrl, accentColor: _primary)
                          : _BusinessProfileStep(bizNameCtrl: _bizNameCtrl, addressCtrl: _addressCtrl, accentColor: _primary),
                    ),
                    _buildStep(
                      formKey: _formKeys[2],
                      title: _isStudent ? 'Your tech\nstack.' : 'Your business\naccount.',
                      subtitle: _isStudent ? 'Pick all skills that apply.' : 'Verification can be submitted after signup.',
                      child: _isStudent
                          ? _SkillsStep(selected: _selectedSkills, accentColor: _primary, onToggle: (s) => setState(() => _selectedSkills.contains(s) ? _selectedSkills.remove(s) : _selectedSkills.add(s)))
                          : const Text('Your account will start as unverified. Document submission will be available after setup.'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
                child: AppButton(
                  label: _currentStep < _totalSteps - 1 ? 'Continue' : 'Create Account',
                  isLoading: _loading,
                  icon: _currentStep < _totalSteps - 1 ? Icons.arrow_forward_rounded : Icons.rocket_launch_rounded,
                  onPressed: _nextStep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({required GlobalKey<FormState> formKey, required String title, required String subtitle, required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            child,
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color accentColor;
  final String roleLabel;
  final VoidCallback onBack;

  const _StepHeader({required this.currentStep, required this.totalSteps, required this.accentColor, required this.roleLabel, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 14),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(roleLabel, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: accentColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(totalSteps, (i) {
              final isActive = i == currentStep;
              final isDone = i < currentStep;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AnimatedContainer(
                    duration: AppDurations.normal,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isDone ? accentColor : isActive ? accentColor.withValues(alpha: 0.7) : AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Step ${currentStep + 1} of $totalSteps',
              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _AccountStep extends StatelessWidget {
  final TextEditingController nameCtrl, emailCtrl, passCtrl;
  final Color accentColor;
  final bool isStudent;
  const _AccountStep({required this.nameCtrl, required this.emailCtrl, required this.passCtrl, required this.accentColor, required this.isStudent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: isStudent ? 'Full Name' : "Owner's Full Name",
          hint: 'Juan dela Cruz', controller: nameCtrl, accentColor: accentColor,
          prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 18),
          textInputAction: TextInputAction.next,
          validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Email', hint: 'you@example.com',
          controller: emailCtrl, keyboardType: TextInputType.emailAddress,
          accentColor: accentColor, textInputAction: TextInputAction.next,
          prefixIcon: Icon(Icons.alternate_email_rounded, color: AppColors.textMuted, size: 18),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Password', controller: passCtrl, obscureText: true,
          accentColor: accentColor, textInputAction: TextInputAction.done,
          prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 18),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 8) return 'At least 8 characters';
            return null;
          },
        ),
      ],
    );
  }
}

class _StudentProfileStep extends StatelessWidget {
  final TextEditingController bioCtrl, githubCtrl;
  final Color accentColor;
  const _StudentProfileStep({required this.bioCtrl, required this.githubCtrl, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: 'Short Bio', hint: 'Flutter dev @ PUP, passionate about mobile UX...',
          controller: bioCtrl, maxLines: 3, accentColor: accentColor,
          prefixIcon: Icon(Icons.edit_note_rounded, color: AppColors.textMuted, size: 18),
          validator: (v) => (v == null || v.isEmpty) ? 'Bio is required' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'GitHub Profile URL', hint: 'https://github.com/yourusername',
          controller: githubCtrl, keyboardType: TextInputType.url, accentColor: accentColor,
          prefixIcon: Icon(Icons.link_rounded, color: AppColors.textMuted, size: 18),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: accentColor, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Your GitHub link will be displayed on your public portfolio.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4))),
            ],
          ),
        ),
      ],
    );
  }
}

class _BusinessProfileStep extends StatelessWidget {
  final TextEditingController bizNameCtrl, addressCtrl;
  final Color accentColor;
  const _BusinessProfileStep({required this.bizNameCtrl, required this.addressCtrl, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: 'Business Name', hint: 'BAMBOU Greenhouse Café',
          controller: bizNameCtrl, accentColor: accentColor,
          prefixIcon: Icon(Icons.storefront_rounded, color: AppColors.textMuted, size: 18),
          validator: (v) => (v == null || v.isEmpty) ? 'Business name is required' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Business Address', hint: '123 Rizal St., Brgy. San Antonio, Manila',
          controller: addressCtrl, maxLines: 2, accentColor: accentColor,
          prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 18),
          validator: (v) => (v == null || v.isEmpty) ? 'Address is required' : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.verified_outlined, color: accentColor, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Business verification is not available yet. Your account starts as unverified.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4))),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkillsStep extends StatelessWidget {
  final Set<String> selected;
  final Color accentColor;
  final void Function(String) onToggle;
  const _SkillsStep({required this.selected, required this.accentColor, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: kSkillOptions.map((s) => SkillChip(
        label: s, selected: selected.contains(s),
        accentColor: accentColor, onTap: () => onToggle(s),
      )).toList(),
    );
  }
}
