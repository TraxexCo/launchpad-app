import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final UserRole role;
  const SettingsScreen({super.key, required this.role});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifJobs = true;
  bool _notifProposals = true;
  bool _notifMessages = true;
  bool _profilePublic = true;

  bool get _isStudent => widget.role == UserRole.student;
  Color get _primary => _isStudent ? AppColors.studentPrimary : AppColors.businessPrimary;
  Color get _accent  => _isStudent ? AppColors.studentAccent  : AppColors.businessAccent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: _primary.withValues(alpha: 0.04),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      _buildProfileCard(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSectionLabel('Notifications'),
                      const SizedBox(height: AppSpacing.md),
                      _buildToggle('New Jobs Near You', 'Get alerted when new jobs match your skills', _notifJobs, (v) => setState(() => _notifJobs = v)),
                      _buildToggle('Proposal Updates', 'Accepted, rejected, or viewed alerts', _notifProposals, (v) => setState(() => _notifProposals = v)),
                      _buildToggle('Messages', 'In-app chat notifications', _notifMessages, (v) => setState(() => _notifMessages = v)),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSectionLabel('Privacy'),
                      const SizedBox(height: AppSpacing.md),
                      _buildToggle('Public Profile', 'Allow businesses to find and view your profile', _profilePublic, (v) => setState(() => _profilePublic = v)),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSectionLabel('Account'),
                      const SizedBox(height: AppSpacing.md),
                      _buildTile(icon: Icons.edit_outlined, label: 'Edit Profile', color: _primary, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✏️ Edit Profile — coming soon!')))),
                      _buildTile(icon: Icons.lock_outline_rounded, label: 'Change Password', color: _primary, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔒 Change Password — coming soon!')))),
                      _buildTile(icon: Icons.help_outline_rounded, label: 'Help & Support', color: AppColors.info, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🆘 Help & Support — coming soon!')))),
                      _buildTile(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', color: AppColors.textMuted, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📄 Privacy Policy — coming soon!')))),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: 'Sign Out',
                        outlined: true,
                        icon: Icons.logout_rounded,
                        onPressed: () async {
                          await AuthService().logout();
                          if (context.mounted) context.go('/onboarding');
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: Text('LaunchPad v0.1.0-alpha',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 10, color: AppColors.textDisabled)),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go(_isStudent ? '/student' : '/business'),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textSecondary, size: 14),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
              Text('// account.preferences',
                  style: GoogleFonts.jetBrainsMono(fontSize: 10, color: _primary)),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primary.withValues(alpha: 0.15), _accent.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: _primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, _accent],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.4), blurRadius: 16)],
            ),
            child: const Center(
              child: Text('JD', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Juan dela Cruz',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(_isStudent ? 'Student Developer · PUP Manila' : 'BAMBOU Greenhouse Café',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('juan@example.com',
                    style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          Icon(Icons.edit_rounded, color: _primary, size: 18),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 80.ms);
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(width: 3, height: 16,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(AppRadius.full),
            )),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(subtitle, style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textMuted, height: 1.4)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: _primary,
              activeTrackColor: _primary.withValues(alpha: 0.25),
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.border,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(label, style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 12),
            ],
          ),
        ),
      ),
    );
  }
}



