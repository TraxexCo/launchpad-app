import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/skill_chip.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _liveCtrl = TextEditingController();
  final Set<String> _selectedSkills = {};
  String _selectedType = 'Mobile App';
  bool _loading = false;

  static const _types = ['Mobile App', 'Web App', 'Desktop App', 'API / Backend', 'UI/UX Design', 'Other'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _githubCtrl.dispose();
    _liveCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    int? createdId;
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw StateError('Sign in to add a project');
      final row = await client.from('portfolio_projects').insert({
        'student_id': userId,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'project_type': _selectedType,
        'repository_url': _githubCtrl.text.trim().isEmpty ? null : _githubCtrl.text.trim(),
        'demo_url': _liveCtrl.text.trim().isEmpty ? null : _liveCtrl.text.trim(),
      }).select('id').single();
      createdId = row['id'] as int;
      if (_selectedSkills.isNotEmpty) {
        final skills = await client.from('skills').select('id,name')
            .inFilter('name', _selectedSkills.toList());
        await client.from('portfolio_project_skills').insert([
          for (final skill in skills)
            {'project_id': row['id'], 'skill_id': skill['id']},
        ]);
      }
      if (!mounted) return;
      context.go('/student/portfolio/${row['id']}');
    } catch (error) {
      if (createdId != null) {
        try {
          await Supabase.instance.client.from('portfolio_projects')
              .delete().eq('id', createdId);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save project: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.studentPrimary.withValues(alpha: 0.04),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        _buildCoverUpload(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSectionLabel('Project Info'),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Project Title',
                          hint: 'Café POS System',
                          controller: _titleCtrl,
                          accentColor: AppColors.studentPrimary,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Description',
                          hint: 'A touchscreen POS built with Flutter and Firebase for a local café...',
                          controller: _descCtrl,
                          maxLines: 4,
                          accentColor: AppColors.studentPrimary,
                          validator: (v) => (v == null || v.length < 30) ? 'Write at least 30 characters' : null,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSectionLabel('Project Type'),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: _types.map((t) {
                            final active = _selectedType == t;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedType = t),
                              child: AnimatedContainer(
                                duration: AppDurations.fast,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                                decoration: BoxDecoration(
                                  color: active ? AppColors.studentPrimary.withValues(alpha: 0.15) : AppColors.surfaceHigh,
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                  border: Border.all(
                                    color: active ? AppColors.studentPrimary.withValues(alpha: 0.7) : AppColors.border,
                                  ),
                                ),
                                child: Text(t,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                      color: active ? AppColors.studentPrimary : AppColors.textSecondary,
                                    )),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSectionLabel('Tech Stack Used'),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: kSkillOptions.map((s) => SkillChip(
                            label: s,
                            selected: _selectedSkills.contains(s),
                            accentColor: AppColors.studentPrimary,
                            onTap: () => setState(() =>
                                _selectedSkills.contains(s)
                                    ? _selectedSkills.remove(s)
                                    : _selectedSkills.add(s)),
                          )).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSectionLabel('Links'),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'GitHub Repository URL',
                          hint: 'https://github.com/you/project',
                          controller: _githubCtrl,
                          keyboardType: TextInputType.url,
                          accentColor: AppColors.studentPrimary,
                          prefixIcon: const Icon(Icons.code_rounded, color: AppColors.textMuted, size: 18),
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final uri = Uri.tryParse(v.trim());
                            if (uri == null || !uri.hasScheme || uri.scheme != 'https') {
                              return 'Please enter a valid https:// URL';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Live Demo URL',
                          hint: 'https://your-project.vercel.app',
                          controller: _liveCtrl,
                          keyboardType: TextInputType.url,
                          accentColor: AppColors.studentPrimary,
                          prefixIcon: const Icon(Icons.open_in_new_rounded, color: AppColors.textMuted, size: 18),
                          textInputAction: TextInputAction.done,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final uri = Uri.tryParse(v.trim());
                            if (uri == null || !uri.hasScheme || uri.scheme != 'https') {
                              return 'Please enter a valid https:// URL';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
                child: AppButton(
                  label: 'Add to Portfolio',
                  icon: Icons.add_circle_outline_rounded,
                  isLoading: _loading,
                  onPressed: _save,
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
            onTap: () => context.canPop() ? context.pop() : context.go('/student'),
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
              Text('Add Project', style: Theme.of(context).textTheme.headlineSmall),
              Text('// portfolio.new_entry',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: AppColors.studentPrimary)),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildCoverUpload() {
    return Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.studentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.folder_outlined,
                          color: AppColors.studentPrimary, size: 24),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Project cover image',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('Image uploads will be available later.',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
        ),
      ).animate().fadeIn(duration: 500.ms, delay: 80.ms);
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(width: 3, height: 16,
            decoration: BoxDecoration(
              color: AppColors.studentPrimary,
              borderRadius: BorderRadius.circular(AppRadius.full),
            )),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}


