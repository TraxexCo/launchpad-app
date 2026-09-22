import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

import '../../models/job_post.dart';
import '../../models/proposal.dart';
import '../../services/job_service.dart';
import '../../services/proposal_service.dart';

class JobProposalsScreen extends StatefulWidget {
  final String jobId;
  const JobProposalsScreen({super.key, required this.jobId});

  @override
  State<JobProposalsScreen> createState() => _JobProposalsScreenState();
}

class _JobProposalsScreenState extends State<JobProposalsScreen> {
  String _sort = 'Newest';
  JobPost? _job;
  List<Proposal> _proposals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final jId = int.parse(widget.jobId);
      final job = await JobService().getJobById(jId);
      final proposals = await ProposalService().getProposalsByJob(jId);
      if (mounted) {
        setState(() {
          _job = job;
          _proposals = proposals;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _sortProposals() {
    if (_sort == 'Newest') {
      _proposals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sort == 'Lowest Rate') {
      _proposals.sort((a, b) => (double.tryParse(a.proposedBudget) ?? 0)
          .compareTo(double.tryParse(b.proposedBudget) ?? 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sort != 'Newest') _sortProposals(); // Sort before building if changed

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.businessPrimary.withValues(alpha: 0.04),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              if (_job != null) _buildJobSummary(context),
              _buildSortRow(context),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.businessPrimary))
                    : _proposals.isEmpty
                        ? Center(child: Text('No proposals yet', style: Theme.of(context).textTheme.bodyMedium))
                        : _buildList(),
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
            onTap: () => context.canPop() ? context.pop() : context.go('/business'),
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
              Text('Proposals', style: Theme.of(context).textTheme.headlineSmall),
              if (!_loading)
                Text('// ${_proposals.length} pitches received',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: AppColors.businessPrimary)),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildJobSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.businessPrimary, AppColors.businessAccent],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.work_outline_rounded, color: AppColors.textPrimary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_job!.title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('₱${_job!.budget}',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 12, color: AppColors.businessPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            StatusBadge(label: _job!.urgency, color: _job!.urgency == 'Urgent' ? AppColors.error : AppColors.success),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms, delay: 80.ms),
    );
  }

  Widget _buildSortRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Text('Sort by:', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(width: AppSpacing.sm),
          DropdownButton<String>(
            value: _sort,
            underline: const SizedBox(),
            isDense: true,
            dropdownColor: AppColors.surface,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 14),
            items: ['Newest', 'Lowest Rate']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              setState(() => _sort = v!);
            },
          ),
        ],
      ).animate().fadeIn(duration: 400.ms, delay: 140.ms),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      itemCount: _proposals.length,
      separatorBuilder: (context, idx) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final p = _proposals[i];
        return _ProposalCard(proposal: p, job: _job!)
            .animate()
            .fadeIn(duration: 350.ms, delay: Duration(milliseconds: i * 70))
            .slideY(begin: 0.08, duration: 300.ms, delay: Duration(milliseconds: i * 70));
      },
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final Proposal proposal;
  final JobPost job;
  const _ProposalCard({required this.proposal, required this.job});

  @override
  Widget build(BuildContext context) {
    // We don't have skills natively on proposals right now from the backend, so we leave it empty.
    return AppCard(
      onTap: () => context.go('/business/proposals/${proposal.id}', extra: proposal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.studentPrimary, AppColors.studentAccent],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.studentPrimary.withValues(alpha: 0.3), blurRadius: 12)],
                ),
                child: Center(
                  child: Text(
                    (proposal.studentName != null && proposal.studentName!.isNotEmpty) ? proposal.studentName![0] : 'S',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(proposal.studentName ?? 'Student',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('View student details...',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge.fromApiStatus(proposal.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(proposal.pitchText,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Pill(label: '₱${proposal.proposedBudget}', color: AppColors.businessPrimary, icon: Icons.payments_outlined),
              const SizedBox(width: AppSpacing.sm),
              _Pill(label: '${proposal.estimatedTimelineWeeks} weeks', color: AppColors.businessAccent, icon: Icons.timer_outlined),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Pill({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}



