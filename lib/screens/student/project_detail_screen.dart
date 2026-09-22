import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/skill_chip.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late final Future<(Map<String, dynamic>, List<String>)> _details = _load();

  Future<(Map<String, dynamic>, List<String>)> _load() async {
    final id = int.parse(widget.projectId);
    final client = Supabase.instance.client;
    final project = await client.from('portfolio_projects').select().eq('id', id).single();
    final links = await client.from('portfolio_project_skills')
        .select('skills(name)').eq('project_id', id);
    final names = links.map((row) =>
        (row['skills'] as Map<String, dynamic>)['name'] as String).toList();
    return (project, names);
  }

  Future<void> _open(String? value) async {
    final uri = Uri.tryParse(value ?? '');
    if (uri == null || uri.scheme != 'https') return;
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.studentPrimary.withValues(alpha: 0.04),
        child: SafeArea(
          child: FutureBuilder<(Map<String, dynamic>, List<String>)>(
            future: _details,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: snapshot.hasError
                    ? Text('Could not load project: ${snapshot.error}')
                    : const CircularProgressIndicator());
              }
              final (project, skills) = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => context.canPop() ? context.pop() : context.go('/student'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.folder_outlined,
                            size: 44, color: AppColors.studentPrimary),
                        const SizedBox(height: AppSpacing.md),
                        Text(project['title'] as String,
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text(project['project_type'] as String? ?? 'Project',
                            style: GoogleFonts.inter(color: AppColors.studentPrimary)),
                      ],
                    )),
                    const SizedBox(height: AppSpacing.xl),
                    Text('About this project', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(project['description'] as String,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Skills', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
                      children: skills.map((name) => SkillChip(label: name,
                          selected: true, accentColor: AppColors.studentPrimary)).toList()),
                    const SizedBox(height: AppSpacing.xl),
                    if (project['repository_url'] != null)
                      TextButton.icon(
                        onPressed: () => _open(project['repository_url'] as String?),
                        icon: const Icon(Icons.code_rounded),
                        label: const Text('Open repository'),
                      ),
                    if (project['demo_url'] != null)
                      TextButton.icon(
                        onPressed: () => _open(project['demo_url'] as String?),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Open live demo'),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
