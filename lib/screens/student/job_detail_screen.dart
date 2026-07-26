import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/skill_chip.dart';
import '../../widgets/report_modal.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _bookmarked = false;
  final _job = _mockJobs['1']!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.studentPrimary.withValues(alpha: 0.04),
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(context),
                  SliverToBoxAdapter(child: _buildBusinessCard()),
                  SliverToBoxAdapter(child: _buildJobMeta()),
                  SliverToBoxAdapter(child: _buildDescription()),
                  SliverToBoxAdapter(child: _buildRequirements()),
                  SliverToBoxAdapter(child: _buildSkillsSection()),
                  SliverToBoxAdapter(child: _buildTimeline()),
                  SliverToBoxAdapter(child: _buildAboutBusiness()),
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
        onTap: () => context.go('/student/jobs'),
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
          onPressed: () => ReportModal.show(context, targetName: _job['title'] as String, targetType: 'job'),
        ),
        GestureDetector(
          onTap: () => setState(() => _bookmarked = !_bookmarked),
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
                    child: Text('// ${_job['category']}',
                        style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.businessPrimary)),
                  ),
                  const SizedBox(height: 5),
                  Text(_job['business'] as String,
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 12),
                      const SizedBox(width: 3),
                      Text(_job['location'] as String,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(Icons.verified_rounded, color: AppColors.success, size: 12),
                      const SizedBox(width: 3),
                      Text('Verified', style: GoogleFonts.inter(fontSize: 12, color: AppColors.success)),
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
          Text(_job['title'] as String,
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _MetaTile(icon: Icons.payments_outlined, label: 'Budget',
                  value: _job['budget'] as String, accent: AppColors.studentPrimary, mono: true),
              const SizedBox(width: AppSpacing.sm),
              _MetaTile(icon: Icons.access_time_rounded, label: 'Deadline',
                  value: _job['deadline'] as String, accent: AppColors.studentAccent),
              const SizedBox(width: AppSpacing.sm),
              _MetaTile(icon: Icons.people_outline_rounded, label: 'Pitches',
                  value: '${_job['proposals']} sent', accent: AppColors.warning),
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
          Text(_job['description'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7)),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 180.ms),
    );
  }

  Widget _buildRequirements() {
    final reqs = _job['requirements'] as List<String>;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'What\'s Needed'),
          const SizedBox(height: AppSpacing.md),
          ...reqs.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.studentPrimary, shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(e.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5))),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: 250 + e.key * 60))),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    final skills = _job['skills'] as List<String>;
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
                Text(_job['timeline'] as String,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Posted', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                Text(_job['posted'] as String,
                    style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms, delay: 420.ms),
    );
  }

  Widget _buildAboutBusiness() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'About the Business'),
          const SizedBox(height: AppSpacing.md),
          Text(_job['about'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _StatPill(icon: Icons.star_rounded, value: '4.8', label: 'Rating', color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              _StatPill(icon: Icons.check_circle_outline, value: '3', label: 'Projects Done', color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              _StatPill(icon: Icons.timer_outlined, value: '1d', label: 'Avg Reply', color: AppColors.info),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 480.ms),
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
              onPressed: () => context.go(
                '/student/jobs/${widget.jobId}/pitch',
                extra: {'title': _job['title']},
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

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatPill({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 3),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock Data
// ─────────────────────────────────────────────────────────────────────────────
final _mockJobs = <String, Map<String, dynamic>>{
  '1': {
    'id': '1', 'title': 'Online Ordering App',
    'business': 'BAMBOU Greenhouse Café',
    'category': 'Mobile App',
    'location': 'Brgy. Pinyahan, QC · 0.3 km away',
    'budget': '₱12,000',
    'deadline': 'Aug 10, 2025',
    'timeline': '3–4 weeks',
    'posted': '2 hours ago',
    'proposals': 4,
    'description': 'We need a Flutter mobile app for customers to browse our full menu, add items to cart, choose pickup time, and pay via GCash or cash on pickup. The app should feel modern — matching our café branding (earthy greens, warm whites). Customers should receive an in-app notification when their order is ready.',
    'requirements': [
      'Flutter/Dart mobile app (iOS + Android)',
      'Browse menu by category (drinks, pastries, meals)',
      'Cart and checkout with pickup time scheduling',
      'GCash and cash-on-pickup payment options',
      'Order status push notifications',
      'Simple admin panel to mark orders as ready',
    ],
    'skills': ['Flutter', 'Dart', 'Firebase', 'PHP', 'MySQL'],
    'about': "BAMBOU Greenhouse Café is a cozy urban café located in QC known for our plant-filled interior, specialty coffee, and homemade pastries. We've been operating for 3 years and serve 100+ customers daily. We want to go digital to reduce queuing and serve takeout customers better.",
  },
};



