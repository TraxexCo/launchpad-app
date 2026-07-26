import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import 'app_button.dart';
import 'app_text_field.dart';

class ReportModal extends StatefulWidget {
  final String targetName;
  final String targetType; // 'student' | 'business' | 'job' | 'proposal'

  const ReportModal({super.key, required this.targetName, required this.targetType});

  static void show(BuildContext context, {required String targetName, required String targetType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportModal(targetName: targetName, targetType: targetType),
    );
  }

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  String? _selectedReason;
  bool _submitting = false;

  final List<String> _reasons = [
    'Not complying with agreement',
    'Inappropriate behavior or language',
    'Spam or misleading information',
    'Suspicious or fraudulent activity',
    'Other',
  ];

  void _submit() async {
    if (_selectedReason == null) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(seconds: 1)); // Mock API delay
    if (!mounted) return;
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report submitted. Our Trust & Safety team will review this shortly.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl + keyboard),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Report ${widget.targetName}', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => context.pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please let us know why you are reporting this ${widget.targetType}. Your report will be kept anonymous.',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._reasons.map((reason) {
            final isSelected = _selectedReason == reason;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: InkWell(
                onTap: () => setState(() => _selectedReason = reason),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? AppColors.error : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: isSelected ? AppColors.error.withValues(alpha: 0.05) : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.error : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          reason,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Additional Details (Optional)',
            hint: 'Provide more context to help our investigation...',
            maxLines: 3,
            accentColor: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _submitting ? 'Submitting Report...' : 'Submit Report',
            onPressed: _selectedReason != null ? _submit : null,
            backgroundColor: AppColors.error,
          ),
        ],
      ),
    );
  }
}
