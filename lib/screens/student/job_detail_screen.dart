import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../services/job_service.dart';
import '../../models/job_post.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/skill_chip.dart';
import '../../widgets/report_modal.dart';
import '../../services/saved_job_service.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _bookmarked = false;
  JobPost? _job;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    setState(() { _loading = true; _error = null; });
    try {
      final id = int.parse(widget.jobId);
      final job = await JobService().getJobById(id);
      final saved = await SavedJobService().isJobSaved(id);
      if (mounted) setState(() { _job = job; _bookmarked = saved; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.studentPrimary.withValues(alpha: 0.04),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.studentPrimary))
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                : _job == null
                    ? const Center(child: Text('Job not found'))
                    : Column(
                        children: [
                          Expanded(
                            child: CustomScrollView(
                              slivers: [
                                _buildAppBar(context),
                                SliverToBoxAdapter(child: _buildBusinessCard()),
                                SliverToBoxAdapter(child: _buildJobMeta()),
                                SliverToBoxAdapter(child: _buildDescription()),
                                SliverToBoxAdapter(child: _buildSkillsSection()),
                                SliverToBoxAdapter(child: _buildTimeline()),
                                const SliverToBoxAdapter(child: SizedBox(height: 120)),
                              ],
                            ),
                          ),
                          _buildBottomCTA(context),
                        ],
                      ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      expandedHeight: 0,
      leading: GestureDetector(
        onTap: () => context.canPop() ? context.pop() : context.go('/student/jobs'),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 14),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.outlined_flag_rounded, color: AppColors.textSecondary),
          tooltip: 'Report Job',
          onPressed: () => ReportModal.show(context, targetName: _job!.title, targetType: 'job'),
        ),
        GestureDetector(
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              final isSaved = await SavedJobService().toggleSave(int.parse(widget.jobId));
              if (!mounted) return;
              setState(() => _bookmarked = isSaved);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(isSaved ? '📌 Job saved to bookmarks!' : 'Removed from bookmarks.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            } catch (e) {
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Could not update saved job: $e')),
                );
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              _bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _bookmarked ? AppColors.studentPrimary : AppColors.textSecondary,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.businessPrimary, AppColors.businessAccent],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [BoxShadow(color: AppColors.businessPrimary.withValues(alpha: 0.4), blurRadius: 16)],
              ),
              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.businessPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text('// ${_job!.category}',
                        style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.businessPrimary)),
                  ),
                  const SizedBox(height: 5),
                  Text(_job!.businessName ?? 'Business',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 12),
                      const SizedBox(width: 3),
                      Text(_job!.location,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                      if (_job!.verificationStatus == 'verified') ...[
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.verified_rounded, color: AppColors.success, size: 12),
                        const SizedBox(width: 3),
                        Text('Verified', style: GoogleFonts.inter(fontSize: 12, color: AppColors.success)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildJobMeta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_job!.title,
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _MetaTile(icon: Icons.payments_outlined, label: 'Budget',
                  value: _job!.budget, accent: AppColors.studentPrimary, mono: true),
              const SizedBox(width: AppSpacing.sm),
              _MetaTile(icon: Icons.access_time_rounded, label: 'Urgency',
                  value: _job!.urgency, accent: AppColors.studentAccent),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Job Description'),
          const SizedBox(height: AppSpacing.md),
          Text(_job!.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7)),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 180.ms),
    );
  }

  Widget _buildSkillsSection() {
    final skills = _job!.skills;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Skills Required'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: skills.map((s) => SkillChip(
              label: s, selected: true, accentColor: AppColors.studentPrimary,
            )).toList(),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildTimeline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.studentAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.calendar_month_outlined, color: AppColors.studentAccent, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expected Timeline',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                Text(_job!.timeline,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Posted', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                Text(_timeAgo(_job!.createdAt),
                    style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms, delay: 420.ms),
    );
  }

  Widget _buildBottomCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: AppButton(
              label: 'Save',
              outlined: true,
              icon: _bookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              onPressed: () => setState(() => _bookmarked = !_bookmarked),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Submit Pitch',
              icon: Icons.rocket_launch_rounded,
              onPressed: () => context.push(
                '/student/jobs/${widget.jobId}/pitch?title=${Uri.encodeComponent(_job!.title)}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────
class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color accent;
  final bool mono;
  const _MetaTile({required this.icon, required this.label, required this.value, required this.accent, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 14),
            const SizedBox(height: 4),
            Text(mono ? value : value,
                style: mono
                    ? GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700, color: accent)
                    : GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
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

