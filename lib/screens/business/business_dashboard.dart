import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/status_badge.dart';
import '../../services/job_service.dart';
import '../../services/proposal_service.dart';
import '../../services/auth_service.dart';
import '../../services/contract_service.dart';
import '../../models/job_post.dart';
import '../../models/proposal.dart';

class BusinessDashboard extends StatefulWidget {
  const BusinessDashboard({super.key});

  @override
  State<BusinessDashboard> createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends State<BusinessDashboard> {
  int _navIndex = 0;
  String _businessName = 'Business';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUser();
    if (user != null && mounted) {
      setState(() => _businessName = user.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.businessPrimary.withValues(alpha: 0.04),
        child: SafeArea(
          child: Column(
            children: [
              _BizAppBar(businessName: _businessName, onLogout: () {
                AuthService().logout();
                context.go('/onboarding');
              }),
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
  final String businessName;
  final VoidCallback onLogout;
  const _BizAppBar({required this.businessName, required this.onLogout});

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
              Text(businessName,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5)),
              Text('Business account', style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textMuted)),
            ],
          ),

          const Spacer(),

          _BizIconBtn(icon: Icons.notifications_none_rounded, onTap: () => context.go('/notifications?role=business')),
          const SizedBox(width: AppSpacing.sm),
          _BizIconBtn(icon: Icons.logout_rounded, onTap: onLogout),
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
class _BizHomeTab extends StatefulWidget {
  const _BizHomeTab();

  @override
  State<_BizHomeTab> createState() => _BizHomeTabState();
}

class _BizHomeTabState extends State<_BizHomeTab> {
  List<JobPost> _jobs = [];
  List<Proposal> _proposals = [];
  List<ContractItem> _contracts = [];
  String _businessName = 'Business';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user != null) {
        _businessName = user.name;
        final futures = await Future.wait([
          JobService().getJobsByBusiness(user.id),
          ContractService().getMyContracts(),
        ]);
        final jobs = futures[0] as List<JobPost>;
        final contracts = futures[1] as List<ContractItem>;
        
        // Fetch proposals for all jobs
        final allProposals = <Proposal>[];
        for (var job in jobs) {
          final p = await ProposalService().getProposalsByJob(int.parse(job.id));
          for (var prop in p) {
            prop = prop.copyWith(jobTitle: job.title, jobBudget: job.budget);
            allProposals.add(prop);
          }
        }
        allProposals.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (mounted) {
          setState(() {
            _jobs = jobs;
            _proposals = allProposals;
            _contracts = contracts;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

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
        Text('$_businessName 👋',
            style: Theme.of(context).textTheme.headlineMedium)
            .animate().fadeIn(duration: 500.ms, delay: 80.ms)
            .slideY(begin: 0.15),

        const SizedBox(height: AppSpacing.lg),

        // ── Stats row
        Row(
          children: [
            _BizStatCard(label: 'Active Jobs', value: '${_jobs.length}', color: AppColors.businessPrimary),
            const SizedBox(width: AppSpacing.sm),
            _BizStatCard(label: 'Proposals', value: '${_proposals.length}', color: AppColors.businessAccent),
            const SizedBox(width: AppSpacing.sm),
            _BizStatCard(label: 'Hired', value: '${_contracts.length}', color: AppColors.success),
          ],
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 200.ms)
            .slideY(begin: 0.1, duration: 400.ms, delay: 200.ms),

        // ── Active Contracts Section
        if (_contracts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _BizSectionHeader(
            title: 'Active Contracts',
            action: '${_contracts.length} ongoing',
            onAction: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          ..._contracts.map((c) => Padding(
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
                                  color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: Text('In Progress',
                                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Assigned Student: ${c.studentName} · ₱${c.budget.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.push('/chat/${c.proposalId}?name=${c.studentName}'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                              decoration: BoxDecoration(
                                color: AppColors.businessPrimary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.businessPrimary.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.businessPrimary),
                                  const SizedBox(width: 6),
                                  Text('Open Project Chat',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.businessPrimary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],

        const SizedBox(height: AppSpacing.xl),

        // ── Post a job CTA
        _PostJobCard(onPosted: _loadData)
            .animate()
            .fadeIn(duration: 500.ms, delay: 350.ms)
            .slideY(begin: 0.1, duration: 400.ms, delay: 350.ms),

        const SizedBox(height: AppSpacing.xl),

        // ── Active jobs section
        _BizSectionHeader(
            title: 'Active Jobs', action: 'View all', onAction: () {
               final state = context.findAncestorStateOfType<_BusinessDashboardState>();
               if (state != null) state.setState(() => state._navIndex = 1);
            }),
        const SizedBox(height: AppSpacing.md),
        
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.md), child: CircularProgressIndicator(color: AppColors.businessPrimary))),
        if (!_loading && _jobs.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Text('No active jobs', style: Theme.of(context).textTheme.bodyMedium))),

        ..._jobs.take(3).toList().asMap().entries.map((e) => Padding(
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
            title: 'Recent Proposals', action: 'See all', onAction: () {
               final state = context.findAncestorStateOfType<_BusinessDashboardState>();
               if (state != null) state.setState(() => state._navIndex = 2);
            }),
        const SizedBox(height: AppSpacing.md),
        
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.md), child: CircularProgressIndicator(color: AppColors.businessPrimary))),
        if (!_loading && _proposals.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Text('No recent proposals', style: Theme.of(context).textTheme.bodyMedium))),

        ..._proposals.take(3).toList().asMap().entries.map((e) => Padding(
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
class _BizJobsTab extends StatefulWidget {
  const _BizJobsTab();
  @override
  State<_BizJobsTab> createState() => _BizJobsTabState();
}

class _BizJobsTabState extends State<_BizJobsTab> {
  List<JobPost> _jobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);
    final user = await AuthService().getCurrentUser();
    if (user != null) {
      final jobs = await JobService().getJobsByBusiness(user.id);
      if (mounted) setState(() { _jobs = jobs; _loading = false; });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteJob(JobPost job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Job', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Delete "${job.title}"? This cannot be undone.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await JobService().deleteJob(int.parse(job.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Job deleted.'), backgroundColor: AppColors.error),
        );
        _loadJobs();
      }
    }
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Job Posts', style: Theme.of(context).textTheme.headlineMedium),
                    Text('${_jobs.length} job(s) posted', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              AppButton.business(
                label: '+ Post Job',
                isExpanded: false,
                onPressed: () async {
                  await context.push('/business/post-job');
                  _loadJobs(); // refresh after returning
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.businessPrimary)))
          else if (_jobs.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.work_off_outlined, size: 56, color: AppColors.textDisabled),
                    const SizedBox(height: AppSpacing.md),
                    Text('No jobs posted yet', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Tap "+ Post Job" to create your first listing.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDisabled)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _jobs.length,
                itemBuilder: (_, i) {
                  final job = _jobs[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(job.title,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.businessPrimary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(AppRadius.full),
                                          ),
                                          child: Text(job.category, style: GoogleFonts.inter(fontSize: 10, color: AppColors.businessPrimary, fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 6),
                                        if (job.urgency == 'Urgent')
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(AppRadius.full),
                                            ),
                                            child: Text('Urgent', style: GoogleFonts.inter(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text('₱${job.budget}',
                                  style: GoogleFonts.jetBrainsMono(
                                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.businessPrimary)),
                            ],
                          ),
                          if (job.description.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(job.description,
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textDisabled),
                              const SizedBox(width: 4),
                              Text(job.timeline, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textDisabled)),
                              const Spacer(),
                              // UPDATE button
                              GestureDetector(
                                onTap: () async {
                                  await context.push('/business/jobs/${job.id}/edit', extra: job);
                                  _loadJobs();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.businessPrimary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(color: AppColors.businessPrimary.withValues(alpha: 0.25)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.edit_rounded, size: 11, color: AppColors.businessPrimary),
                                      const SizedBox(width: 4),
                                      Text('Edit', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.businessPrimary)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              // DELETE button
                              GestureDetector(
                                onTap: () => _deleteJob(job),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.delete_rounded, size: 11, color: AppColors.error),
                                      const SizedBox(width: 4),
                                      Text('Delete', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: i * 80)),
                  );
                },
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
class _BizProposalsTab extends StatefulWidget {
  const _BizProposalsTab();
  @override
  State<_BizProposalsTab> createState() => _BizProposalsTabState();
}

class _BizProposalsTabState extends State<_BizProposalsTab> {
  List<Proposal> _proposals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProposals();
  }

  Future<void> _loadProposals() async {
    setState(() => _loading = true);
    try {
      final user = await AuthService().getCurrentUser();
      if (user == null) throw Exception('Not logged in');
      
      final jobs = await JobService().getJobsByBusiness(user.id);
      
      List<Proposal> allProposals = [];
      for (final job in jobs) {
        final jobProposals = await ProposalService().getProposalsByJob(int.parse(job.id));
        for (var p in jobProposals) {
          p = p.copyWith(jobTitle: job.title, jobBudget: job.budget);
          allProposals.add(p);
        }
      }
      allProposals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) setState(() { _proposals = allProposals; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

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
          Text('${_proposals.length} proposals received',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.businessPrimary)))
          else if (_proposals.isEmpty)
            Expanded(child: Center(child: Text('No proposals yet', style: Theme.of(context).textTheme.bodyMedium)))
          else
            Expanded(
              child: ListView.separated(
                itemCount: _proposals.length,
                separatorBuilder: (context, idx) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) =>
                    _IncomingProposalCard(proposal: _proposals[i]),
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
class _BizProfileTab extends StatefulWidget {
  const _BizProfileTab();

  @override
  State<_BizProfileTab> createState() => _BizProfileTabState();
}

class _BizProfileTabState extends State<_BizProfileTab> {
  late final Future<Map<String, dynamic>> _profile = _loadProfile();

  Future<Map<String, dynamic>> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to view your profile');
    return Supabase.instance.client.from('business_profiles').select()
        .eq('user_id', userId).single();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profile,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: snapshot.hasError
              ? Text('Could not load profile: ${snapshot.error}')
              : const CircularProgressIndicator());
        }
        final profile = snapshot.data!;
        final status = profile['verification_status'] as String? ?? 'unverified';
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                gradient: AppTheme.businessGradient(),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: AppColors.textPrimary, size: 40),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(profile['business_name'] as String,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text((profile['address'] as String?)?.isNotEmpty == true
                ? profile['address'] as String : 'No address added',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text('Verification: $status', style: GoogleFonts.inter(
                color: status == 'verified' ? AppColors.success : AppColors.warning)),
            const SizedBox(height: AppSpacing.xl),
            _BizInfoRow(icon: Icons.category_outlined, label: 'Category',
                value: profile['category'] as String? ?? 'Not added'),
            const SizedBox(height: AppSpacing.sm),
            _BizInfoRow(icon: Icons.phone_outlined, label: 'Contact',
                value: profile['phone'] as String? ?? 'Not added'),
            const SizedBox(height: AppSpacing.xl),
          ]),
        );
      },
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
  final VoidCallback onPosted;

  const _PostJobCard({required this.onPosted});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await context.push('/business/post-job');
        if (result == true) {
          onPosted();
        }
      },
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
  final JobPost job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go('/business/jobs/${job.id}/proposals'),
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
                child: const Icon(Icons.work_outline_rounded,
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
                    Text('Tap to view proposals',
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
  final Proposal proposal;
  const _IncomingProposalCard({required this.proposal});

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
      onTap: () => context.go('/business/proposals/${proposal.id}', extra: proposal),
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
              child: Text(proposal.studentName != null && proposal.studentName!.isNotEmpty ? proposal.studentName![0] : 'S',
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
                      child: Text(proposal.studentName ?? 'Student',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                Text('${proposal.jobTitle ?? 'Job'} • ₱${proposal.proposedBudget}',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge.fromApiStatus(proposal.status),
              const SizedBox(height: 4),
              Text(_timeAgo(proposal.createdAt),
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





