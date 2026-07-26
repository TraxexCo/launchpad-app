import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _page = 0;
  UserRole? _selectedRole;
  late final AnimationController _tintCtrl;

  @override
  void initState() {
    super.initState();
    _tintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _tintCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectRole(UserRole role) async {
    HapticFeedback.mediumImpact();
    setState(() => _selectedRole = role);
    await _tintCtrl.forward();
    if (!mounted) return;
    setState(() => _page = 1);
  }

  void _goBack() {
    setState(() {
      _page = 0;
      _selectedRole = null;
      _tintCtrl.reset();
    });
  }

  Color get _roleColor =>
      _selectedRole == UserRole.business ? AppColors.businessPrimary : AppColors.studentPrimary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        tintColor: _selectedRole != null ? _roleColor.withValues(alpha: 0.06) : null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
              child: child,
            ),
          ),
          child: _page == 0
              ? _RoleSelectPage(key: const ValueKey('role'), onSelect: _selectRole)
              : _AuthOptionsPage(key: const ValueKey('auth'), role: _selectedRole!, onBack: _goBack),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 0 — Role Selection
// ─────────────────────────────────────────────────────────────────────────────
class _RoleSelectPage extends StatelessWidget {
  final Future<void> Function(UserRole) onSelect;
  const _RoleSelectPage({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xxl),

            Text('Who are\nyou?', style: Theme.of(context).textTheme.displayMedium)
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.25, duration: 500.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: AppSpacing.sm),

            Text('Your role shapes the entire experience.', style: Theme.of(context).textTheme.bodyLarge)
                .animate()
                .fadeIn(duration: 500.ms, delay: 180.ms),

            const SizedBox(height: AppSpacing.xxl),

            _RoleCard(
              title: 'Student Developer',
              description: 'Build real projects.\nEarn. Grow your portfolio.',
              icon: Icons.code_rounded,
              tag: 'CS / IT / Programming Student',
              primaryColor: AppColors.studentPrimary,
              accentColor: AppColors.studentAccent,
              onTap: () => onSelect(UserRole.student),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 280.ms)
                .slideX(begin: -0.08, duration: 500.ms, delay: 280.ms),

            const SizedBox(height: AppSpacing.md),

            _RoleCard(
              title: 'Local Business',
              description: 'Go digital. Find talent.\nGrow your reach.',
              icon: Icons.storefront_rounded,
              tag: 'Shop / Café / Restaurant / Store',
              primaryColor: AppColors.businessPrimary,
              accentColor: AppColors.businessAccent,
              onTap: () => onSelect(UserRole.business),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 400.ms)
                .slideX(begin: 0.08, duration: 500.ms, delay: 400.ms),

            const Spacer(),

            Center(
              child: Text(
                '// you can always switch roles later',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 650.ms),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final String tag;
  final Color primaryColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title, required this.description, required this.icon,
    required this.tag, required this.primaryColor, required this.accentColor,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: widget.primaryColor.withValues(alpha: 0.28)),
            boxShadow: [BoxShadow(color: widget.primaryColor.withValues(alpha: 0.1), blurRadius: 28, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [widget.primaryColor, widget.accentColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [BoxShadow(color: widget.primaryColor.withValues(alpha: 0.4), blurRadius: 16)],
                ),
                child: Icon(widget.icon, color: AppColors.textPrimary, size: 30),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(widget.tag, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: widget.primaryColor, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 6),
                    Text(widget.title, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(widget.description, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.45)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: widget.primaryColor, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 1 — Auth Options
// ─────────────────────────────────────────────────────────────────────────────
class _AuthOptionsPage extends StatelessWidget {
  final UserRole role;
  final VoidCallback onBack;
  const _AuthOptionsPage({super.key, required this.role, required this.onBack});

  bool get _isStudent => role == UserRole.student;
  Color get _primary => _isStudent ? AppColors.studentPrimary : AppColors.businessPrimary;
  Color get _accent  => _isStudent ? AppColors.studentAccent  : AppColors.businessAccent;
  String get _slug   => _isStudent ? 'student' : 'business';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),

            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: _primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded, color: _primary, size: 12),
                    const SizedBox(width: 6),
                    Icon(_isStudent ? Icons.code_rounded : Icons.storefront_rounded, color: _primary, size: 14),
                    const SizedBox(width: 6),
                    Text(_isStudent ? 'Student Developer' : 'Local Business',
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, color: _primary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),

            const SizedBox(height: AppSpacing.xl),

            ShaderMask(
              shaderCallback: (bounds) =>
                  LinearGradient(colors: [_primary, _accent]).createShader(bounds),
              child: Text(
                _isStudent ? 'Ready to\nhustle?' : 'Ready to go\ndigital?',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.textPrimary),
              ),
            ).animate().fadeIn(duration: 550.ms, delay: 100.ms),

            const SizedBox(height: AppSpacing.md),

            Text(
              _isStudent
                  ? 'Connect with local businesses that need\nyour skills. Build real things. Get paid.'
                  : 'Find talented student developers to bring\nyour business online — at accessible rates.',
              style: Theme.of(context).textTheme.bodyLarge,
            ).animate().fadeIn(duration: 500.ms, delay: 220.ms),

            const SizedBox(height: AppSpacing.xl),
            ..._features.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6,
                          decoration: BoxDecoration(color: _primary, shape: BoxShape.circle)),
                      const SizedBox(width: AppSpacing.sm),
                      Text(e.value, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: 350 + e.key * 80))),

            const Spacer(),

            _OBButton(label: 'Create Account', isPrimary: true, primary: _primary, accent: _accent,
                onTap: () => context.go('/register?role=$_slug'))
                .animate().slideY(begin: 0.3, duration: 500.ms, delay: 500.ms).fadeIn(delay: 500.ms),

            const SizedBox(height: AppSpacing.sm + 2),

            _OBButton(label: 'Sign In', isPrimary: false, primary: _primary, accent: _accent,
                onTap: () => context.go('/login?role=$_slug'))
                .animate().slideY(begin: 0.3, duration: 500.ms, delay: 600.ms).fadeIn(delay: 600.ms),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  List<String> get _features => _isStudent
      ? ['Showcase your portfolio to real clients', 'Send pitches to undigitized local businesses', 'Browse job posts & earn ₱ for your work']
      : ['Post project requests with your budget', 'Browse verified student talent portfolios', 'Digitize your shop — starting from ₱5,000'];
}

class _OBButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final Color primary;
  final Color accent;
  final VoidCallback onTap;
  const _OBButton({required this.label, required this.isPrimary, required this.primary, required this.accent, required this.onTap});

  @override
  State<_OBButton> createState() => _OBButtonState();
}

class _OBButtonState extends State<_OBButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.lightImpact(); _ctrl.forward(); },
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity, height: 56,
          decoration: BoxDecoration(
            gradient: widget.isPrimary ? LinearGradient(colors: [widget.primary, widget.accent], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
            color: widget.isPrimary ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: widget.isPrimary ? null : Border.all(color: widget.primary.withValues(alpha: 0.4), width: 1.5),
            boxShadow: widget.isPrimary
                ? [BoxShadow(color: widget.primary.withValues(alpha: 0.35), blurRadius: 22, spreadRadius: -4, offset: const Offset(0, 6))]
                : null,
          ),
          child: Center(
            child: Text(widget.label,
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700,
                    color: widget.isPrimary ? Colors.white : widget.primary)),
          ),
        ),
      ),
    );
  }
}

