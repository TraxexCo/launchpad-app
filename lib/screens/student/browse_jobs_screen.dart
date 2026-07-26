import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../data/mock_data.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';

class BrowseJobsScreen extends StatefulWidget {
  const BrowseJobsScreen({super.key});

  @override
  State<BrowseJobsScreen> createState() => _BrowseJobsScreenState();
}

class _BrowseJobsScreenState extends State<BrowseJobsScreen> {
  final _searchCtrl = TextEditingController();
  String _activeFilter = 'All';
  String _sortBy = 'Newest';

  static const _filters = ['All', 'Mobile App', 'Web App', 'E-Commerce', 'POS', 'Digital Menu', 'Inventory'];
  static const _sorts = ['Newest', 'Budget ↑', 'Budget ↓', 'Nearest'];

  List<MockJob> get _filtered {
    var list = mockBrowseJobs.toList();
    if (_activeFilter != 'All') {
      list = list.where((j) => j.category == _activeFilter).toList();
    }
    if (_searchCtrl.text.isNotEmpty) {
      final q = _searchCtrl.text.toLowerCase();
      list = list.where((j) =>
        j.title.toLowerCase().contains(q) ||
        j.business.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.studentPrimary.withValues(alpha: 0.04),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildSearchBar(),
              _buildFilterRow(),
              _buildSortRow(),
              Expanded(child: _buildJobList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/student'),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Browse Jobs', style: Theme.of(context).textTheme.headlineSmall),
              Text('// ${_filtered.length} opportunities near you',
                  style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.studentPrimary)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/notifications?role=student'),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary, size: 20)),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.studentPrimary, shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.md),
            const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() {}),
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search jobs or businesses…',
                  hintStyle: GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _searchCtrl.clear()),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                ),
              ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms, delay: 80.ms),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, idx) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final f = _filters[i];
          final active = _activeFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = f),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
              decoration: BoxDecoration(
                color: active ? AppColors.studentPrimary.withValues(alpha: 0.15) : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: active ? AppColors.studentPrimary.withValues(alpha: 0.7) : AppColors.border,
                ),
                boxShadow: active
                    ? [BoxShadow(color: AppColors.studentPrimary.withValues(alpha: 0.15), blurRadius: 10)]
                    : null,
              ),
              child: Text(f,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? AppColors.studentPrimary : AppColors.textSecondary,
                  )),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 140.ms);
  }

  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text('${_filtered.length} jobs',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
          const Spacer(),
          const Icon(Icons.sort_rounded, color: AppColors.textMuted, size: 14),
          const SizedBox(width: 4),
          DropdownButton<String>(
            value: _sortBy,
            underline: const SizedBox(),
            isDense: true,
            dropdownColor: AppColors.surface,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 14),
            items: _sorts.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _sortBy = v!),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 180.ms);
  }

  Widget _buildJobList() {
    final jobs = _filtered;
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, color: AppColors.textMuted, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text('No jobs found', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Try a different filter or search term.',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      itemCount: jobs.length,
      separatorBuilder: (context, idx) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) => _JobCard(job: jobs[i])
          .animate()
          .fadeIn(duration: 400.ms, delay: Duration(milliseconds: i * 60))
          .slideY(begin: 0.1, duration: 350.ms, delay: Duration(milliseconds: i * 60)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Job Card
// ─────────────────────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final MockJob job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go('/student/jobs/${job.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.businessPrimary.withValues(alpha: 0.25),
                      AppColors.businessAccent.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.storefront_rounded, color: AppColors.businessPrimary, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(job.business,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                        if (job.isVerifiedBusiness) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, color: AppColors.studentPrimary, size: 14),
                        ],
                      ],
                    ),
                    Text(job.title,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(job.budget,
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.studentPrimary)),
                  Text('budget', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm + 2),

          // ── Description
          Text(job.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall),

          const SizedBox(height: AppSpacing.md),

          // ── Tags row
          Wrap(
            spacing: AppSpacing.xs + 2,
            runSpacing: AppSpacing.xs,
            children: job.skills.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.studentPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(s, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.studentPrimary)),
            )).toList(),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Footer row
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 12),
              const SizedBox(width: 3),
              Text(job.distance,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: AppSpacing.md),
              const Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 12),
              const SizedBox(width: 3),
              Text(job.postedAgo,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: job.urgency == 'Urgent'
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: job.urgency == 'Urgent'
                        ? AppColors.error.withValues(alpha: 0.4)
                        : AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(job.urgency,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: job.urgency == 'Urgent' ? AppColors.error : AppColors.success,
                    )),
              ),
              const SizedBox(width: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 12),
                  const SizedBox(width: 3),
                  Text('${job.proposals} pitches',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


