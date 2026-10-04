import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/report_modal.dart';
import '../../widgets/app_state_view.dart';
import '../../models/proposal.dart';
import '../../services/proposal_service.dart';

class ProposalDetailScreen extends StatefulWidget {
  final String proposalId;
  final Proposal? proposal;
  const ProposalDetailScreen({
    super.key,
    required this.proposalId,
    this.proposal,
  });

  @override
  State<ProposalDetailScreen> createState() => _ProposalDetailScreenState();
}

class _ProposalDetailScreenState extends State<ProposalDetailScreen> {
  Proposal? _proposal;
  bool _loading = false;
  String? _loadError;
  bool _accepting = false;
  bool _rejecting = false;
  String _decision = ''; // '' | 'accepted' | 'rejected'

  @override
  void initState() {
    super.initState();
    _proposal = widget.proposal;
    if (_proposal == null) _loadProposal();
  }

  Future<void> _loadProposal() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final proposal = await ProposalService().getProposalById(
        int.parse(widget.proposalId),
      );
      if (mounted) {
        setState(() {
          _proposal = proposal;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = '$error';
          _loading = false;
        });
      }
    }
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      if (_proposal != null) {
        await ProposalService().updateProposalStatus(_proposal!.id, 'accepted');
      }
      if (!mounted) return;
      setState(() {
        _accepting = false;
        _decision = 'accepted';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _reject() async {
    setState(() => _rejecting = true);
    try {
      if (_proposal != null) {
        await ProposalService().updateProposalStatus(_proposal!.id, 'rejected');
      }
      if (!mounted) return;
      setState(() {
        _rejecting = false;
        _decision = 'rejected';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _rejecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: AppLoadingView(
          label: 'Opening proposal details…',
          color: AppColors.businessPrimary,
        ),
      );
    }
    if (_loadError != null || _proposal == null) {
      return Scaffold(
        body: AppStateView(
          icon: Icons.description_outlined,
          title: 'Proposal unavailable',
          message:
              'This proposal could not be opened. It may have been withdrawn or the connection may have changed.',
          accentColor: AppColors.error,
          actionLabel: 'Try again',
          actionIcon: Icons.refresh_rounded,
          onAction: _loadProposal,
        ),
      );
    }

    if (_decision.isNotEmpty || _proposal!.status != 'pending') {
      return _buildDecisionState(context);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.businessPrimary.withValues(alpha: 0.04),
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(context),
                  SliverToBoxAdapter(child: _buildStudentCard(context)),
                  SliverToBoxAdapter(child: _buildRateTimeline(context)),
                  SliverToBoxAdapter(child: _buildCoverLetter(context)),
                  if (_proposal!.attachedProjectId != null)
                    SliverToBoxAdapter(child: _buildAttachedProject(context)),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
            _buildActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionState(BuildContext context) {
    final status = _decision.isNotEmpty ? _decision : _proposal!.status;
    final accepted = status == 'accepted';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: accepted
                              ? [AppColors.success, const Color(0xFF34D399)]
                              : [AppColors.error, const Color(0xFFF87171)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (accepted ? AppColors.success : AppColors.error)
                                    .withValues(alpha: 0.4),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                      child: Icon(
                        accepted
                            ? Icons.handshake_rounded
                            : Icons.close_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: AppSpacing.xl),
                Text(
                      accepted ? 'Proposal Accepted!' : 'Proposal Rejected',
                      style: Theme.of(context).textTheme.displaySmall,
                    )
                    .animate()
                    .fadeIn(delay: 400.ms)
                    .slideY(begin: 0.2, delay: 400.ms),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  accepted
                      ? 'You accepted ${_proposal!.studentName ?? "Student"}. A chat has been opened — say hello!'
                      : 'This proposal has been rejected.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: AppSpacing.xxl),
                if (accepted)
                  AppButton(
                    label: 'Open Chat',
                    icon: Icons.chat_bubble_outline_rounded,
                    onPressed: () => context.go(
                      '/chat/${_proposal!.id}?name=${_proposal!.studentName ?? "Student"}',
                    ),
                  ).animate().fadeIn(delay: 650.ms)
                else
                  AppButton(
                    label: 'Back to Proposals',
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/business'),
                  ).animate().fadeIn(delay: 650.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: GestureDetector(
        onTap: () => context.canPop() ? context.pop() : context.go('/business'),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textSecondary,
            size: 14,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.outlined_flag_rounded,
            color: AppColors.textSecondary,
          ),
          tooltip: 'Report Proposal',
          onPressed: () => ReportModal.show(
            context,
            targetName: _proposal!.studentName ?? "Student",
            targetType: 'proposal',
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.studentPrimary, AppColors.studentAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.studentPrimary.withValues(alpha: 0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  (_proposal!.studentName != null &&
                          _proposal!.studentName!.isNotEmpty)
                      ? _proposal!.studentName![0]
                      : 'S',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _proposal!.studentName ?? "Student",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Student Profile',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () =>
                  context.go('/student/profile/${_proposal!.studentProfileId}'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.studentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: AppColors.studentPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'View Profile',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: AppColors.studentPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildRateTimeline(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _MetaTile(
            icon: Icons.payments_outlined,
            label: 'Proposed Rate',
            value: '₱${_proposal!.proposedBudget}',
            accent: AppColors.businessPrimary,
            mono: true,
          ),
          const SizedBox(width: AppSpacing.sm),
          _MetaTile(
            icon: Icons.timer_outlined,
            label: 'Timeline',
            value: '${_proposal!.estimatedTimelineWeeks} weeks',
            accent: AppColors.businessAccent,
          ),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
    );
  }

  Widget _buildCoverLetter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'Cover Letter'),
          const SizedBox(height: AppSpacing.md),
          Text(
            _proposal!.pitchText,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.75),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 180.ms),
    );
  }

  Widget _buildAttachedProject(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'Attached Portfolio Project'),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            onTap: () => context.go(
              '/student/portfolio/${_proposal!.attachedProjectId}',
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.studentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.studentPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View attached project',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted,
                  size: 12,
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 340.ms),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Decline',
              outlined: true,
              isLoading: _rejecting,
              onPressed: _reject,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Accept Proposal',
              icon: Icons.handshake_rounded,
              isLoading: _accepting,
              onPressed: _accept,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color accent;
  final bool mono;
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.mono = false,
  });

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
            Text(
              value,
              style: mono
                  ? GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    )
                  : GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
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
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.businessPrimary,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
