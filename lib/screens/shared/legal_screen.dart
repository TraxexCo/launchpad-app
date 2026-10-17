import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';

/// Simple legal content screen showing either the Privacy Policy or
/// Terms of Service. Content is static placeholder text until real
/// policy documents are supplied.
class LegalScreen extends StatelessWidget {
  /// When [showTerms] is true, Terms of Service is displayed;
  /// otherwise Privacy Policy is shown.
  final bool showTerms;

  const LegalScreen({super.key, this.showTerms = false});

  String get _title => showTerms ? 'Terms of Service' : 'Privacy Policy';

  String get _effectiveDate => 'Effective: October 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.violet.withValues(alpha: 0.04),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTag(label: showTerms ? '// terms.of.service' : '// privacy.policy'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _effectiveDate,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (showTerms) ..._termsContent(context) else ..._privacyContent(context),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: 'View Full Document Online',
                        icon: Icons.open_in_new_rounded,
                        outlined: true,
                        foregroundColor: AppColors.studentPrimary,
                        onPressed: () => _openUrl(
                          showTerms
                              ? 'https://launchpad.example.com/terms'
                              : 'https://launchpad.example.com/privacy',
                        ),
                      ),
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textSecondary,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(_title, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }

  List<Widget> _privacyContent(BuildContext context) => [
    _LegalSection(
      title: '1. Information We Collect',
      body:
          'We collect the information you provide during registration (name, email, school/business details), '
          'portfolio projects, proposals, and messages exchanged through the platform. We also collect '
          'device and usage data to improve the service.',
    ),
    _LegalSection(
      title: '2. How We Use Your Information',
      body:
          'Your information is used to operate the LaunchPad platform, match students with local businesses, '
          'facilitate project contracts, process payments, and send important notifications about your account.',
    ),
    _LegalSection(
      title: '3. Data Sharing',
      body:
          'We do not sell your personal data. Profile information visible to other users (name, bio, skills) '
          'is shared as part of the platform\'s core functionality. We share data with payment processors '
          '(PayMongo) only to the extent required to complete transactions.',
    ),
    _LegalSection(
      title: '4. Data Retention',
      body:
          'We retain your data for as long as your account is active. You may request account deletion '
          'at any time from Settings. Deleted accounts are purged within 30 days.',
    ),
    _LegalSection(
      title: '5. Contact',
      body: 'For privacy questions, reach us at privacy@launchpad.example.com.',
    ),
  ];

  List<Widget> _termsContent(BuildContext context) => [
    _LegalSection(
      title: '1. Eligibility',
      body:
          'LaunchPad is available to enrolled students and registered business owners in the Philippines. '
          'By creating an account you confirm that the information you provide is accurate.',
    ),
    _LegalSection(
      title: '2. Platform Role',
      body:
          'LaunchPad connects students and businesses but is not a party to any contract formed between '
          'them. Each project contract is solely between the student and the business.',
    ),
    _LegalSection(
      title: '3. Payments',
      body:
          'Payments are processed through PayMongo in test mode during the beta period. No real money '
          'is transferred until the platform moves to production mode.',
    ),
    _LegalSection(
      title: '4. Prohibited Conduct',
      body:
          'Users must not post false information, harass other users, circumvent the platform to avoid fees, '
          'or use the service for any illegal purpose.',
    ),
    _LegalSection(
      title: '5. Termination',
      body:
          'LaunchPad reserves the right to suspend or terminate accounts that violate these terms or '
          'harm other users.',
    ),
    _LegalSection(
      title: '6. Changes to Terms',
      body:
          'We may update these terms periodically. Continued use of the platform after changes are posted '
          'constitutes acceptance of the updated terms.',
    ),
  ];
}

/// ── Private helpers ──────────────────────────────────────────────────────────

class _SectionTag extends StatelessWidget {
  final String label;
  const _SectionTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 10,
          color: AppColors.violet,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String title;
  final String body;
  const _LegalSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
