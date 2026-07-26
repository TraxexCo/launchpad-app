import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class VerificationScreen extends StatefulWidget {
  final UserRole role;

  const VerificationScreen({super.key, required this.role});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isLoading = false;
  bool _uploaded = false;

  bool get _isStudent => widget.role == UserRole.student;
  Color get _primary => _isStudent ? AppColors.studentPrimary : AppColors.businessPrimary;

  void _handleUpload() async {
    setState(() => _isLoading = true);
    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
      _uploaded = true;
    });
  }

  void _handleFinish() {
    context.go(_isStudent ? '/student' : '/business');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Identity'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Trust & Safety',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _isStudent
                    ? 'Please upload a photo of your University ID or Certificate of Registration (COR) to verify your student status.'
                    : 'Please upload your DTI/SEC Registration or Business Permit to verify your business.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: AppCard(
                  onTap: _uploaded ? null : _handleUpload,
                  child: Center(
                    child: _isLoading
                        ? CircularProgressIndicator(color: _primary)
                        : _uploaded
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Document Uploaded',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Our team will review this shortly.',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_upload_rounded, color: _primary, size: 64),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Tap to Upload Document',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _primary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'JPG, PNG, or PDF (Max 5MB)',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: _uploaded ? 'Continue to Dashboard' : 'Skip for Now',
                onPressed: _handleFinish,
                backgroundColor: _uploaded ? _primary : AppColors.surfaceHigh,
                foregroundColor: _uploaded ? Colors.white : AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
