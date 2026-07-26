import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/skill_chip.dart';
import '../../widgets/report_modal.dart';
import '../../data/mock_data.dart';

class StudentPublicProfileScreen extends StatelessWidget {
  final String studentId;
  const StudentPublicProfileScreen({super.key, required this.studentId});

  static const _profile = {
    'name': 'Juan dela Cruz',
    'title': 'Flutter & Full-Stack Developer',
    'school': 'Polytechnic University of the Philippines',
    'year': '3rd Year · BSIT',
    'bio':
        'Mobile-first developer passionate about building real products. I specialize in Flutter and Laravel, and I love helping local businesses get their first app. 5 projects completed, 3 with local clients.',
    'github': 'github.com/juandc',
    'rating': '4.9',
    'projects': 5,
    'proposals': 12,
    'completedJobs': 3,
    'responseTime': '< 4h',
    'skills': ['Flutter', 'Dart', 'Laravel', 'PHP', 'MySQL', 'Firebase', 'Figma'],
  };

  static const _portfolioItems = [
    {'title': 'Café POS System', 'type': 'Mobile App', 'icon': Icons.point_of_sale_rounded},
    {'title': 'QuizBee App', 'type': 'Mobile App', 'icon': Icons.quiz_rounded},
    {'title': 'Grade Tracker', 'type': 'Web App', 'icon': Icons.grade_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.studentPrimary.withValues(alpha: 0.04),
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(context),
                  SliverToBoxAdapter(child: _buildProfileHeader(context)),
                  SliverToBoxAdapter(child: _buildStats(context)),
                  SliverToBoxAdapter(child: _buildBio(context)),
                  SliverToBoxAdapter(child: _buildSkills(context)),
                  SliverToBoxAdapter(child: _buildPortfolio(context)),
                  SliverToBoxAdapter(child: _buildReviews(context)),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
            _buildBottom(context),
          ],
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
        onTap: () => context.go('/business'),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary, size: 14),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.outlined_flag_rounded, color: AppColors.textSecondary),
          tooltip: 'Report Student',
          onPressed: () => ReportModal.show(context, targetName: mockStudentProfile.name, targetType: 'student'),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.share_outlined, color: AppColors.textSecondary, size: 16),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.studentPrimary, AppColors.studentAccent],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.studentPrimary.withValues(alpha: 0.4), blurRadius: 20)],
                ),
                child: Center(
                  child: Text(
                    mockStudentProfile.initials,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
                        Expanded(
                          child: Text(mockStudentProfile.name,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20, fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                        ),
                        if (mockStudentProfile.isVerified) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.verified_rounded, color: AppColors.studentPrimary, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(_profile['title'] as String,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, color: AppColors.textMuted, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text('${_profile['year']} · PUP',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _StatTile(value: '${_profile['rating']}★', label: 'Rating', color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          _StatTile(value: '${_profile['completedJobs']}', label: 'Jobs Done', color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          _StatTile(value: '${_profile['projects']}', label: 'Projects', color: AppColors.studentPrimary),
          const SizedBox(width: AppSpacing.sm),
          _StatTile(value: _profile['responseTime'] as String, label: 'Response', color: AppColors.studentAccent),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
    );
  }

  Widget _buildBio(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'About'),
          const SizedBox(height: AppSpacing.md),
          Text(_profile['bio'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7)),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.code_rounded, color: AppColors.studentPrimary, size: 14),
                const SizedBox(width: 4),
                Text(_profile['github'] as String,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 12, color: AppColors.studentPrimary, fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                const Icon(Icons.open_in_new_rounded, color: AppColors.studentPrimary, size: 12),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 180.ms),
    );
  }

  Widget _buildSkills(BuildContext context) {
    final skills = _profile['skills'] as List<String>;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Skills'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: skills
                .map((s) => SkillChip(label: s, selected: true, accentColor: AppColors.studentPrimary))
                .toList(),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 260.ms),
    );
  }

  Widget _buildPortfolio(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Portfolio'),
          const SizedBox(height: AppSpacing.md),
          ..._portfolioItems.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              onTap: () => context.go('/student/portfolio/${e.key}'),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.studentPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(e.value['icon'] as IconData,
                        color: AppColors.studentPrimary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value['title'] as String,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text(e.value['type'] as String,
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 10, color: AppColors.studentPrimary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.textMuted, size: 12),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms,
                delay: Duration(milliseconds: 320 + e.key * 80)),
          )),
        ],
      ),
    );
  }

  Widget _buildReviews(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionLabel(label: 'Client Reviews (${mockStudentProfile.reviewCount})'),
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const _LeaveReviewModal(),
                  );
                },
                child: Text('Write a Review', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.studentPrimary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (mockStudentProfile.reviews.isEmpty)
            Text('No reviews yet.', style: GoogleFonts.inter(color: AppColors.textMuted))
          else
            ...mockStudentProfile.reviews.map((review) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < review.rating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                                color: AppColors.warning,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(review.rating.toStringAsFixed(1),
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.warning)),
                          const Spacer(),
                          Text(review.authorName,
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '"${review.text}"',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(review.timeAgo, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDisabled)),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBottom(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Message',
              outlined: true,
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () => context.go('/chat/s1?name=Juan dela Cruz'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Invite to Job',
              icon: Icons.send_rounded,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatTile({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted)),
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
        Container(width: 3, height: 16,
            decoration: BoxDecoration(
              color: AppColors.studentPrimary,
              borderRadius: BorderRadius.circular(AppRadius.full),
            )),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _LeaveReviewModal extends StatefulWidget {
  const _LeaveReviewModal();
  @override
  State<_LeaveReviewModal> createState() => _LeaveReviewModalState();
}

class _LeaveReviewModalState extends State<_LeaveReviewModal> {
  int _rating = 0;
  bool _submitting = false;

  void _submit() async {
    if (_rating == 0) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted successfully!'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl + keyboard),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Write a Review', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                icon: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.warning,
                  size: 40,
                ),
                onPressed: () => setState(() => _rating = i + 1),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your experience working with this student...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _submitting ? 'Submitting...' : 'Submit Review',
            onPressed: _rating > 0 ? _submit : null,
          ),
        ],
      ),
    );
  }
}



