import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../models/job_post.dart';
import '../../services/job_service.dart';

class EditJobScreen extends StatefulWidget {
  final JobPost job;
  const EditJobScreen({super.key, required this.job});

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _timelineCtrl;
  late final TextEditingController _locationCtrl;
  late String _category;
  late String _urgency;
  late Set<String> _requiredSkills;
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  static const _categories = ['Mobile App', 'Web App', 'E-Commerce', 'POS', 'Digital Menu', 'Inventory', 'Other'];
  static const _urgencies = ['Urgent', 'Open'];
  static const _skillOptions = ['Flutter', 'Dart', 'React', 'Next.js', 'Vue.js', 'Angular', 'Laravel',
    'PHP', 'Node.js', 'MySQL', 'Firebase', 'MongoDB', 'Figma', 'Python', 'Swift', 'Kotlin'];

  @override
  void initState() {
    super.initState();
    _titleCtrl    = TextEditingController(text: widget.job.title);
    _descCtrl     = TextEditingController(text: widget.job.description);
    _budgetCtrl   = TextEditingController(text: widget.job.budget);
    _timelineCtrl = TextEditingController(text: widget.job.timeline);
    _locationCtrl = TextEditingController(text: widget.job.location);
    _category       = widget.job.category;
    _urgency        = widget.job.urgency;
    _requiredSkills = Set.from(widget.job.skills);
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _budgetCtrl.dispose();
    _timelineCtrl.dispose(); _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await JobService().updateJob(
        int.parse(widget.job.id),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        budget: _budgetCtrl.text.trim(),
        category: _category,
        urgency: _urgency,
        skills: _requiredSkills.toList(),
        timeline: _timelineCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Job updated successfully!'), backgroundColor: AppColors.success),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.businessPrimary.withValues(alpha: 0.04),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('Edit Job Post',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          controller: _titleCtrl,
                          label: 'Job Title',
                          hint: 'e.g. Online Ordering App for Café',
                          validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _descCtrl,
                          label: 'Description',
                          hint: 'Describe what you need built...',
                          maxLines: 4,
                          validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _budgetCtrl,
                          label: 'Budget (₱)',
                          hint: 'e.g. 8000',
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Budget is required' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _timelineCtrl,
                          label: 'Timeline',
                          hint: 'e.g. 3 weeks',
                          validator: (v) => v == null || v.isEmpty ? 'Timeline is required' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _locationCtrl,
                          label: 'Location',
                          hint: 'e.g. Sta. Mesa, Manila',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Category', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
                          children: _categories.map((cat) {
                            final sel = cat == _category;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: sel,
                              selectedColor: AppColors.businessPrimary.withValues(alpha: 0.2),
                              onSelected: (_) => setState(() => _category = cat),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Urgency', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: _urgencies.map((u) {
                            final sel = u == _urgency;
                            return ChoiceChip(
                              label: Text(u),
                              selected: sel,
                              selectedColor: AppColors.businessPrimary.withValues(alpha: 0.2),
                              onSelected: (_) => setState(() => _urgency = u),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Required Skills', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
                          children: _skillOptions.map((s) {
                            final sel = _requiredSkills.contains(s);
                            return FilterChip(
                              label: Text(s),
                              selected: sel,
                              selectedColor: AppColors.businessPrimary.withValues(alpha: 0.15),
                              onSelected: (v) => setState(() => v ? _requiredSkills.add(s) : _requiredSkills.remove(s)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppButton(
                          label: _loading ? 'Saving...' : 'Save Changes',
                          icon: Icons.save_rounded,
                          isLoading: _loading,
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
