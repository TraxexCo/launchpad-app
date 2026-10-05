import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/skill_chip.dart';
import '../../widgets/app_state_view.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Future<(Map<String, dynamic>, List<String>)> _details;

  @override
  void initState() {
    super.initState();
    _details = _load();
  }

  void _refresh() => setState(() => _details = _load());

  Future<(Map<String, dynamic>, List<String>)> _load() async {
    final id = int.parse(widget.projectId);
    final client = Supabase.instance.client;
    final project = await client
        .from('portfolio_projects')
        .select()
        .eq('id', id)
        .single();
    final links = await client
        .from('portfolio_project_skills')
        .select('skills(name)')
        .eq('project_id', id);
    final names = links
        .map((row) => (row['skills'] as Map<String, dynamic>)['name'] as String)
        .toList();
    return (project, names);
  }

  Future<void> _open(String? value) async {
    final uri = Uri.tryParse(value ?? '');
    if (uri == null || uri.scheme != 'https') return;
    await launchUrl(uri);
  }

  Future<void> _editProject(
    Map<String, dynamic> project,
    List<String> currentSkills,
  ) async {
    final title = TextEditingController(
      text: project['title']?.toString() ?? '',
    );
    final description = TextEditingController(
      text: project['description']?.toString() ?? '',
    );
    final repository = TextEditingController(
      text: project['repository_url']?.toString() ?? '',
    );
    final demo = TextEditingController(
      text: project['demo_url']?.toString() ?? '',
    );
    var type = project['project_type']?.toString() ?? 'Other';
    final selectedSkills = currentSkills.toSet();
    const types = [
      'Mobile App',
      'Web App',
      'Desktop App',
      'API / Backend',
      'UI/UX Design',
      'Other',
    ];
    if (!types.contains(type)) type = 'Other';
    try {
      final skillRows = await Supabase.instance.client
          .from('skills')
          .select('id, name')
          .order('name');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Edit project'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: description,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Project type',
                    ),
                    items: types
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => type = value ?? type),
                  ),
                  TextField(
                    controller: repository,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Repository URL',
                    ),
                  ),
                  TextField(
                    controller: demo,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Live demo URL',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Skills',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: skillRows.map((skill) {
                      final name = skill['name'] as String;
                      return FilterChip(
                        label: Text(name),
                        selected: selectedSkills.contains(name),
                        onSelected: (selected) => setDialogState(() {
                          selected
                              ? selectedSkills.add(name)
                              : selectedSkills.remove(name);
                        }),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final cleanTitle = title.text.trim();
                  final cleanDescription = description.text.trim();
                  final urls = [repository.text.trim(), demo.text.trim()];
                  if (cleanTitle.isEmpty || cleanDescription.length < 30) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter a title and a description of at least 30 characters.',
                        ),
                      ),
                    );
                    return;
                  }
                  if (urls.any(
                    (value) =>
                        value.isNotEmpty &&
                        (Uri.tryParse(value)?.scheme != 'https'),
                  )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Project links must use https://.'),
                      ),
                    );
                    return;
                  }
                  try {
                    await Supabase.instance.client
                        .from('portfolio_projects')
                        .update({
                          'title': cleanTitle,
                          'description': cleanDescription,
                          'project_type': type,
                          'repository_url': urls[0].isEmpty ? null : urls[0],
                          'demo_url': urls[1].isEmpty ? null : urls[1],
                        })
                        .eq('id', int.parse(widget.projectId));
                    final projectId = int.parse(widget.projectId);
                    await Supabase.instance.client.rpc(
                      'replace_portfolio_project_skills',
                      params: {
                        'project_key': projectId,
                        'selected_skill_names': selectedSkills.toList(),
                      },
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    _refresh();
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Project updated.')),
                      );
                    }
                  } catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Could not update project: $error'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
    } finally {
      title.dispose();
      description.dispose();
      repository.dispose();
      demo.dispose();
    }
  }

  Future<void> _deleteProject() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete project?'),
            content: const Text(
              'This removes the project from your portfolio. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await Supabase.instance.client
          .from('portfolio_projects')
          .delete()
          .eq('id', int.parse(widget.projectId));
      if (mounted) context.go('/student');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete project: $error')),
        );
      }
    }
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
                return snapshot.hasError
                    ? AppStateView(
                        icon: Icons.folder_off_outlined,
                        title: 'Project could not load',
                        message:
                            'The project may be unavailable or your connection may have changed.',
                        accentColor: AppColors.error,
                        actionLabel: 'Try again',
                        actionIcon: Icons.refresh_rounded,
                        onAction: _refresh,
                      )
                    : const AppLoadingView(
                        label: 'Opening project showcase…',
                        color: AppColors.studentPrimary,
                      );
              }
              final (project, skills) = snapshot.data!;
              final isOwner =
                  project['student_id'] ==
                  Supabase.instance.client.auth.currentUser?.id;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Back',
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/student'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Case File',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                'BUILD RECORD • VERIFIED EVIDENCE',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9,
                                  letterSpacing: 1.1,
                                  color: AppColors.studentAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.data_object_rounded,
                                size: 42,
                                color: AppColors.studentAccent,
                              ),
                              const Spacer(),
                              Text(
                                'CASE ${widget.projectId.padLeft(4, '0')}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            project['title'] as String,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            project['project_type'] as String? ?? 'Project',
                            style: GoogleFonts.inter(
                              color: AppColors.studentPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _editProject(project, skills),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _deleteProject,
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'About this project',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      project['description'] as String,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Skills',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: skills
                          .map(
                            (name) => SkillChip(
                              label: name,
                              selected: true,
                              accentColor: AppColors.studentPrimary,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (project['repository_url'] != null)
                      TextButton.icon(
                        onPressed: () =>
                            _open(project['repository_url'] as String?),
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
