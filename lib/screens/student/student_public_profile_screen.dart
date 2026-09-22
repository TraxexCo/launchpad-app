import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/skill_chip.dart';

import '../../services/github_api_service.dart';
import '../../services/review_service.dart';

class StudentPublicProfileScreen extends StatefulWidget {
  final String studentId;
  const StudentPublicProfileScreen({super.key, required this.studentId});

  @override
  State<StudentPublicProfileScreen> createState() => _StudentPublicProfileScreenState();
}

class _StudentPublicProfileScreenState extends State<StudentPublicProfileScreen> {
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _portfolioItems = [];
  StudentReviewSummary _reviewSummary = const StudentReviewSummary(
    averageRating: 0.0,
    totalReviews: 0,
    completedJobsCount: 0,
    reviews: [],
  );
  bool _profileLoading = true;
  String? _profileError;

  final GithubApiService _githubApiService = GithubApiService();
  List<Map<String, dynamic>> _repos = [];
  bool _isLoading = true;
  String? _error;
  String _selectedLanguage = 'All';
  Set<String> _availableLanguages = {'All'};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final client = Supabase.instance.client;
      final profile = await client.from('profiles').select('full_name')
          .eq('id', widget.studentId).single();
      final student = await client.from('student_profiles').select()
          .eq('user_id', widget.studentId).maybeSingle();
      final skillLinks = await client.from('student_skills')
          .select('skills(name)').eq('student_id', widget.studentId);
      final projects = await client.from('portfolio_projects')
          .select('id,title,description,project_type').eq('student_id', widget.studentId)
          .order('created_at', ascending: false);
      final reviews = await ReviewService().getStudentReviews(widget.studentId);
      if (!mounted) return;
      setState(() {
        _profile = {
          'name': profile['full_name'] as String? ?? 'Student',
          'school': student?['school'] as String? ?? '',
          'course': student?['course'] as String? ?? '',
          'year': student?['year_level'] as String? ?? '',
          'bio': student?['bio'] as String? ?? '',
          'github': student?['github_username'] as String? ?? '',
          'skills': skillLinks.map((row) =>
              (row['skills'] as Map<String, dynamic>?)?['name'] as String? ?? '').where((s) => s.isNotEmpty).toList(),
        };
        _portfolioItems = projects;
        _reviewSummary = reviews;
        _profileLoading = false;
      });
      await _fetchGithubRepos();
    } catch (error) {
      if (mounted) setState(() { _profileError = '$error'; _profileLoading = false; });
    }
  }

  Future<void> _fetchGithubRepos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final username = _profile['github'] as String? ?? '';
      if (username.isEmpty) {
        if (mounted) setState(() { _repos = []; _isLoading = false; });
        return;
      }
      final repos = await _githubApiService.fetchUserRepositories(username);
      
      final languages = {'All'};
      for (var repo in repos) {
        if (repo['language'] != null) {
          languages.add(repo['language'] as String);
        }
      }

      if (!mounted) return;
      setState(() {
        _repos = repos;
        _availableLanguages = languages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _profileLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileError != null
              ? Center(child: Text('Could not load student profile: $_profileError'))
              : AppBackground(
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
                  SliverToBoxAdapter(child: _buildGithubPortfolio(context)),
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
        onTap: () => context.canPop() ? context.pop() : context.go('/business'),
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
                    (_profile['name'] as String).split(' ')
                        .where((part) => part.isNotEmpty)
                        .take(2).map((part) => part[0]).join().toUpperCase(),
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
                    Text(_profile['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text((_profile['course'] as String).isEmpty
                            ? 'Student developer' : _profile['course'] as String,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, color: AppColors.textMuted, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(((_profile['school'] as String).isEmpty &&
                                  (_profile['year'] as String).isEmpty)
                              ? 'School details not added'
                              : '${_profile['year']} · ${_profile['school']}',
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
    final ratingStr = _reviewSummary.totalReviews > 0
        ? '${_reviewSummary.averageRating} ★'
        : '—';
    final completedJobsStr = '${_reviewSummary.completedJobsCount}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _StatTile(value: ratingStr, label: 'Rating', color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          _StatTile(value: completedJobsStr, label: 'Jobs Done', color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          _StatTile(value: '${_portfolioItems.length}', label: 'Projects', color: AppColors.studentPrimary),
          const SizedBox(width: AppSpacing.sm),
          _StatTile(value: '100%', label: 'Response', color: AppColors.studentAccent),
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
          const _SectionLabel(label: 'About'),
          const SizedBox(height: AppSpacing.md),
          Text((_profile['bio'] as String).isEmpty ? 'No bio added yet.' : _profile['bio'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7)),
          const SizedBox(height: AppSpacing.md),
          if ((_profile['github'] as String).isNotEmpty) GestureDetector(
            onTap: () => launchUrl(Uri.https('github.com', '/${_profile['github']}')),
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
          const _SectionLabel(label: 'Skills'),
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

  Widget _buildGithubPortfolio(BuildContext context) {
    List<Map<String, dynamic>> displayedRepos = _repos;
    if (_selectedLanguage != 'All') {
      displayedRepos = _repos.where((r) => r['language'] == _selectedLanguage).toList();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const _SectionLabel(label: 'Live GitHub Portfolio'),
                  const SizedBox(width: AppSpacing.sm),
                  if ((_profile['github'] as String).isNotEmpty) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('LIVE', style: GoogleFonts.jetBrainsMono(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: AppColors.success,
                          letterSpacing: 0.5,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
              if ((_profile['github'] as String).isNotEmpty) IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.studentPrimary),
                onPressed: _isLoading ? null : _fetchGithubRepos,
                tooltip: 'Refresh GitHub Data',
              )
            ],
          ),
          if (!_isLoading && _error == null && _availableLanguages.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableLanguages.map((lang) {
                  final isSelected = _selectedLanguage == lang;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(lang, style: GoogleFonts.inter(fontSize: 11)),
                      selected: isSelected,
                      selectedColor: AppColors.studentPrimary.withValues(alpha: 0.2),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedLanguage = lang);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if ((_profile['github'] as String).isEmpty)
            Text('No GitHub account linked.', style: GoogleFonts.inter(color: AppColors.textMuted))
          else if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(color: AppColors.studentPrimary),
            ))
          else if (_error != null)
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(_error!, style: GoogleFonts.inter(color: AppColors.error, fontSize: 12))),
                ],
              ),
            )
          else if (displayedRepos.isEmpty)
            Text('No repositories found.', style: GoogleFonts.inter(color: AppColors.textMuted))
          else
            ...displayedRepos.take(5).map((repo) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                onTap: () {
                  final url = Uri.tryParse(repo['html_url']?.toString() ?? '');
                  if (url != null && url.scheme == 'https' && url.host == 'github.com') {
                    launchUrl(url);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(repo['name'] ?? 'Unknown',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                            const SizedBox(width: 4),
                            Text('${repo['stargazers_count'] ?? 0}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        )
                      ],
                    ),
                    if (repo['description'] != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(repo['description'],
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.studentPrimary),
                        ),
                        const SizedBox(width: 6),
                        Text(repo['language'] ?? 'Unknown', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.textSecondary)),
                        const Spacer(),
                        Text('Updated: ${(repo['updated_at'] as String).substring(0, 10)}',
                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDisabled)),
                      ],
                    )
                  ],
                ),
              ),
            )),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 280.ms),
    );
  }

  Widget _buildPortfolio(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'Past Projects'),
          const SizedBox(height: AppSpacing.md),
          if (_portfolioItems.isEmpty)
            Text('No portfolio projects yet.', style: GoogleFonts.inter(color: AppColors.textMuted)),
          ..._portfolioItems.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              onTap: () => context.go('/student/portfolio/${e.value['id']}'),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.studentPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.folder_outlined,
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
                        Text(e.value['project_type'] as String? ?? 'Portfolio project',
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
            children: [
              const _SectionLabel(label: 'Client Reviews'),
              const Spacer(),
              if (_reviewSummary.totalReviews > 0)
                Text('${_reviewSummary.totalReviews} review(s)',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_reviewSummary.reviews.isEmpty)
            Text('No reviews yet. Reviews will appear after completed contracts.',
                style: GoogleFonts.inter(color: AppColors.textMuted))
          else
            ..._reviewSummary.reviews.map((rev) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(rev.reviewerName,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            Row(
                              children: [
                                for (int i = 1; i <= 5; i++)
                                  Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: i <= rev.rating
                                        ? AppColors.warning
                                        : AppColors.border,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(rev.jobTitle,
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 10, color: AppColors.studentPrimary)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(rev.body,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                )),
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
      child: Text('Messaging is available after a proposal is accepted. Invitations are coming later.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
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
