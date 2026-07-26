import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class JobProposalsScreen extends StatefulWidget {
  final String jobId;
  const JobProposalsScreen({super.key, required this.jobId});

  @override
  State<JobProposalsScreen> createState() => _JobProposalsScreenState();
}

class _JobProposalsScreenState extends State<JobProposalsScreen> {
  String _sort = 'Newest';

  static const _job = {
    'title': 'Online Ordering App',
    'proposals': 4,
    'budget': '₱12,000',
    'status': 'Open',
  };

  static const _proposals = [
    {
      'id': 'p1', 'name': 'Juan dela Cruz', 'school': 'PUP Manila',
      'rate': '₱11,500', 'timeline': '3 weeks',
      'cover': 'Hi! I am a 3rd year BSIT student specializing in Flutter development. I have built 3 complete mobile apps and one of them is a POS system for a local restaurant. I can start immediately.',
      'skills': ['Flutter', 'Firebase', 'Dart'],
      'rating': 4.9, 'jobs': 3, 'status': 'pending',
    },
    {
      'id': 'p2', 'name': 'Maria Santos', 'school': 'TUP Cavite',
      'rate': '₱12,000', 'timeline': '4 weeks',
      'cover': 'Experienced Flutter developer with Firebase expertise. I recently built a food delivery app prototype for my capstone project and can replicate and extend it for your cafe.',
      'skills': ['Flutter', 'Dart', 'PHP'],
      'rating': 4.7, 'jobs': 1, 'status': 'pending',
    },
    {
      'id': 'p3', 'name': 'Carlo Reyes', 'school': 'DLSU Manila',
      'rate': '₱15,000', 'timeline': '3 weeks',
      'cover': 'Full-stack developer with experience in both mobile and backend. I can build the Flutter app and set up the PHP API for GCash integration.',
      'skills': ['Flutter', 'Laravel', 'PHP', 'MySQL'],
      'rating': 5.0, 'jobs': 5, 'status': 'pending',
    },
    {
      'id': 'p4', 'name': 'Ana Lim', 'school': 'UST Manila',
      'rate': '₱9,500', 'timeline': '5 weeks',
      'cover': 'I am a UI/UX-focused developer. My apps are not just functional but look professional. I can show you my Figma prototypes before we even start coding.',
      'skills': ['Flutter', 'Figma', 'Firebase'],
      'rating': 4.5, 'jobs': 2, 'status': 'pending',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.businessPrimary.withValues(alpha: 0.04),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildJobSummary(context),
              _buildSortRow(context),
              Expanded(child: _buildList()),
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
            onTap: () => context.go('/business'),
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
              Text('// ${_job['proposals']} pitches received',
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
                  Text(_job['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(_job['budget'] as String,
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 12, color: AppColors.businessPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            StatusBadge(label: _job['status'] as String, color: AppColors.success),
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
            items: ['Newest', 'Lowest Rate', 'Highest Rating']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _sort = v!),
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
        return _ProposalCard(proposal: p)
            .animate()
            .fadeIn(duration: 350.ms, delay: Duration(milliseconds: i * 70))
            .slideY(begin: 0.08, duration: 300.ms, delay: Duration(milliseconds: i * 70));
      },
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final Map<String, dynamic> proposal;
  const _ProposalCard({required this.proposal});

  @override
  Widget build(BuildContext context) {
    final skills = proposal['skills'] as List;
    return AppCard(
      onTap: () => context.go('/business/proposals/${proposal['id']}'),
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
                    (proposal['name'] as String).split(' ').map((w) => w[0]).take(2).join(),
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
                    Text(proposal['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text(proposal['school'] as String,
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.warning, size: 12),
                      const SizedBox(width: 3),
                      Text('${proposal['rating']}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning)),
                    ],
                  ),
                  Text('${proposal['jobs']} jobs done',
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(proposal['cover'] as String,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Pill(label: proposal['rate'] as String, color: AppColors.businessPrimary, icon: Icons.payments_outlined),
              const SizedBox(width: AppSpacing.sm),
              _Pill(label: proposal['timeline'] as String, color: AppColors.businessAccent, icon: Icons.timer_outlined),
              const Spacer(),
              ...skills.take(2).map((s) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.studentPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(s as String,
                      style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.studentPrimary)),
                ),
              )),
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



