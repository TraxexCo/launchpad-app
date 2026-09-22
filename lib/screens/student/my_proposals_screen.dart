import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../services/proposal_service.dart';
import '../../models/proposal.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class MyProposalsScreen extends StatefulWidget {
  const MyProposalsScreen({super.key});

  @override
  State<MyProposalsScreen> createState() => _MyProposalsScreenState();
}

class _MyProposalsScreenState extends State<MyProposalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  List<Proposal> _allProposals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _loadProposals();
  }

  Future<void> _loadProposals() async {
    try {
      final proposals = await ProposalService().getMyProposals();
      if (mounted) setState(() { _allProposals = proposals; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tab.dispose();
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
              _buildStats(),
              _buildTabBar(),
              Expanded(child: _loading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.studentPrimary))
                : _buildTabViews()),
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
              width: 40,
              height: 40,
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
              Text('My Pitches',
                  style: Theme.of(context).textTheme.headlineSmall),
              Text('// proposal.tracker',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: AppColors.studentPrimary)),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          _StatCard(value: '${_allProposals.length}', label: 'Total', color: AppColors.studentPrimary),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
              value: '${_allProposals.where((p) => p.status == 'pending').length}',
              label: 'Pending',
              color: AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
              value: '${_allProposals.where((p) => p.status == 'accepted').length}',
              label: 'Accepted',
              color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
              value: '${_allProposals.where((p) => p.status == 'rejected').length}',
              label: 'Rejected',
              color: AppColors.error),
        ],
      ).animate().fadeIn(duration: 400.ms, delay: 80.ms),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: TabBar(
          controller: _tab,
          labelStyle:
              GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
          labelColor: AppColors.studentPrimary,
          unselectedLabelColor: AppColors.textMuted,
          indicator: BoxDecoration(
            color: AppColors.studentPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 140.ms);
  }

  Widget _buildTabViews() {
    return TabBarView(
      controller: _tab,
      children: [
        _ProposalList(proposals: _allProposals),
        _ProposalList(proposals: _allProposals.where((p) => p.status == 'pending').toList()),
        _ProposalList(proposals: _allProposals.where((p) => p.status == 'accepted').toList()),
        _ProposalList(proposals: _allProposals.where((p) => p.status == 'rejected').toList()),
      ],
    );
  }
}

class _ProposalList extends StatelessWidget {
  final List<Proposal> proposals;
  const _ProposalList({required this.proposals});

  @override
  Widget build(BuildContext context) {
    if (proposals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, color: AppColors.textMuted, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text('No proposals here', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      itemCount: proposals.length,
      separatorBuilder: (context, idx) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) => _ProposalCard(proposal: proposals[i])
          .animate()
          .fadeIn(duration: 350.ms, delay: Duration(milliseconds: i * 60))
          .slideY(begin: 0.08, duration: 300.ms, delay: Duration(milliseconds: i * 60)),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final Proposal proposal;
  const _ProposalCard({required this.proposal});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: proposal.status == 'accepted'
          ? () => context.go('/chat/${proposal.id}?name=${Uri.encodeComponent(proposal.jobTitle ?? 'Job')}')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.businessPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: AppColors.businessPrimary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Business', // mock as API doesn't return business name on student side yet
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textMuted)),
                    Text(proposal.jobTitle ?? 'Job',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              StatusBadge.fromApiStatus(proposal.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(proposal.pitchText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Pill(
                  icon: Icons.payments_outlined,
                  value: '₱${proposal.proposedBudget}',
                  color: AppColors.studentPrimary),
              const SizedBox(width: AppSpacing.sm),
              _Pill(
                  icon: Icons.timer_outlined,
                  value: '${proposal.estimatedTimelineWeeks}w',
                  color: AppColors.studentAccent),
              const Spacer(),
              Text(_timeAgo(proposal.createdAt),
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
          if (proposal.status == 'accepted') ...[  
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border:
                    Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      color: AppColors.success, size: 14),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Tap to open chat',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.success)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _Pill({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
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
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatCard(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm + 2, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style:
                    GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}


