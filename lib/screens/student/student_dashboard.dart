import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/skill_chip.dart';
import '../../widgets/status_badge.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.studentPrimary.withValues(alpha: 0.04),
        child: SafeArea(
          child: Column(
            children: [
              _AppBar(onLogout: () => context.go('/onboarding')),
              Expanded(
                child: IndexedStack(
                  index: _navIndex,
                  children: const [
                    _HomeTab(),
                    _RadarTab(),
                    _PortfolioTab(),
                    _ProfileTab(),
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
  final VoidCallback onLogout;
  const _AppBar({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
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
              child: Text('JD',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ),
          ),

          const SizedBox(width: AppSpacing.sm + 2),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LaunchPad',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5)),
              Text('Juan dela Cruz',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ),

          const Spacer(),

          // Notification bell
          _IconBtn(icon: Icons.notifications_none_rounded, onTap: () => context.go('/notifications?role=student')),
          const SizedBox(width: AppSpacing.sm),
          _IconBtn(icon: Icons.settings_outlined, onTap: () => context.go('/settings?role=student')),
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
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
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
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
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
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.sm),

        // ── Welcome
        Text('Hey, Juan 👋',
            style: Theme.of(context).textTheme.headlineMedium)
            .animate().fadeIn(duration: 500.ms).slideY(begin: 0.15),
        const SizedBox(height: AppSpacing.xs),
        Text('Ready to hustle today?',
            style: Theme.of(context).textTheme.bodyLarge)
            .animate().fadeIn(duration: 400.ms, delay: 100.ms),

        const SizedBox(height: AppSpacing.lg),

        // ── Stats row
        Row(
          children: [
            _StatCard(label: 'Projects', value: '7', color: AppColors.studentPrimary),
            const SizedBox(width: AppSpacing.sm),
            _StatCard(label: 'Pitches', value: '12', color: AppColors.studentAccent),
            const SizedBox(width: AppSpacing.sm),
            _StatCard(label: 'Accepted', value: '3', color: AppColors.success),
          ],
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 200.ms)
            .slideY(begin: 0.1, duration: 400.ms, delay: 200.ms),

        const SizedBox(height: AppSpacing.xl),

        // ── Radar teaser
        _SectionHeader(title: 'Local Radar', action: 'View all', onAction: () {}),
        const SizedBox(height: AppSpacing.md),
        const _RadarPreview(),

        const SizedBox(height: AppSpacing.xl),

        // ── Browse Jobs CTA
        _SectionHeader(title: 'Open Jobs Near You', action: 'Browse all', onAction: () => context.go('/student/jobs')),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: mockProjects.length,
            separatorBuilder: (context, idx) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => _ProjectCard(project: mockProjects[i]),
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 600.ms),

        const SizedBox(height: AppSpacing.xl),

        // ── Portfolio preview
        _SectionHeader(title: 'My Portfolio', action: 'Add project', onAction: () => context.go('/student/portfolio/add')),
        const SizedBox(height: AppSpacing.md),

        const SizedBox(height: AppSpacing.xl),

        // ── Active proposals
        _SectionHeader(title: 'Active Proposals', action: 'See all', onAction: () => context.go('/student/proposals')),

        ...mockStudentProposals.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ProposalCard(proposal: e.value)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: Duration(milliseconds: 700 + e.key * 80))
                  .slideY(begin: 0.1, duration: 300.ms, delay: Duration(milliseconds: 700 + e.key * 80)),
            )),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Radar (full view)
// ─────────────────────────────────────────────────────────────────────────────
class _RadarTab extends StatelessWidget {
  const _RadarTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text('Local Radar', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Undigitized businesses near you.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),

          // Full radar
          Expanded(
            flex: 3,
            child: Center(child: _RadarWidget(size: 280)),
          ),

          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: mockNearbyBusinesses.length,
              itemBuilder: (_, i) => _BusinessPingCard(biz: mockNearbyBusinesses[i]),
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
class _PortfolioTab extends StatelessWidget {
  const _PortfolioTab();

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
                child: Text('Portfolio',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              GestureDetector(
                onTap: () => context.go('/student/portfolio/add'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: AppTheme.studentGradient(),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, color: AppColors.textPrimary, size: 16),
                      const SizedBox(width: 4),
                      Text('Add',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.82,
              ),
              itemCount: mockProjects.length,
              itemBuilder: (_, i) => _ProjectGridCard(project: mockProjects[i]),
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
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
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
                child: Text('JD',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          ),

          const SizedBox(height: AppSpacing.md),
          Text('Juan dela Cruz',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text('Flutter Developer · PUP Manila',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.link_rounded, color: AppColors.studentPrimary, size: 14),
              const SizedBox(width: 4),
              Text('github.com/juandc',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 12, color: AppColors.studentPrimary)),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Skills
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Tech Stack', style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: ['Flutter', 'Dart', 'PHP', 'MySQL', 'React', 'Figma']
                  .map((s) => SkillChip(
                        label: s,
                        selected: true,
                        accentColor: AppColors.studentPrimary,
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Bio card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Flutter dev at PUP, passionate about crafting beautiful and performant mobile apps. Open for freelance project collaborations.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
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
  const _SectionHeader({required this.title, required this.action, required this.onAction});

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
                  color: AppColors.studentPrimary,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

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
                    fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
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

  static const _dots = [
    (0.35, 0.25), (0.72, 0.40), (0.20, 0.60),
    (0.60, 0.70), (0.45, 0.80), (0.80, 0.20),
  ];

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
              ..color =
                  AppColors.businessPrimary.withValues(alpha: opacity + 0.2),
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
  const _RadarPreview();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const _RadarWidget(size: 110),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('6 businesses found',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.xs),
                Text('No websites detected. Potential clients nearby.',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4)),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.businessPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                        color: AppColors.businessPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Text('Tap to explore →',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, color: AppColors.businessPrimary)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms);
  }
}

class _ProjectCard extends StatelessWidget {
  final MockProject project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      width: 180,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  project.color.withValues(alpha: 0.3),
                  project.color.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg)),
            ),
            child: Center(
              child: Icon(project.icon, color: project.color, size: 40),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(project.tech,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectGridCard extends StatelessWidget {
  final MockProject project;
  const _ProjectGridCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    project.color.withValues(alpha: 0.3),
                    project.color.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg)),
              ),
              child: Center(
                child: Icon(project.icon, color: project.color, size: 36),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(project.tech,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 9, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final MockStudentProposal proposal;
  const _ProposalCard({required this.proposal});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.studentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.business_outlined,
                color: AppColors.studentPrimary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(proposal.bizName,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(proposal.projectType,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          StatusBadge.fromProposal(proposal.status),
        ],
      ),
    );
  }
}

class _BusinessPingCard extends StatelessWidget {
  final MockBusiness biz;
  const _BusinessPingCard({required this.biz});

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.storefront_rounded,
                  color: AppColors.businessPrimary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(biz.name,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (biz.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: AppColors.studentPrimary, size: 14),
                      ],
                    ],
                  ),
                  Text(biz.distance,
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.businessPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text('No website',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, color: AppColors.businessPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA



