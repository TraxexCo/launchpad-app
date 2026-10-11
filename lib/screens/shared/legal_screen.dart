import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';

class LegalScreen extends StatelessWidget {
  final bool showTerms;
  const LegalScreen({super.key, this.showTerms = false});

  @override
  Widget build(BuildContext context) {
    final title = showTerms ? 'Terms of Use' : 'Privacy Policy';
    final sections = showTerms ? _terms : _privacy;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Effective October 11, 2026 · Classroom demonstration',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            ...sections.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.value,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _privacy = {
    'What LaunchPad stores':
        'Account identity, profile details, jobs, proposals, contracts, messages, approximate business location, verification documents, reports, payment test records, device notification tokens, and crash diagnostics.',
    'Why it is used':
        'Data supports matching students with local businesses, project delivery, communication, classroom payment demonstrations, safety review, and system reliability.',
    'Who can see it':
        'Signed-in users can see marketplace profiles and listings. Contract participants see their private project workspace. Verification files are private to their owner and authorized administrators.',
    'Location':
        'Location is requested only when a business publishes its location or a student uses nearby discovery. Permission can be denied in device settings.',
    'Retention and deletion':
        'Project records are kept while the classroom service operates. You can permanently delete your account and linked data from Settings.',
    'Contact':
        'For this classroom project, contact the project owner or course instructor for privacy questions.',
  };
  static const _terms = {
    'Classroom use':
        'LaunchPad is a student project for demonstration and assessment. It is not a commercial marketplace or financial service.',
    'Accounts':
        'Provide accurate information, protect your password, and do not impersonate another person or business.',
    'Projects':
        'Businesses and students should agree on clear scope, timeline, and deliverables. Submitted files must be safe and lawful.',
    'Payments':
        'PayMongo operates in test mode. Payment records are demonstrations and do not represent real settlement or payout.',
    'Safety':
        'Harassment, fraud, harmful files, and unlawful content are prohibited. Reports, suspensions, and disputes may be reviewed by an administrator.',
    'Availability':
        'The project may be changed, reset, or discontinued after the class demonstration.',
  };
}
