import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../services/job_service.dart';
import '../../services/proposal_service.dart';
import '../../services/auth_service.dart';
import '../../services/contract_service.dart';
import '../../services/review_service.dart';
import '../../services/github_api_service.dart';
import '../../models/job_post.dart';
import '../../models/proposal.dart';
import '../../core/theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/skill_chip.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/confirm_sign_out.dart';
import '../../widgets/contract_action_panel.dart';
import '../../widgets/dashboard_load_error.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/nearby_business_radar.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _navIndex = 0;
  String _name = 'Student';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          GoRouterState.of(context).uri.queryParameters['unauthorized'] ==
              '1') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unauthorized: this area is for business accounts.'),
          ),
        );
      }
    });
    AuthService().getCurrentUser().then((user) {
      if (mounted && user != null) setState(() => _name = user.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.studentPrimary.withValues(alpha: 0.04),
        child: SafeArea(
          child: Column(
            children: [
              _AppBar(name: _name, onLogout: () => confirmSignOut(context)),
              Expanded(
                child: IndexedStack(
                  index: _navIndex,
                  children: [
                    _HomeTab(
                      name: _name,
                      onNavigate: (i) => setState(() => _navIndex = i),
                    ),
                    const _RadarTab(),
                    const _PortfolioTab(),
                    const _ProfileTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final String name;
  final VoidCallback onLogout;
  const _AppBar({required this.name, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.studentGradient(),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: AppColors.studentPrimary.withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: Text(
                name
                    .split(' ')
                    .where((part) => part.isNotEmpty)
                    .take(2)
                    .map((part) => part[0])
                    .join()
                    .toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm + 2),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LaunchPad',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                name,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Notification bell
          const NotificationBell(
            role: UserRole.student,
            accentColor: AppColors.studentPrimary,
          ),
          const SizedBox(width: AppSpacing.sm),
          _IconBtn(
            icon: Icons.settings_outlined,
            onTap: () => context.go('/settings?role=student'),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

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
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.radar_rounded, Icons.radar_rounded, 'Radar'),
    (Icons.grid_view_rounded, Icons.grid_view_outlined, 'Portfolio'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
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
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.studentPrimary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? e.value.$1 : e.value.$2,
                        color: isActive
                            ? AppColors.studentPrimary
                            : AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.value.$3,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? AppColors.studentPrimary
                              : AppColors.textMuted,
                        ),
                      ),
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

class _HomeTab extends StatefulWidget {
  final String name;
  final ValueChanged<int> onNavigate;
  const _HomeTab({required this.name, required this.onNavigate});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<JobPost> _jobs = [];
  List<Proposal> _proposals = [];
  List<ContractItem> _contracts = [];
  int _projectCount = 0;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final futures = await Future.wait([
        JobService().getAllJobs(),
        ProposalService().getMyProposals(),
        ContractService().getMyContracts(),
        if (userId != null)
          Supabase.instance.client
              .from('portfolio_projects')
              .select('id')
              .eq('student_id', userId)
        else
          Future.value(<Map<String, dynamic>>[]),
      ]);
      if (mounted) {
        setState(() {
          _jobs = futures[0] as List<JobPost>;
          _proposals = futures[1] as List<Proposal>;
          _contracts = futures[2] as List<ContractItem>;
          _projectCount = (futures[3] as List).length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.sm),

        _StudentLaunchHero(
          name: widget.name.split(' ').first,
          projects: _projectCount,
          pitches: _proposals.length,
          activeMissions: _contracts
              .where((contract) => contract.status != 'completed')
              .length,
          loading: _loading,
          onBrowse: () => context.go('/student/jobs'),
          onPortfolio: () => widget.onNavigate(2),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08),

        if (_loadFailed) ...[
          const SizedBox(height: AppSpacing.md),
          DashboardLoadError(onRetry: _loadData),
        ],

        // ── Project workspaces
        if (_contracts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(
            title: 'Project Workspaces',
            action: '${_contracts.length} total',
            onAction: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          ..._contracts.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            c.jobTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: contractStatusColor(
                              c.status,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: contractStatusColor(
                                c.status,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            contractStatusLabel(c.status),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: contractStatusColor(c.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Client: ${c.businessName} · ₱${c.budget.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push(
                            '/chat/${c.proposalId}?name=${c.businessName}',
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs + 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.studentPrimary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: AppColors.studentPrimary.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 14,
                                  color: AppColors.studentPrimary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Open Workspace Chat',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.studentPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ContractActionPanel(
                      contract: c,
                      studentView: true,
                      onChanged: _loadData,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        // ── Radar teaser
        _SectionHeader(
          title: 'Local Radar',
          action: 'View all',
          onAction: () => widget.onNavigate(1),
        ),
        const SizedBox(height: AppSpacing.md),
        _RadarPreview(onNavigate: () => widget.onNavigate(1)),

        const SizedBox(height: AppSpacing.xl),

        // ── Browse Jobs CTA
        _SectionHeader(
          title: 'Open Jobs Near You',
          action: 'Browse all',
          onAction: () => context.go('/student/jobs'),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(color: AppColors.studentPrimary),
            ),
          ),
        if (!_loading && _jobs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'No open jobs',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ..._jobs.take(3).toList().asMap().entries.map((e) {
          final job = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child:
                AppCard(
                  onTap: () => context.go('/student/jobs/${job.id}'),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.businessPrimary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          Icons.work_outline_rounded,
                          color: AppColors.businessPrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              job.businessName ?? 'Business',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            job.budget,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.studentPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: job.urgency == 'Urgent'
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : AppColors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              job.urgency,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: job.urgency == 'Urgent'
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(
                  duration: 400.ms,
                  delay: Duration(milliseconds: 500 + e.key * 80),
                ),
          );
        }),

        const SizedBox(height: AppSpacing.xl),

        // ── Portfolio preview
        _SectionHeader(
          title: 'My Portfolio',
          action: 'Add project',
          onAction: () => context.go('/student/portfolio/add'),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'No projects in portfolio yet.',
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Active proposals
        _SectionHeader(
          title: 'Active Proposals',
          action: 'See all',
          onAction: () => context.go('/student/proposals'),
        ),

        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(color: AppColors.studentPrimary),
            ),
          ),
        if (!_loading && _proposals.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'No active proposals',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),

        ..._proposals
            .take(3)
            .toList()
            .asMap()
            .entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ProposalCard(proposal: e.value)
                    .animate()
                    .fadeIn(
                      duration: 400.ms,
                      delay: Duration(milliseconds: 700 + e.key * 80),
                    )
                    .slideY(
                      begin: 0.1,
                      duration: 300.ms,
                      delay: Duration(milliseconds: 700 + e.key * 80),
                    ),
              ),
            ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _StudentLaunchHero extends StatelessWidget {
  final String name;
  final int projects;
  final int pitches;
  final int activeMissions;
  final bool loading;
  final VoidCallback onBrowse;
  final VoidCallback onPortfolio;

  const _StudentLaunchHero({
    required this.name,
    required this.projects,
    required this.pitches,
    required this.activeMissions,
    required this.loading,
    required this.onBrowse,
    required this.onPortfolio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF241B4A), Color(0xFF10192A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.studentPrimary.withValues(alpha: 0.34),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(34),
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -34,
            top: -38,
            child: _OrbitGlyph(color: AppColors.studentAccent),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.studentAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.studentAccent,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'STUDENT FLIGHT DECK  /  ONLINE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                        color: AppColors.studentAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ready for launch,\n$name?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 27,
                    height: 1.04,
                    letterSpacing: -1.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    _HeroMetric(
                      value: loading ? '—' : '$activeMissions',
                      label: 'LIVE MISSIONS',
                      color: AppColors.success,
                    ),
                    _HeroMetric(
                      value: loading ? '—' : '$pitches',
                      label: 'PITCHES',
                      color: AppColors.studentAccent,
                    ),
                    _HeroMetric(
                      value: loading ? '—' : '$projects',
                      label: 'BUILDS',
                      color: AppColors.signalYellow,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onBrowse,
                        icon: const Icon(Icons.radar_rounded, size: 18),
                        label: const Text('Find a mission'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.outlined(
                      tooltip: 'Open portfolio',
                      onPressed: onPortfolio,
                      icon: const Icon(Icons.grid_view_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _HeroMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.30),
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 7,
              letterSpacing: 0.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    ),
  );
}

class _OrbitGlyph extends StatelessWidget {
  final Color color;
  const _OrbitGlyph({required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    height: 180,
    child: CustomPaint(painter: _OrbitGlyphPainter(color)),
  );
}

class _OrbitGlyphPainter extends CustomPainter {
  final Color color;
  const _OrbitGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.18);
    for (final radius in [30.0, 54.0, 78.0]) {
      canvas.drawCircle(center, radius, paint);
    }
    canvas.drawLine(
      Offset(center.dx - 90, center.dy),
      Offset(center.dx + 90, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 90),
      Offset(center.dx, center.dy + 90),
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx - 42, center.dy + 33),
      4,
      Paint()..color = color.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Radar (full view)
// ─────────────────────────────────────────────────────────────────────────────
class _RadarTab extends StatelessWidget {
  const _RadarTab();

  @override
  Widget build(BuildContext context) => const NearbyBusinessRadar();
}

// Kept temporarily so existing static-map installations can be compared during
// rollout. The active Radar above uses GPS and an interactive map.
// ignore: unused_element
class _LegacyRadarTab extends StatefulWidget {
  const _LegacyRadarTab();

  @override
  State<_LegacyRadarTab> createState() => _LegacyRadarTabState();
}

class _LegacyRadarTabState extends State<_LegacyRadarTab> {
  static const _mapboxToken = String.fromEnvironment('MAPBOX_PUBLIC_TOKEN');
  List<Map<String, dynamic>> _businesses = [];
  bool _loading = true;
  String? _error;
  int _selectedIndex = 0;
  int _zoom = 13;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    try {
      final rows = await Supabase.instance.client
          .from('business_profiles')
          .select(
            'user_id, business_name, address, category, phone, latitude, longitude',
          )
          .order('business_name');
      if (mounted) {
        setState(() {
          _businesses = List<Map<String, dynamic>>.from(rows);
          _selectedIndex = 0;
          _error = null;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _businesses = [];
          _error = 'Could not load businesses: $error';
          _loading = false;
        });
      }
    }
  }

  Uri? get _mapUrl {
    if (_mapboxToken.isEmpty) return null;
    final located = _businesses
        .where(
          (business) =>
              business['latitude'] is num && business['longitude'] is num,
        )
        .take(20)
        .toList();
    if (located.isEmpty) return null;
    final selected = _businesses[_selectedIndex];
    final center = selected['latitude'] is num && selected['longitude'] is num
        ? selected
        : located.first;
    final markers = located
        .map(
          (business) =>
              'pin-s+14b8a6(${business['longitude']},${business['latitude']})',
        )
        .join(',');
    return Uri.parse(
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/'
      '$markers/${center['longitude']},${center['latitude']},$_zoom/600x300'
      '?access_token=${Uri.encodeQueryComponent(_mapboxToken)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Local Radar',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Businesses in the LaunchPad directory.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.studentPrimary,
                  size: 20,
                ),
                onPressed: _loading ? null : _loadBusinesses,
                tooltip: 'Scan for businesses',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Expanded(
            flex: 3,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _mapboxToken.isEmpty
                ? const Center(
                    child: Text(
                      'Add MAPBOX_PUBLIC_TOKEN to your app build to show the map.',
                    ),
                  )
                : _mapUrl == null
                ? const Center(
                    child: Text('No businesses have map coordinates yet.'),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: Image.network(
                            _mapUrl.toString(),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Text(
                                'Map could not load. Check the Mapbox token and connection.',
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Text('© Mapbox © OpenStreetMap'),
                          const Spacer(),
                          IconButton(
                            onPressed: _zoom <= 1
                                ? null
                                : () => setState(() => _zoom--),
                            icon: const Icon(Icons.remove),
                            tooltip: 'Zoom out',
                          ),
                          IconButton(
                            onPressed: _zoom >= 18
                                ? null
                                : () => setState(() => _zoom++),
                            icon: const Icon(Icons.add),
                            tooltip: 'Zoom in',
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          Expanded(
            flex: 2,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.studentPrimary,
                    ),
                  )
                : _businesses.isEmpty
                ? const Center(child: Text('No businesses found.'))
                : ListView.builder(
                    itemCount: _businesses.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setState(() => _selectedIndex = i),
                      child: _BusinessPingCard(biz: _businesses[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Portfolio
// ─────────────────────────────────────────────────────────────────────────────
class _PortfolioTab extends StatefulWidget {
  const _PortfolioTab();

  @override
  State<_PortfolioTab> createState() => _PortfolioTabState();
}

class _PortfolioTabState extends State<_PortfolioTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _githubRepos = [];
  Set<String> _importedUrls = {};
  String? _importingUrl;
  String? _error;
  String? _githubError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final dbProjects = await Supabase.instance.client
          .from('portfolio_projects')
          .select('id,title,project_type,repository_url')
          .eq('student_id', userId)
          .order('created_at', ascending: false);

      final studentProfile = await Supabase.instance.client
          .from('student_profiles')
          .select('github_username')
          .eq('user_id', userId)
          .maybeSingle();

      List<Map<String, dynamic>> repos = [];
      if (studentProfile != null && studentProfile['github_username'] != null) {
        final username = studentProfile['github_username'] as String;
        if (username.isNotEmpty) {
          try {
            repos = await GithubApiService().fetchUserRepositories(username);
          } catch (error) {
            _githubError = error.toString();
          }
        }
      }

      if (mounted) {
        setState(() {
          _projects = List<Map<String, dynamic>>.from(dbProjects);
          _importedUrls = dbProjects
              .map((row) => row['repository_url']?.toString() ?? '')
              .where((url) => url.isNotEmpty)
              .toSet();
          _githubRepos = repos;
          if (repos.isNotEmpty) _githubError = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _importRepo(Map<String, dynamic> repo) async {
    final url = repo['html_url']?.toString() ?? '';
    if (url.isEmpty || _importedUrls.contains(url) || _importingUrl != null) {
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _importingUrl = url);
    try {
      final existing = await Supabase.instance.client
          .from('portfolio_projects')
          .select('id')
          .eq('student_id', userId)
          .eq('repository_url', url)
          .maybeSingle();
      if (existing == null) {
        await Supabase.instance.client.from('portfolio_projects').insert({
          'student_id': userId,
          'title': repo['name']?.toString() ?? 'GitHub project',
          'description':
              (repo['description']?.toString().trim().isNotEmpty ?? false)
              ? repo['description'].toString().trim()
              : 'Public GitHub repository imported from $url',
          'repository_url': url,
          'demo_url':
              (repo['homepage']?.toString().startsWith('https://') ?? false)
              ? repo['homepage']
              : null,
          'project_type': 'Other',
        });
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repository added to portfolio.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not import repository: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _importingUrl = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.studentPrimary),
      );
    }
    if (_error != null) {
      return Center(child: Text('Could not load portfolio: $_error'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Portfolio',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/student/portfolio/add'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.studentGradient(),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: AppColors.textPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (_projects.isNotEmpty) ...[
            Text(
              'Manual Projects',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.82,
              ),
              itemCount: _projects.length,
              itemBuilder: (_, i) => _ProjectGridCard(project: _projects[i]),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          if (_githubRepos.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.code_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'GitHub Repositories',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.82,
              ),
              itemCount: _githubRepos.length,
              itemBuilder: (_, i) {
                final repo = _githubRepos[i];
                final url = repo['html_url']?.toString() ?? '';
                return _GithubRepoGridCard(
                  repo: repo,
                  imported: _importedUrls.contains(url),
                  importing: _importingUrl == url,
                  onImport: () => _importRepo(repo),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          if (_githubError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text('GitHub: $_githubError'),
            ),

          if (_projects.isEmpty && _githubRepos.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxl),
              child: Center(
                child: Text(
                  'No projects yet. Add your first project or link your GitHub.',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — Profile
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late final Future<Map<String, dynamic>> _profile = _loadProfile();

  Future<Map<String, dynamic>> _loadProfile() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to view your profile');

    final profile = await client
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .single();
    final student = await client
        .from('student_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    final skillLinks = await client
        .from('student_skills')
        .select('skills(name)')
        .eq('student_id', userId);
    final reviewSummary = await ReviewService().getStudentReviews(userId);

    final skills = (skillLinks as List)
        .map(
          (row) =>
              (row['skills'] as Map<String, dynamic>?)?['name'] as String? ??
              '',
        )
        .where((s) => s.isNotEmpty)
        .toList();

    final isVerified =
        client.auth.currentUser?.emailConfirmedAt != null ||
        (student != null && (student['school'] as String?)?.isNotEmpty == true);

    return {
      'name': profile['full_name'] as String? ?? 'Student',
      'school': student?['school'] as String? ?? '',
      'course': student?['course'] as String? ?? '',
      'year': student?['year_level'] as String? ?? '',
      'bio': student?['bio'] as String? ?? '',
      'github': student?['github_username'] as String? ?? '',
      'linkedin': student?['linkedin_url'] as String? ?? '',
      'status': isVerified ? 'verified' : 'unverified',
      'skills': skills,
      'averageRating': reviewSummary.averageRating,
      'totalReviews': reviewSummary.totalReviews,
      'completedJobsCount': reviewSummary.completedJobsCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profile,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: snapshot.hasError
                ? Text('Could not load profile: ${snapshot.error}')
                : const CircularProgressIndicator(),
          );
        }
        final profile = snapshot.data!;
        final name = profile['name'] as String;
        final initials = name
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0])
            .join()
            .toUpperCase();
        final course = profile['course'] as String;
        final school = profile['school'] as String;
        final year = profile['year'] as String;
        final subtitle = course.isNotEmpty
            ? (school.isNotEmpty ? '$course · $school' : course)
            : (school.isNotEmpty ? school : 'Student developer');
        final github = profile['github'] as String;
        final bio = profile['bio'] as String;
        final skills = profile['skills'] as List<String>;
        final status = profile['status'] as String;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              // Avatar hero
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: AppTheme.studentGradient(),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.studentPrimary.withValues(alpha: 0.4),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials.isNotEmpty ? initials : 'ST',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              ),

              const SizedBox(height: AppSpacing.md),
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              if (year.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  year,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Verification: $status',
                style: GoogleFonts.inter(
                  color: status == 'verified'
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (profile['totalReviews'] as int) > 0
                        ? '★ ${profile['averageRating']} (${profile['totalReviews']} reviews)'
                        : 'No reviews yet',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (profile['totalReviews'] as int) > 0
                          ? AppColors.warning
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('·', style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${profile['completedJobsCount']} jobs completed',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (github.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: () {
                    final cleanUser = github
                        .replaceAll('https://github.com/', '')
                        .replaceAll('/', '')
                        .trim();
                    launchUrl(Uri.https('github.com', '/$cleanUser'));
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        color: AppColors.studentPrimary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'github.com/$github',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: AppColors.studentPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.open_in_new_rounded,
                        color: AppColors.studentPrimary,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Skills
              if (skills.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tech Stack',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: skills
                        .map(
                          (s) => SkillChip(
                            label: s,
                            selected: true,
                            accentColor: AppColors.studentPrimary,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Bio card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      bio.isNotEmpty ? bio : 'No bio added yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Text(
            action,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.studentPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RADAR WIDGET — sonar sweep animation
// ─────────────────────────────────────────────────────────────────────────────
class _RadarWidget extends StatefulWidget {
  final double size;
  const _RadarWidget({required this.size});

  @override
  State<_RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<_RadarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const List<(double, double)> _dots = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => CustomPaint(
        painter: _RadarPainter(angle: _ctrl.value * 2 * math.pi, dots: _dots),
        size: Size(widget.size, widget.size),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double angle;
  final List<(double, double)> dots;

  const _RadarPainter({required this.angle, required this.dots});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // ── Background circle
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = AppColors.surfaceHigh,
    );

    // ── Concentric rings
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(
        Offset(cx, cy),
        r * i / 3,
        Paint()
          ..color = AppColors.studentPrimary.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // ── Cross hairs
    final hairPaint = Paint()
      ..color = AppColors.studentPrimary.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), hairPaint);
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), hairPaint);

    // ── Sweep gradient (arc trailing)
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          AppColors.studentPrimary.withValues(alpha: 0.35),
        ],
        startAngle: angle - 1.4,
        endAngle: angle,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, sweepPaint);

    // ── Sweep line
    final sweepLine = Paint()
      ..color = AppColors.studentPrimary
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
      sweepLine,
    );

    // ── Center dot
    canvas.drawCircle(
      Offset(cx, cy),
      4,
      Paint()
        ..color = AppColors.studentPrimary
        ..style = PaintingStyle.fill,
    );

    // ── Business dots
    for (final (rx, ry) in dots) {
      final dx = cx + (rx - 0.5) * size.width * 1.8;
      final dy = cy + (ry - 0.5) * size.height * 1.8;
      final dotAngle = math.atan2(dy - cy, dx - cx);
      // Normalize both angles to [0, 2π]
      final normDot = dotAngle < 0 ? dotAngle + 2 * math.pi : dotAngle;
      final normSweep = angle % (2 * math.pi);
      final diff = (normSweep - normDot + 2 * math.pi) % (2 * math.pi);
      final opacity = diff < 1.4 ? (1 - diff / 1.4) * 0.9 + 0.1 : 0.12;

      if (dx >= 0 && dx <= size.width && dy >= 0 && dy <= size.height) {
        // Only draw if inside circle
        final dist = math.sqrt((dx - cx) * (dx - cx) + (dy - cy) * (dy - cy));
        if (dist < r) {
          canvas.drawCircle(
            Offset(dx, dy),
            5,
            Paint()
              ..color = AppColors.businessPrimary.withValues(alpha: opacity),
          );
          canvas.drawCircle(
            Offset(dx, dy),
            3,
            Paint()
              ..color = AppColors.businessPrimary.withValues(
                alpha: opacity + 0.2,
              ),
          );
        }
      }
    }

    // ── Outer ring (border)
    canvas.drawCircle(
      Offset(cx, cy),
      r - 0.5,
      Paint()
        ..color = AppColors.studentPrimary.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.angle != angle;
}

class _RadarPreview extends StatelessWidget {
  final VoidCallback onNavigate;
  const _RadarPreview({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onNavigate,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const _RadarWidget(size: 110),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore business map',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'View registered businesses with saved map locations.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.businessPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: AppColors.businessPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Tap to explore →',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: AppColors.businessPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms);
  }
}

class _ProjectGridCard extends StatelessWidget {
  final Map<String, dynamic> project;
  const _ProjectGridCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final title = project['title'] as String? ?? 'Untitled Project';
    final projectType =
        project['project_type'] as String? ?? 'Portfolio project';
    final id = project['id']?.toString() ?? '0';

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/student/portfolio/$id'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.studentPrimary.withValues(alpha: 0.3),
                    AppColors.studentPrimary.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.folder_outlined,
                  color: AppColors.studentPrimary,
                  size: 36,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  projectType,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GithubRepoGridCard extends StatelessWidget {
  final Map<String, dynamic> repo;
  final bool imported;
  final bool importing;
  final VoidCallback onImport;
  const _GithubRepoGridCard({
    required this.repo,
    required this.imported,
    required this.importing,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final title = repo['name'] as String? ?? 'Untitled Repo';
    final language = repo['language'] as String? ?? 'Repository';
    final url = repo['html_url'] as String? ?? '';

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () {
        if (url.isNotEmpty) launchUrl(Uri.parse(url));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.surfaceHigh, AppColors.surface],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.code_rounded,
                  color: AppColors.textPrimary,
                  size: 36,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        language,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (repo['stargazers_count'] != null &&
                        repo['stargazers_count'] > 0)
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 10,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${repo['stargazers_count']}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 28,
                  child: TextButton(
                    onPressed: imported || importing ? null : onImport,
                    child: Text(
                      imported
                          ? 'In portfolio'
                          : importing
                          ? 'Importing…'
                          : 'Import',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final Proposal proposal;
  const _ProposalCard({required this.proposal});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go('/student/proposals'),
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
              Icons.business_outlined,
              color: AppColors.studentPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proposal.businessName ?? proposal.jobTitle ?? 'Job',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '₱${proposal.proposedBudget} · ${proposal.estimatedTimelineWeeks}w',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          StatusBadge.fromApiStatus(proposal.status),
        ],
      ),
    );
  }
}

class _BusinessPingCard extends StatelessWidget {
  final Map<String, dynamic> biz;
  const _BusinessPingCard({required this.biz});

  @override
  Widget build(BuildContext context) {
    final name =
        biz['business_name'] as String? ??
        biz['name'] as String? ??
        'Local Business';
    final address =
        biz['address'] as String? ?? biz['distance'] as String? ?? 'Nearby';
    final category = biz['category'] as String? ?? 'Local Store';
    final isVerified =
        biz['verification_status'] == 'verified' || biz['isVerified'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.businessPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.businessPrimary,
                size: 20,
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
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.studentPrimary,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '$category · $address',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.businessPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                'Listed',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: AppColors.businessPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
