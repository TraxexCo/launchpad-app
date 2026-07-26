import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_card.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _step = 0;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  String _category = 'Mobile App';
  String _urgency = 'Open';
  final Set<String> _requiredSkills = {};
  final _timelineCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _loading = false;

  final List<GlobalKey<FormState>> _keys = List.generate(3, (_) => GlobalKey<FormState>());

  static const _categories = ['Mobile App', 'Web App', 'E-Commerce', 'POS', 'Digital Menu', 'Inventory', 'Other'];
  static const _urgencies = ['Urgent', 'Open'];
  static const _skillOptions = ['Flutter', 'Dart', 'React', 'Next.js', 'Vue.js', 'Angular', 'Laravel',
    'PHP', 'Node.js', 'MySQL', 'Firebase', 'MongoDB', 'Figma', 'Python', 'Swift', 'Kotlin'];

  Color get _primary => AppColors.businessPrimary;
  Color get _accent  => AppColors.businessAccent;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _titleCtrl.dispose(); _descCtrl.dispose(); _budgetCtrl.dispose();
    _timelineCtrl.dispose(); _locationCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_keys[_step].currentState!.validate()) return;
    if (_step < 2) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    // Clear validation errors before going back
    _keys[_step].currentState?.reset();
    if (_step > 0) {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
      setState(() => _step--);
    } else {
      context.go('/business');
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/business');
  }

  static const _stepTitles = ['Job Details', 'Requirements', 'Review & Post'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: _primary.withValues(alpha: 0.04),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep0(),
                    _buildStep1(),
                    _buildStep2(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _prevStep,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 14),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text('// business.post_job',
                    style: GoogleFonts.jetBrainsMono(fontSize: 10, color: _primary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(3, (i) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedContainer(
                  duration: AppDurations.normal,
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= _step ? _primary : AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
            )),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(_stepTitles[_step],
                  style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              Text('${_step + 1} / 3',
                  style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Form(
        key: _keys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Job Title',
              hint: 'Online Ordering App for Café',
              controller: _titleCtrl,
              accentColor: _primary,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Job Description',
              hint: 'Describe what you need built, how it should work, and any important details...',
              controller: _descCtrl,
              maxLines: 5,
              accentColor: _primary,
              validator: (v) => (v == null || v.length < 50) ? 'Write at least 50 characters' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel(label: 'Category', color: _primary),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
              children: _categories.map((c) {
                final active = _category == c;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: active ? _primary.withValues(alpha: 0.15) : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: active ? _primary.withValues(alpha: 0.7) : AppColors.border),
                    ),
                    child: Text(c,
                        style: GoogleFonts.inter(fontSize: 12,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            color: active ? _primary : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel(label: 'Budget (₱)', color: _primary),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Budget',
              hint: '12000',
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              accentColor: _primary,
              prefixIcon: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('₱', style: TextStyle(color: _primary, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Budget is required';
                if (int.tryParse(v) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel(label: 'Urgency', color: _primary),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: _urgencies.map((u) {
                final active = _urgency == u;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _urgency = u),
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        height: 48,
                        decoration: BoxDecoration(
                          color: active
                              ? (u == 'Urgent' ? AppColors.error : AppColors.success).withValues(alpha: 0.12)
                              : AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: active
                                ? (u == 'Urgent' ? AppColors.error : AppColors.success).withValues(alpha: 0.6)
                                : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Text(u,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: active
                                      ? (u == 'Urgent' ? AppColors.error : AppColors.success)
                                      : AppColors.textSecondary)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Form(
        key: _keys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Expected Timeline',
              hint: '3–4 weeks',
              controller: _timelineCtrl,
              accentColor: _primary,
              prefixIcon: const Icon(Icons.timer_outlined, color: AppColors.textMuted, size: 18),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.isEmpty) ? 'Timeline is required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Business Location',
              hint: 'Brgy. Pinyahan, Quezon City',
              controller: _locationCtrl,
              accentColor: _primary,
              prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 18),
              validator: (v) => (v == null || v.isEmpty) ? 'Location is required' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel(label: 'Required Skills', color: _primary),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _skillOptions.map((s) {
                final sel = _requiredSkills.contains(s);
                return GestureDetector(
                  onTap: () => setState(() => sel ? _requiredSkills.remove(s) : _requiredSkills.add(s)),
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: sel ? _primary.withValues(alpha: 0.15) : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: sel ? _primary.withValues(alpha: 0.7) : AppColors.border),
                    ),
                    child: Text(s,
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w500,
                            color: sel ? _primary : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _keys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text('// job.preview',
                        style: GoogleFonts.jetBrainsMono(fontSize: 9, color: _primary)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(_titleCtrl.text.isEmpty ? 'Untitled Job' : _titleCtrl.text,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(_category,
                            style: GoogleFonts.jetBrainsMono(fontSize: 9, color: _primary)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: (_urgency == 'Urgent' ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(_urgency,
                            style: GoogleFonts.jetBrainsMono(fontSize: 9,
                                color: _urgency == 'Urgent' ? AppColors.error : AppColors.success)),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: AppSpacing.xl * 2),
                  _ReviewRow(label: 'Budget', value: '₱${_budgetCtrl.text}', icon: Icons.payments_outlined, color: _primary),
                  const SizedBox(height: AppSpacing.sm),
                  _ReviewRow(label: 'Timeline', value: _timelineCtrl.text.isEmpty ? '—' : _timelineCtrl.text, icon: Icons.timer_outlined, color: _accent),
                  const SizedBox(height: AppSpacing.sm),
                  _ReviewRow(label: 'Location', value: _locationCtrl.text.isEmpty ? '—' : _locationCtrl.text, icon: Icons.location_on_outlined, color: AppColors.info),
                  if (_requiredSkills.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs + 2, runSpacing: AppSpacing.xs,
                      children: _requiredSkills.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(s, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: _primary)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: AppSpacing.md),

            AppCard(
              backgroundColor: AppColors.warning.withValues(alpha: 0.06),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(
                    'Once posted, students in your area will be able to see and pitch on your job. You can close the job anytime.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                  )),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: AppButton(
        label: _step < 2 ? 'Continue' : 'Post Job Now',
        isLoading: _loading,
        icon: _step < 2 ? Icons.arrow_forward_rounded : Icons.check_rounded,
        onPressed: _nextStep,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.full))),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _ReviewRow({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Text('$label:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
        const Spacer(),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}


