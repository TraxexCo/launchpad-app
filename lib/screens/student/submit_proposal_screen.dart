import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_card.dart';

class SubmitProposalScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  const SubmitProposalScreen({super.key, required this.jobId, required this.jobTitle});

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _coverCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  int _timelineWeeks = 3;
  int _step = 0; // 0=write, 1=preview, 2=sent
  bool _loading = false;
  int _attachedProject = -1;

  static const _projects = ['Café POS System', 'QuizBee Mobile App', 'Grade Tracker Web'];

  @override
  void dispose() {
    _coverCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() { _loading = false; _step = 2; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.studentPrimary.withValues(alpha: 0.04),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: _step == 2 ? _buildSentState(context) : _buildForm(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSentState(BuildContext context) {
    return Center(
      key: const ValueKey('sent'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.success, Color(0xFF34D399)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.4), blurRadius: 40)],
              ),
              child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 42),
            )
                .animate()
                .scale(begin: const Offset(0.4, 0.4), duration: 700.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: AppSpacing.xl),

            Text('Pitch Sent!', style: Theme.of(context).textTheme.displaySmall)
                .animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, delay: 400.ms),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Your proposal for\n"${widget.jobTitle}" has been submitted.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: AppSpacing.xxl),

            AppCard(
              child: Column(
                children: [
                  _ConfirmRow(icon: Icons.payments_outlined, label: 'Your Rate', value: '₱${_rateCtrl.text}', accent: AppColors.studentPrimary),
                  const SizedBox(height: AppSpacing.sm),
                  _ConfirmRow(icon: Icons.timer_outlined, label: 'Timeline', value: '$_timelineWeeks weeks', accent: AppColors.studentAccent),
                  const SizedBox(height: AppSpacing.sm),
                  _ConfirmRow(icon: Icons.hourglass_empty_rounded, label: 'Status', value: 'Under Review', accent: AppColors.warning),
                ],
              ),
            ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.2, delay: 650.ms),

            const SizedBox(height: AppSpacing.xl),

            AppButton(
              label: 'Track My Proposals',
              icon: Icons.track_changes_rounded,
              onPressed: () => context.go('/student/proposals'),
            ).animate().fadeIn(delay: 800.ms),

            const SizedBox(height: AppSpacing.md),

            AppButton(
              label: 'Back to Jobs',
              outlined: true,
              onPressed: () => context.go('/student/jobs'),
            ).animate().fadeIn(delay: 880.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      key: const ValueKey('form'),
      children: [
        _buildHeader(context),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _step == 0
                ? _buildWriteStep()
                : _buildPreviewStep(context),
          ),
        ),
        _buildBottomBar(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _step == 0 ? context.go('/student/jobs/${widget.jobId}') : setState(() => _step = 0),
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_step == 0 ? 'Write Your Pitch' : 'Preview Pitch',
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text('// ${widget.jobTitle}',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 10, color: AppColors.studentPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress
          Row(
            children: List.generate(2, (i) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedContainer(
                  duration: AppDurations.normal,
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= _step
                        ? AppColors.studentPrimary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
            )),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildWriteStep() {
    return SingleChildScrollView(
      key: const ValueKey('write'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),

            // Cover letter
            AppTextField(
              label: 'Cover Letter',
              hint: 'Hi! I\'m a 3rd year CS student at PUP with experience building Flutter apps...',
              controller: _coverCtrl,
              maxLines: 7,
              accentColor: AppColors.studentPrimary,
              validator: (v) {
                if (v == null || v.isEmpty) return 'A cover letter is required';
                if (v.length < 80) return 'Write at least 80 characters';
                return null;
              },
            ),

            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${_coverCtrl.text.length} chars',
                    style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted)),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Rate
            AppTextField(
              label: 'Your Rate (₱)',
              hint: '12000',
              controller: _rateCtrl,
              keyboardType: TextInputType.number,
              accentColor: AppColors.studentPrimary,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text('₱', style: TextStyle(color: AppColors.studentPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your proposed rate';
                if (int.tryParse(v) == null) return 'Enter a valid number';
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Timeline slider
            Row(
              children: [
                Container(
                  width: 3, height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.studentPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Estimated Timeline', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('$_timelineWeeks weeks',
                    style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.studentPrimary)),
              ],
            ),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.studentPrimary,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.studentPrimary,
                overlayColor: AppColors.studentPrimary.withValues(alpha: 0.15),
                trackHeight: 3,
              ),
              child: Slider(
                value: _timelineWeeks.toDouble(),
                min: 1, max: 12, divisions: 11,
                onChanged: (v) => setState(() => _timelineWeeks = v.round()),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 week', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted)),
                Text('12 weeks', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Portfolio attachment
            Row(
              children: [
                Container(width: 3, height: 16,
                    decoration: BoxDecoration(color: AppColors.studentPrimary,
                        borderRadius: BorderRadius.circular(AppRadius.full))),
                const SizedBox(width: AppSpacing.sm),
                Text('Attach a Portfolio Project', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text('Optional', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textMuted)),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            ..._projects.asMap().entries.map((e) {
              final selected = _attachedProject == e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => setState(() => _attachedProject = selected ? -1 : e.key),
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.studentPrimary.withValues(alpha: 0.1) : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: selected ? AppColors.studentPrimary.withValues(alpha: 0.6) : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.folder_outlined, color: selected ? AppColors.studentPrimary : AppColors.textMuted, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(e.value, style: GoogleFonts.inter(fontSize: 13,
                            color: selected ? AppColors.studentPrimary : AppColors.textPrimary)),
                        const Spacer(),
                        Icon(
                          selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: selected ? AppColors.studentPrimary : AppColors.border,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewStep(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('preview'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.studentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text('// your.pitch',
                          style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.studentPrimary)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Cover Letter', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: AppSpacing.sm),
                Text(_coverCtrl.text.isEmpty ? 'No cover letter written.' : _coverCtrl.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7)),
                const Divider(color: AppColors.border, height: AppSpacing.xl * 2),
                _ConfirmRow(icon: Icons.payments_outlined, label: 'Your Rate', value: '₱${_rateCtrl.text}', accent: AppColors.studentPrimary),
                const SizedBox(height: AppSpacing.sm),
                _ConfirmRow(icon: Icons.timer_outlined, label: 'Timeline', value: '$_timelineWeeks weeks', accent: AppColors.studentAccent),
                if (_attachedProject >= 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _ConfirmRow(
                    icon: Icons.folder_outlined,
                    label: 'Attached Project',
                    value: _projects[_attachedProject],
                    accent: AppColors.info,
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

          const SizedBox(height: AppSpacing.lg),

          AppCard(
            backgroundColor: AppColors.warning.withValues(alpha: 0.06),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(
                  'Once sent, you cannot edit your pitch. The business will review and respond via in-app chat.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                )),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: _step == 0
          ? AppButton(
              label: 'Preview Pitch',
              icon: Icons.visibility_outlined,
              onPressed: () {
                if (_formKey.currentState!.validate()) setState(() => _step = 1);
              },
            )
          : AppButton(
              label: 'Send Pitch',
              icon: Icons.send_rounded,
              isLoading: _loading,
              onPressed: _send,
            ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color accent;
  const _ConfirmRow({required this.icon, required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Text('$label:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
        const Spacer(),
        Text(value, style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}


