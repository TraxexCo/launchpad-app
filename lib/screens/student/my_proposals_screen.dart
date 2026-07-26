import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
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
              Expanded(child: _buildTabViews()),
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
            onTap: () => context.go('/student'),
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
          _StatCard(value: '${_all.length}', label: 'Total', color: AppColors.studentPrimary),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
              value: '${_all.where((p) => p.status == ProposalStatus.sent).length}',
              label: 'Pending',
              color: AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
              value: '${_all.where((p) => p.status == ProposalStatus.accepted).length}',
              label: 'Accepted',
              color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
              value: '${_all.where((p) => p.status == ProposalStatus.rejected).length}',
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
        _ProposalList(proposals: _all),
        _ProposalList(proposals: _all.where((p) => p.status == ProposalStatus.sent).toList()),
        _ProposalList(proposals: _all.where((p) => p.status == ProposalStatus.accepted).toList()),
        _ProposalList(proposals: _all.where((p) => p.status == ProposalStatus.rejected).toList()),
      ],
    );
  }
}

class _ProposalList extends StatelessWidget {
  final List<_MockProposal> proposals;
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
  final _MockProposal proposal;
  const _ProposalCard({required this.proposal});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: proposal.status == ProposalStatus.accepted
          ? () => context.go('/chat/${proposal.id}?name=${proposal.business}')
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
                    Text(proposal.business,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textMuted)),
                    Text(proposal.jobTitle,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              StatusBadge.fromProposal(proposal.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(proposal.coverSnippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Pill(
                  icon: Icons.payments_outlined,
                  value: proposal.rate,
                  color: AppColors.studentPrimary),
              const SizedBox(width: AppSpacing.sm),
              _Pill(
                  icon: Icons.timer_outlined,
                  value: proposal.timeline,
                  color: AppColors.studentAccent),
              const Spacer(),
              Text(proposal.sentAgo,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
          if (proposal.status == ProposalStatus.accepted) ...[  
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
                  Text('Tap to open chat with ${proposal.business}',
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

class _MockProposal {
  final String id, business, jobTitle, coverSnippet, rate, timeline, sentAgo;
  final ProposalStatus status;
  const _MockProposal({
    required this.id,
    required this.business,
    required this.jobTitle,
    required this.coverSnippet,
    required this.rate,
    required this.timeline,
    required this.sentAgo,
    required this.status,
  });
}

const _all = [
  _MockProposal(
    id: '1', business: 'BAMBOU Greenhouse Café', jobTitle: 'Online Ordering App',
    coverSnippet: 'Hi! I am a 3rd year CS student at PUP Manila with 2 years of Flutter experience. I have built 3 complete mobile apps...',
    rate: '₱11,500', timeline: '3 weeks', sentAgo: '2h ago', status: ProposalStatus.sent,
  ),
  _MockProposal(
    id: '2', business: 'Mang Juan\'s Hardware', jobTitle: 'Inventory Management System',
    coverSnippet: 'I specialize in Laravel + MySQL systems and have built a similar inventory system for a school project...',
    rate: '₱14,000', timeline: '4 weeks', sentAgo: '1d ago', status: ProposalStatus.accepted,
  ),
  _MockProposal(
    id: '3', business: 'Ate Rose\'s Ukay-Ukay', jobTitle: 'E-Commerce Website',
    coverSnippet: 'I can build a full e-commerce site using Next.js with GCash integration...',
    rate: '₱18,000', timeline: '5 weeks', sentAgo: '3d ago', status: ProposalStatus.rejected,
  ),
  _MockProposal(
    id: '4', business: 'Beans & Brew Coffee', jobTitle: 'Customer Loyalty App',
    coverSnippet: 'I built a loyalty rewards module for my capstone project — I can adapt it for your café...',
    rate: '₱13,000', timeline: '3 weeks', sentAgo: '5d ago', status: ProposalStatus.sent,
  ),
];


