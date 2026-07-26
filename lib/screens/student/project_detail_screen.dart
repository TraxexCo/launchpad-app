import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/skill_chip.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  static final _project = {
    'title': 'Café POS System',
    'type': 'Mobile App',
    'description':
        'A full-featured point-of-sale system built with Flutter and Firebase, designed for small cafés and restaurants. The app features touchscreen item buttons, a real-time running total, split-payment support, and end-of-day sales report generation as a PDF.',
    'tech': ['Flutter', 'Dart', 'Firebase', 'Cloud Firestore'],
    'github': 'github.com/juandc/cafe-pos',
    'demo': 'cafe-pos-demo.web.app',
    'date': 'March 2025',
    'duration': '6 weeks',
    'status': 'Completed',
    'highlights': [
      'Real-time order sync across devices via Firestore',
      'Offline mode with local SQLite fallback',
      'PDF receipt generation using pdf package',
      'Role-based access (cashier vs. admin)',
    ],
  };

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
                  _buildSliverBar(context),
                  SliverToBoxAdapter(child: _buildHero(context)),
                  SliverToBoxAdapter(child: _buildMetaRow(context)),
                  SliverToBoxAdapter(child: _buildDescription(context)),
                  SliverToBoxAdapter(child: _buildHighlights(context)),
                  SliverToBoxAdapter(child: _buildTech(context)),
                  SliverToBoxAdapter(child: _buildLinks(context)),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
            _buildBottom(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: GestureDetector(
        onTap: () => context.go('/student'),
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
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 16),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.studentPrimary.withValues(alpha: 0.3),
              AppColors.studentAccent.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.studentPrimary.withValues(alpha: 0.25)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.studentPrimary, AppColors.studentAccent],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [BoxShadow(color: AppColors.studentPrimary.withValues(alpha: 0.4), blurRadius: 20)],
                ),
                child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(_project['title'] as String,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text(_project['type'] as String,
                  style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.studentPrimary)),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
    );
  }

  Widget _buildMetaRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _MetaTile(label: 'Duration', value: _project['duration'] as String, icon: Icons.timer_outlined, color: AppColors.studentAccent),
          const SizedBox(width: AppSpacing.sm),
          _MetaTile(label: 'Completed', value: _project['date'] as String, icon: Icons.calendar_month_outlined, color: AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          _MetaTile(label: 'Status', value: _project['status'] as String, icon: Icons.check_circle_outline, color: AppColors.success),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'About this Project'),
          const SizedBox(height: AppSpacing.md),
          Text(_project['description'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7)),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 180.ms),
    );
  }

  Widget _buildHighlights(BuildContext context) {
    final highlights = _project['highlights'] as List<String>;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Key Features'),
          const SizedBox(height: AppSpacing.md),
          ...highlights.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.studentPrimary, shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(e.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5))),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: 250 + e.key * 60))),
        ],
      ),
    );
  }

  Widget _buildTech(BuildContext context) {
    final tech = _project['tech'] as List<String>;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Tech Stack'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: tech
                .map((t) => SkillChip(label: t, selected: true, accentColor: AppColors.studentPrimary))
                .toList(),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
    );
  }

  Widget _buildLinks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Links'),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: [
                _LinkTile(
                  icon: Icons.code_rounded,
                  label: 'GitHub Repository',
                  url: _project['github'] as String,
                  color: AppColors.studentPrimary,
                ),
                const Divider(color: AppColors.border, height: AppSpacing.xl),
                _LinkTile(
                  icon: Icons.open_in_new_rounded,
                  label: 'Live Demo',
                  url: _project['demo'] as String,
                  color: AppColors.studentAccent,
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 420.ms),
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
              label: 'Delete',
              outlined: true,
              icon: Icons.delete_outline_rounded,
              onPressed: () => context.go('/student'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Edit Project',
              icon: Icons.edit_rounded,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetaTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label,
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
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

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label, url;
  final Color color;
  const _LinkTile({required this.icon, required this.label, required this.url, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              Text(url,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 12, color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Icon(Icons.open_in_new_rounded, color: AppColors.textMuted, size: 14),
      ],
    );
  }
}


