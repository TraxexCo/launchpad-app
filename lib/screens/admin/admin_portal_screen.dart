import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';

class AdminPortalScreen extends StatefulWidget {
  const AdminPortalScreen({super.key});
  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen>
    with SingleTickerProviderStateMixin {
  final _service = AdminService();
  late final TabController _tabs;
  bool _loading = true;
  bool _authorized = false;
  String? _error;
  List<Map<String, dynamic>> _verifications = const [];
  List<Map<String, dynamic>> _reports = const [];
  List<Map<String, dynamic>> _disputes = const [];
  List<Map<String, dynamic>> _payments = const [];
  List<Map<String, dynamic>> _accounts = const [];
  List<Map<String, dynamic>> _jobs = const [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!kIsWeb || !await _service.isAdmin()) {
        setState(() => _authorized = false);
        return;
      }
      final data = await Future.wait([
        _service.verificationQueue(),
        _service.reports(),
        _service.disputes(),
        _service.payments(),
        _service.accounts(),
        _service.jobs(),
      ]);
      if (!mounted) return;
      setState(() {
        _authorized = true;
        _verifications = data[0];
        _reports = data[1];
        _disputes = data[2];
        _payments = data[3];
        _accounts = data[4];
        _jobs = data[5];
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is PostgrestException ? error.message : '$error',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _note(
    String title, {
    String action = 'Confirm',
    String? helper,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (helper != null) ...[
                  Text(
                    helper,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: controller,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 500,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Decision notes',
                    helperText: 'At least 10 characters',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: controller.text.trim().length >= 10
                  ? () => Navigator.pop(context, controller.text.trim())
                  : null,
              child: Text(action),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _act(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is PostgrestException ? error.message : '$error',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openDisputeCase(int contractId) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final caseFile = await _service.disputeCase(contractId);
      if (!mounted) return;
      Navigator.pop(context);
      await showDialog<void>(
        context: context,
        builder: (context) => _DisputeCaseDialog(
          caseFile: caseFile,
          openFile: (path) async {
            final url = await _service.deliverableFileUrl(path);
            await launchUrl(Uri.parse(url));
          },
        ),
      );
    } catch (error) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is PostgrestException ? error.message : '$error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 72,
      titleSpacing: 24,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.studentPrimary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.north_east_rounded,
              color: AppColors.ink,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LAUNCHPAD',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'ADMIN OPERATIONS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: _authorized
          ? TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: const [
                Tab(icon: Icon(Icons.badge_outlined), text: 'Verification'),
                Tab(icon: Icon(Icons.flag_outlined), text: 'Reports'),
                Tab(icon: Icon(Icons.gavel_outlined), text: 'Disputes'),
                Tab(icon: Icon(Icons.people_outline_rounded), text: 'Accounts'),
                Tab(icon: Icon(Icons.work_outline_rounded), text: 'Jobs'),
                Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Payments'),
              ],
            )
          : null,
      actions: [
        IconButton(
          tooltip: 'Refresh admin data',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: () async {
            await AuthService().logout();
            if (context.mounted) context.go('/admin/login');
          },
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Sign out'),
        ),
        const SizedBox(width: 16),
      ],
    ),
    body: AppBackground(
      tintColor: AppColors.studentPrimary,
      child: _loading
          ? _loadingView()
          : _error != null
          ? _center(_error!, Icons.error_outline_rounded)
          : !_authorized
          ? _center(
              kIsWeb
                  ? 'This account is not on the administrator allowlist.'
                  : 'The admin portal is available on web only.',
              Icons.admin_panel_settings_outlined,
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _verificationTab(),
                _reportTab(),
                _disputeTab(),
                _accountTab(),
                _jobTab(),
                _paymentTab(),
              ],
            ),
    ),
  );

  Widget _loadingView() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1180),
      child: GridView.count(
        padding: const EdgeInsets.all(28),
        crossAxisCount: MediaQuery.sizeOf(context).width > 900 ? 3 : 1,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 2.7,
        children: List.generate(
          6,
          (_) => Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _verificationTab() => _queue(
    _verifications,
    empty: 'No verification documents',
    builder: (item) {
      final profile = item['profiles'] as Map<String, dynamic>?;
      return _adminCard(
        title: profile?['full_name']?.toString() ?? 'User',
        tag: item['status'].toString(),
        detail:
            '${item['document_type'].toString().replaceAll('_', ' ')} · ${profile?['role'] ?? 'account'}',
        actions: item['status'] == 'pending'
            ? [
                TextButton.icon(
                  onPressed: () async {
                    final url = await _service.verificationFileUrl(
                      item['owner_id'] as String,
                      item['id'] as int,
                    );
                    await launchUrl(Uri.parse(url));
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open'),
                ),
                TextButton(
                  onPressed: () async {
                    final note = await _note(
                      'Reject document',
                      action: 'Reject',
                    );
                    if (note != null) {
                      await _act(
                        () => _service.reviewVerification(
                          item['id'] as int,
                          false,
                          note,
                        ),
                      );
                    }
                  },
                  child: const Text('Reject'),
                ),
                FilledButton(
                  onPressed: () => _act(
                    () => _service.reviewVerification(
                      item['id'] as int,
                      true,
                      null,
                    ),
                  ),
                  child: const Text('Approve'),
                ),
              ]
            : const [],
      );
    },
  );

  Widget _reportTab() => _queue(
    _reports,
    empty: 'No reports',
    builder: (item) => _adminCard(
      title: '${item['target_type']}: ${item['target_label']}',
      tag: item['status'].toString(),
      detail: '${item['reason']}\n${item['details'] ?? ''}',
      actions: item['status'] == 'open' || item['status'] == 'reviewing'
          ? [
              TextButton(
                onPressed: () async {
                  final note = await _note('Dismiss report', action: 'Dismiss');
                  if (note != null) {
                    await _act(
                      () => _service.resolveReport(
                        item['id'] as int,
                        'dismissed',
                        note,
                      ),
                    );
                  }
                },
                child: const Text('Dismiss'),
              ),
              FilledButton(
                onPressed: () async {
                  final note = await _note('Resolve report', action: 'Resolve');
                  if (note != null) {
                    await _act(
                      () => _service.resolveReport(
                        item['id'] as int,
                        'resolved',
                        note,
                      ),
                    );
                  }
                },
                child: const Text('Resolve'),
              ),
            ]
          : const [],
    ),
  );

  Widget _disputeTab() => _queue(
    _disputes,
    empty: 'No open disputes',
    builder: (item) {
      final job = item['jobs'] as Map<String, dynamic>?;
      final paymentRelation = item['payments'];
      final payment = paymentRelation is List && paymentRelation.isNotEmpty
          ? paymentRelation.first as Map<String, dynamic>
          : paymentRelation is Map<String, dynamic>
          ? paymentRelation
          : null;
      final paymentStatus = payment?['status']?.toString();
      final fundsHeld = paymentStatus == 'paid';
      return _adminCard(
        title: job?['title']?.toString() ?? 'Contract #${item['id']}',
        tag: 'disputed',
        detail:
            '${item['dispute_reason']?.toString() ?? 'No reason supplied'}\n'
            '${fundsHeld ? 'Payment is held: resume the project or record a refund.' : 'Payment status: ${paymentStatus ?? 'not funded'}'}',
        actions: [
          OutlinedButton.icon(
            onPressed: () => _openDisputeCase(item['id'] as int),
            icon: const Icon(Icons.fact_check_outlined, size: 18),
            label: const Text('Review evidence'),
          ),
          TextButton(
            onPressed: () async {
              final note = await _note('Resume contract');
              if (note != null) {
                await _act(
                  () => _service.resolveDispute(
                    item['id'] as int,
                    'resume',
                    note,
                  ),
                );
              }
            },
            child: const Text('Resume'),
          ),
          if (!fundsHeld)
            TextButton(
              onPressed: () async {
                final note = await _note('Cancel contract');
                if (note != null) {
                  await _act(
                    () => _service.resolveDispute(
                      item['id'] as int,
                      'cancel',
                      note,
                    ),
                  );
                }
              },
              child: const Text('Cancel'),
            ),
          FilledButton(
            onPressed: () async {
              final note = await _note(
                'Record classroom refund',
                action: 'Record refund',
                helper:
                    'PayMongo test transactions do not move real funds. This records the approved refund for the classroom workflow.',
              );
              if (note != null) {
                await _act(
                  () => _service.resolveDispute(
                    item['id'] as int,
                    'refund',
                    note,
                  ),
                );
              }
            },
            child: const Text('Record test refund'),
          ),
        ],
      );
    },
  );

  Widget _accountTab() => _queue(
    _accounts,
    empty: 'No registered accounts',
    builder: (item) {
      final userId = item['id'].toString();
      final suspended = item['suspended_at'] != null;
      return _adminCard(
        title: item['full_name']?.toString() ?? 'Unnamed account',
        tag: suspended ? 'suspended' : 'active',
        detail: suspended
            ? '${item['role']} · ${item['suspension_reason'] ?? 'No suspension reason recorded'}'
            : '${item['role']} · joined ${_date(item['created_at'])}',
        actions: [
          if (suspended)
            FilledButton.icon(
              onPressed: () => _act(
                () => _service.setUserSuspension(userId, suspended: false),
              ),
              icon: const Icon(Icons.person_add_alt_rounded, size: 18),
              label: const Text('Restore account'),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final note = await _note(
                  'Suspend account',
                  action: 'Suspend',
                  helper:
                      'Explain the policy violation. The user will be signed out and blocked.',
                );
                if (note != null) {
                  await _act(
                    () => _service.setUserSuspension(
                      userId,
                      suspended: true,
                      reason: note,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.block_rounded, size: 18),
              label: const Text('Suspend'),
            ),
        ],
      );
    },
  );

  Widget _jobTab() => _queue(
    _jobs,
    empty: 'No job posts',
    builder: (item) {
      final jobId = item['id'] as int;
      final business = item['business_profiles'] as Map<String, dynamic>?;
      final open = item['status'] == 'open';
      final moderated = item['moderated_at'] != null;
      return _adminCard(
        title: item['title']?.toString() ?? 'Job #$jobId',
        tag: item['status'].toString(),
        detail:
            '${business?['business_name'] ?? 'Business'} · PHP ${item['budget']} · ${item['location']}\n'
            '${moderated ? item['moderation_note'] ?? 'Moderated by an administrator' : 'Posted ${_date(item['created_at'])}'}',
        actions: [
          if (open)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final note = await _note(
                  'Close job post',
                  action: 'Close job',
                  helper:
                      'Explain why this post must be removed from the marketplace.',
                );
                if (note != null) {
                  await _act(
                    () => _service.moderateJob(jobId, close: true, note: note),
                  );
                }
              },
              icon: const Icon(Icons.visibility_off_outlined, size: 18),
              label: const Text('Close job'),
            )
          else if (item['status'] == 'closed' && moderated)
            OutlinedButton.icon(
              onPressed: () async {
                final note = await _note(
                  'Reopen job post',
                  action: 'Reopen',
                  helper:
                      'Record why this post is safe to return to the marketplace.',
                );
                if (note != null) {
                  await _act(
                    () => _service.moderateJob(jobId, close: false, note: note),
                  );
                }
              },
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Reopen job'),
            ),
        ],
      );
    },
  );

  Widget _paymentTab() => _queue(
    _payments,
    empty: 'No payment records',
    builder: (item) => _adminCard(
      title: item['reference_number']?.toString() ?? 'Payment #${item['id']}',
      tag: item['status'].toString(),
      detail:
          'Contract ${item['contract_id']} · PHP ${item['amount']} · ${item['payment_method'] ?? 'awaiting payment'}',
      actions: const [],
    ),
  );

  String _date(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return 'unknown date';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _queue(
    List<Map<String, dynamic>> items, {
    required String empty,
    required Widget Function(Map<String, dynamic>) builder,
  }) => items.isEmpty
      ? _center(empty, Icons.inbox_outlined)
      : RefreshIndicator(
          onRefresh: _load,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: items.length,
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: builder(items[index]),
                ),
              ),
            ),
          ),
        );
  Widget _adminCard({
    required String title,
    required String tag,
    required String detail,
    required List<Widget> actions,
  }) => AppCard(
    accentColor: AppColors.businessPrimary,
    padding: const EdgeInsets.all(20),
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              _tag(tag),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            detail,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    ),
  );

  Widget _tag(String text) {
    final tone = switch (text.toLowerCase()) {
      'active' ||
      'verified' ||
      'paid' ||
      'released' ||
      'resolved' => AppColors.success,
      'suspended' || 'rejected' || 'failed' || 'disputed' => AppColors.error,
      'pending' ||
      'open' ||
      'reviewing' ||
      'checkout_created' => AppColors.warning,
      _ => AppColors.info,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .10),
        border: Border.all(color: tone.withValues(alpha: .45)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: .6,
          color: tone,
        ),
      ),
    );
  }

  Widget _center(String text, IconData icon) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}

class _DisputeCaseDialog extends StatelessWidget {
  const _DisputeCaseDialog({required this.caseFile, required this.openFile});

  final Map<String, dynamic> caseFile;
  final Future<void> Function(String path) openFile;

  Map<String, dynamic> _map(String key) =>
      Map<String, dynamic>.from((caseFile[key] as Map?) ?? const {});
  List<Map<String, dynamic>> _list(String key) =>
      ((caseFile[key] as List?) ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

  String _when(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return 'Unknown time';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final contract = _map('contract');
    final job = _map('job');
    final proposal = _map('proposal');
    final student = _map('student');
    final business = _map('business');
    final payment = _map('payment');
    final messages = _list('messages');
    final deliverables = _list('deliverables');
    final events = _list('events');
    final studentMessages = messages
        .where((m) => m['sender_id'] == student['id'])
        .length;
    final businessMessages = messages.length - studentMessages;
    final revisions = events
        .where((e) => e['event_type'] == 'revision_requested')
        .length;
    final checks = <String>[
      '${deliverables.length} submission${deliverables.length == 1 ? '' : 's'} recorded',
      '$studentMessages student and $businessMessages business messages retained',
      '$revisions revision request${revisions == 1 ? '' : 's'} recorded',
      'Payment status: ${payment['status'] ?? 'not recorded'}',
    ];

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Dispute case #${contract['id']}'),
          leading: IconButton(
            tooltip: 'Close case file',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _caseSection(
                'Neutral case brief',
                Icons.balance_outlined,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student['full_name'] ?? 'Student'} disputes with '
                      '${business['business_name'] ?? business['full_name'] ?? 'Business'} '
                      'over “${job['title'] ?? 'Project'}”.',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Complaint: ${contract['dispute_reason'] ?? 'No reason supplied'}',
                    ),
                    const SizedBox(height: 12),
                    ...checks.map(
                      (check) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 17),
                            const SizedBox(width: 8),
                            Expanded(child: Text(check)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Decision support: compare the agreed scope with the actual files and links, then check whether revision requests were specific and whether each party responded. This summary is evidence assistance, not a verdict.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              _caseSection(
                'Agreed project scope',
                Icons.assignment_outlined,
                Text(
                  '${job['description'] ?? 'No description'}\n\n'
                  'Original budget: PHP ${job['budget'] ?? '—'}  ·  '
                  'Accepted proposal: PHP ${proposal['proposed_budget'] ?? '—'}  ·  '
                  '${proposal['estimated_timeline_weeks'] ?? '—'} week(s)\n\n'
                  'Student proposal: ${proposal['pitch_text'] ?? 'No proposal text'}',
                  style: const TextStyle(height: 1.5),
                ),
              ),
              _caseSection(
                'Submission evidence',
                Icons.inventory_2_outlined,
                deliverables.isEmpty
                    ? const Text('No deliverables were submitted.')
                    : Column(
                        children: deliverables.map((item) {
                          final path = item['storage_path']?.toString();
                          final link = item['link_url']?.toString();
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Submission ${item['submission_number']}: ${item['title']}',
                            ),
                            subtitle: Text(
                              '${item['summary']}\n${_when(item['created_at'])}',
                            ),
                            isThreeLine: true,
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                if (link != null && link.isNotEmpty)
                                  IconButton(
                                    tooltip: 'Open submitted link',
                                    onPressed: () => launchUrl(Uri.parse(link)),
                                    icon: const Icon(Icons.link_rounded),
                                  ),
                                if (path != null && path.isNotEmpty)
                                  IconButton(
                                    tooltip: 'Open submitted file',
                                    onPressed: () => openFile(path),
                                    icon: const Icon(Icons.file_open_outlined),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              _caseSection(
                'Conversation record',
                Icons.forum_outlined,
                messages.isEmpty
                    ? const Text('No project messages were recorded.')
                    : Column(
                        children: messages
                            .map(
                              (item) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  item['sender_name']?.toString() ?? 'User',
                                ),
                                subtitle: Text(item['body']?.toString() ?? ''),
                                trailing: Text(_when(item['created_at'])),
                              ),
                            )
                            .toList(),
                      ),
              ),
              _caseSection(
                'Audit timeline',
                Icons.history_rounded,
                Column(
                  children: events
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.radio_button_checked,
                            size: 16,
                          ),
                          title: Text(
                            item['event_type'].toString().replaceAll('_', ' '),
                          ),
                          subtitle: Text(
                            item['message']?.toString() ?? 'No note',
                          ),
                          trailing: Text(_when(item['created_at'])),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _caseSection(String title, IconData icon, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.businessPrimary),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}
