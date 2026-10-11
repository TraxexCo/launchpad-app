import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../services/verification_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class VerificationScreen extends StatefulWidget {
  final UserRole role;
  const VerificationScreen({super.key, required this.role});
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _service = VerificationService();
  VerificationSubmission? _latest;
  PlatformFile? _file;
  int? _fileSize;
  bool _loading = true;
  bool _submitting = false;
  late String _type;
  bool get _student => widget.role == UserRole.student;
  Color get _accent =>
      _student ? AppColors.studentPrimary : AppColors.businessPrimary;

  @override
  void initState() {
    super.initState();
    _type = _student ? 'student_id' : 'business_permit';
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await _service.latest();
      if (mounted) setState(() => _latest = value);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      final size = result.lengthSync() ?? await result.length();
      setState(() {
        _file = result;
        _fileSize = size;
      });
    }
  }

  Future<void> _submit() async {
    final file = _file;
    if (file == null || _fileSize == null || _fileSize! > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choose a readable JPG, PNG, or PDF smaller than 5 MB.',
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final bytes = await file.readAsBytes();
      await _service.submit(
        documentType: _type,
        fileName: file.name,
        bytes: bytes,
      );
      _file = null;
      _fileSize = null;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document sent for review.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is PostgrestException
                  ? error.message
                  : 'Document upload failed.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _student
        ? const {
            'student_id': 'University ID',
            'enrollment': 'Enrollment certificate',
          }
        : const {
            'business_permit': 'Business permit',
            'storefront': 'Storefront proof',
          };
    return Scaffold(
      appBar: AppBar(title: const Text('Identity verification')),
      body: AppBackground(
        tintColor: _accent.withValues(alpha: .05),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Build trust with proof.',
              style: GoogleFonts.manrope(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _student
                  ? 'Submit a school document. It stays in private storage and is visible only to you and authorized reviewers.'
                  : 'Submit a registration document so an administrator can review the business account.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_latest != null)
              _statusCard(_latest!),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Document type'),
              items: options.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              onTap: _submitting ? null : _pick,
              accentColor: _accent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(
                      _file == null
                          ? Icons.cloud_upload_outlined
                          : Icons.description_rounded,
                      size: 52,
                      color: _accent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _file?.name ?? 'Choose document',
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _file == null
                          ? 'JPG, PNG, or PDF · maximum 5 MB'
                          : '${((_fileSize ?? 0) / 1024).ceil()} KB',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Submit for review',
              icon: Icons.verified_user_outlined,
              backgroundColor: _accent,
              isLoading: _submitting,
              onPressed: _file == null ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(VerificationSubmission item) {
    final color = switch (item.status) {
      'verified' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };
    final label = switch (item.status) {
      'verified' => 'Verified',
      'rejected' => 'Needs another document',
      _ => 'Review pending',
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        border: Border.all(color: color.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w800, color: color),
                ),
                Text(
                  'Latest: ${item.documentType.replaceAll('_', ' ')}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
