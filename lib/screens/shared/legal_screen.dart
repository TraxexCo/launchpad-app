import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../widgets/app_background.dart';

/// Classroom privacy notice and terms shown inside the application.
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
                      _SectionTag(label: showTerms ? 'Terms' : 'Privacy'),
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
                      if (showTerms)
                        ..._termsContent(context)
                      else
                        ..._privacyContent(context),
                      const SizedBox(height: AppSpacing.sm),
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
          'portfolio projects, proposals, messages, verification documents, profile photos, and project '
          'deliverables you submit. When you use nearby discovery, your device location is used to calculate '
          'distance. Android notification tokens and non-sensitive error diagnostics may also be stored.',
    ),
    _LegalSection(
      title: '2. How We Use Your Information',
      body:
          'Your information is used to operate the LaunchPad platform, match students with local businesses, '
          'facilitate project contracts, run PayMongo test-mode payments, review verification documents, '
          'deliver notifications, and diagnose application failures.',
    ),
    _LegalSection(
      title: '3. Data Sharing',
      body:
          'We do not sell your personal data. Profile information visible to other users (name, bio, skills) '
          'is shared as part of the platform\'s core functionality. Verification documents and contract '
          'deliverables use restricted storage. PayMongo receives the information required to create a '
          'test checkout, and Firebase receives Android push notification delivery data.',
    ),
    _LegalSection(
      title: '4. Data Retention',
      body:
          'Data is retained while the classroom project is active. You can permanently delete your account '
          'from Settings. Deletion removes the authentication account and linked records according to the '
          'database retention and cascade rules.',
    ),
    _LegalSection(
      title: '5. Classroom scope',
      body:
          'LaunchPad is an academic demonstration project. Questions about the demonstration should be '
          'raised with the project presenter or subject instructor.',
    ),
  ];

  List<Widget> _termsContent(BuildContext context) => [
    _LegalSection(
      title: '1. Eligibility',
      body:
          'LaunchPad is designed for student developers and local business representatives participating in '
          'the classroom demonstration. By creating an account, you confirm that the information you provide '
          'for the demonstration is accurate and appropriate.',
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
          'Payments use PayMongo test mode for the classroom demonstration. No real money is charged or '
          'transferred, and payment and refund states are demonstration records.',
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
          'An authorized administrator may suspend demonstration accounts, close inappropriate job posts, '
          'or resolve reports and disputes to keep the evaluation environment usable.',
    ),
    _LegalSection(
      title: '6. Changes to Terms',
      body:
          'These terms may be updated before the final evaluation to match the demonstrated system. The '
          'effective date shown above identifies the version presented in the application.',
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
