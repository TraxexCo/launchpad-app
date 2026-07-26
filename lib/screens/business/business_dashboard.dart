import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/status_badge.dart';

class BusinessDashboard extends StatefulWidget {
  const BusinessDashboard({super.key});

  @override
  State<BusinessDashboard> createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends State<BusinessDashboard> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.businessPrimary.withValues(alpha: 0.04),
        child: SafeArea(
          child: Column(
            children: [
              _BizAppBar(onLogout: () => context.go('/onboarding')),
              Expanded(
                child: IndexedStack(
                  index: _navIndex,
                  children: const [
                    _BizHomeTab(),
                    _BizJobsTab(),
                    _BizProposalsTab(),
                    _BizProfileTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BizBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────
class _BizAppBar extends StatelessWidget {
  final VoidCallback onLogout;
  const _BizAppBar({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          // Business avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.businessGradient(),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: AppColors.businessPrimary.withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
          ),

          const SizedBox(width: AppSpacing.sm + 2),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BAMBOU Café',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5)),
              StatusBadge.verified(),
            ],
          ),

          const Spacer(),

          _BizIconBtn(icon: Icons.notifications_none_rounded, onTap: () => context.go('/notifications?role=business')),
          const SizedBox(width: AppSpacing.sm),
          _BizIconBtn(icon: Icons.settings_outlined, onTap: () => context.go('/settings?role=business')),
        ],
      ),
    );
  }
}

class _BizIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BizIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Navigation
// ─────────────────────────────────────────────────────────────────────────────
class _BizBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const _BizBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.work_rounded, Icons.work_outline_rounded, 'Jobs'),
    (Icons.inbox_rounded, Icons.inbox_outlined, 'Proposals'),
    (Icons.storefront_rounded, Icons.storefront_outlined, 'Business'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items.asMap().entries.map((e) {
              final isActive = e.key == currentIndex;
              return GestureDetector(
                onTap: () => onTap(e.key),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppDurations.normal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.businessPrimary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? e.value.$1 : e.value.$2,
                        color: isActive
                            ? AppColors.businessPrimary
                            : AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(e.value.$3,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive
                                ? AppColors.businessPrimary
                                : AppColors.textMuted,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0 — Home
// ─────────────────────────────────────────────────────────────────────────────
class _BizHomeTab extends StatelessWidget {
  const _BizHomeTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.sm),

        // ── Welcome
        Text('Welcome back,',
            style: Theme.of(context).textTheme.bodyLarge)
            .animate().fadeIn(duration: 400.ms),
        Text('BAMBOU Café ☕',
            style: Theme.of(context).textTheme.headlineMedium)
            .animate().fadeIn(duration: 500.ms, delay: 80.ms)
            .slideY(begin: 0.15),

        const SizedBox(height: AppSpacing.lg),

        // ── Stats row
        Row(
          children: [
            _BizStatCard(label: 'Active Jobs', value: '3', color: AppColors.businessPrimary),
            const SizedBox(width: AppSpacing.sm),
            _BizStatCard(label: 'Proposals', value: '11', color: AppColors.businessAccent),
            const SizedBox(width: AppSpacing.sm),
            _BizStatCard(label: 'Hired', value: '2', color: AppColors.success),
          ],
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 200.ms)
            .slideY(begin: 0.1, duration: 400.ms, delay: 200.ms),

        const SizedBox(height: AppSpacing.xl),

        // ── Post a job CTA
        _PostJobCard()
            .animate()
            .fadeIn(duration: 500.ms, delay: 350.ms)
            .slideY(begin: 0.1, duration: 400.ms, delay: 350.ms),

        const SizedBox(height: AppSpacing.xl),

        // ── Active jobs section
        _BizSectionHeader(
            title: 'Active Jobs', action: 'View all', onAction: () => context.go('/business/jobs/1/proposals')),
        const SizedBox(height: AppSpacing.md),
        ...mockBusinessJobs.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _JobCard(job: e.value)
                  .animate()
                  .fadeIn(
                      duration: 400.ms,
                      delay: Duration(milliseconds: 450 + e.key * 100))
                  .slideY(
                      begin: 0.1,
                      duration: 350.ms,
                      delay: Duration(milliseconds: 450 + e.key * 100)),
            )),

        const SizedBox(height: AppSpacing.xl),

        // ── Recent proposals
        _BizSectionHeader(
            title: 'Recent Proposals', action: 'See all', onAction: () => context.go('/business/jobs/1/proposals')),
        const SizedBox(height: AppSpacing.md),
        ...mockIncomingProposals.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _IncomingProposalCard(proposal: e.value)
                  .animate()
                  .fadeIn(
                      duration: 400.ms,
                      delay: Duration(milliseconds: 700 + e.key * 80)),
            )),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Jobs
// ─────────────────────────────────────────────────────────────────────────────
class _BizJobsTab extends StatelessWidget {
  const _BizJobsTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text('My Job Posts',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              AppButton.business(
                label: '+ Post Job',
                isExpanded: false,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              itemCount: mockBusinessJobs.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _JobCard(job: mockBusinessJobs[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Proposals inbox
// ─────────────────────────────────────────────────────────────────────────────
class _BizProposalsTab extends StatelessWidget {
  const _BizProposalsTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text('Proposals Inbox',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('${mockIncomingProposals.length} proposals received',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.separated(
              itemCount: mockIncomingProposals.length,
              separatorBuilder: (context, idx) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) =>
                  _IncomingProposalCard(proposal: mockIncomingProposals[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — Business Profile
// ─────────────────────────────────────────────────────────────────────────────
class _BizProfileTab extends StatelessWidget {
  const _BizProfileTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),

          // ── Business avatar hero
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: AppTheme.businessGradient(),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.businessPrimary.withValues(alpha: 0.4),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: AppColors.textPrimary, size: 40),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: const Icon(Icons.verified_rounded,
                      color: Colors.white, size: 14),
                ),
              ],
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          ),

          const SizedBox(height: AppSpacing.md),
          Text('BAMBOU Greenhouse Café',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text('123 Rizal St., Brgy. San Antonio, Manila',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          StatusBadge.verified(),

          const SizedBox(height: AppSpacing.xl),

          // ── Business info cards
          _BizInfoRow(icon: Icons.category_outlined, label: 'Category', value: 'Café / Restaurant'),
          const SizedBox(height: AppSpacing.sm),
          _BizInfoRow(icon: Icons.phone_outlined, label: 'Contact', value: '+63 912 345 6789'),
          const SizedBox(height: AppSpacing.sm),
          _BizInfoRow(icon: Icons.location_on_outlined, label: 'Coordinates', value: '14.5995° N, 120.9842° E'),

          const SizedBox(height: AppSpacing.xl),

          // ── Verification details
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_rounded,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Text('KYB Verification',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _VerificationRow(
                    icon: Icons.receipt_long_rounded,
                    label: 'DTI Permit',
                    done: true),
                const SizedBox(height: AppSpacing.sm),
                _VerificationRow(
                    icon: Icons.add_a_photo_rounded,
                    label: 'Storefront Photo',
                    done: true),
                const SizedBox(height: AppSpacing.sm),
                _VerificationRow(
                    icon: Icons.gps_fixed_rounded,
                    label: 'GPS Verified',
                    done: true),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _BizInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _BizInfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.businessPrimary, size: 18),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: AppColors.textMuted)),
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerificationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;
  const _VerificationRow({required this.icon, required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: done ? AppColors.success : AppColors.textMuted,
          size: 18,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _BizSectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;
  const _BizSectionHeader({required this.title, required this.action, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Text(action,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.businessPrimary,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _BizStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BizStatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 28, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 9, color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PostJobCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/business/post-job'),
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.businessPrimary, AppColors.businessAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.businessPrimary.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Post a New Job',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Connect with student developers\nready to build for your business.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary, height: 1.45),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: AppColors.textPrimary, size: 16),
                      const SizedBox(width: 6),
                      Text('Post Job Now',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(Icons.work_rounded,
                color: Colors.white, size: 34),
          ),
        ],
      ),
    ),  // Container
    );  // GestureDetector
  }
}


class _JobCard extends StatelessWidget {
  final MockBusinessJob job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go('/business/jobs/1/proposals'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.businessPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(job.icon,
                    color: AppColors.businessPrimary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('${job.proposals} proposals received',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
              // Budget badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.businessPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                      color: AppColors.businessPrimary.withValues(alpha: 0.3)),
                ),
                child: Text(job.budget,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.businessPrimary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(job.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _IncomingProposalCard extends StatelessWidget {
  final MockIncomingProposal proposal;
  const _IncomingProposalCard({required this.proposal});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {},
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.studentPrimary, AppColors.studentAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(proposal.initials,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
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
                      child: Text(proposal.studentName,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (proposal.isVerifiedStudent) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: AppColors.studentPrimary, size: 14),
                    ],
                  ],
                ),
                Text('${proposal.skill} • ${proposal.budget}',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge.fromProposal(proposal.status),
              const SizedBox(height: 4),
              Text(proposal.timeAgo,
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA





