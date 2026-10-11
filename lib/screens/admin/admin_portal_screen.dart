import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../services/admin_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
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
      ]);
      if (!mounted) return;
      setState(() {
        _authorized = true;
        _verifications = data[0];
        _reports = data[1];
        _disputes = data[2];
        _payments = data[3];
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

  Future<String?> _note(String title, {String action = 'Confirm'}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Decision notes'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(action),
          ),
        ],
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('LaunchPad Admin'),
      bottom: _authorized
          ? TabBar(
              controller: _tabs,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Verification'),
                Tab(text: 'Reports'),
                Tab(text: 'Disputes'),
                Tab(text: 'Payments'),
              ],
            )
          : null,
      actions: [
        IconButton(
          tooltip: 'Refresh admin data',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: AppBackground(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
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
                _paymentTab(),
              ],
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
      return _adminCard(
        title: job?['title']?.toString() ?? 'Contract #${item['id']}',
        tag: 'disputed',
        detail: item['dispute_reason']?.toString() ?? 'No reason supplied',
        actions: [
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
              final note = await _note('Mark classroom refund');
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
            child: const Text('Refund'),
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

  Widget _queue(
    List<Map<String, dynamic>> items, {
    required String empty,
    required Widget Function(Map<String, dynamic>) builder,
  }) => items.isEmpty
      ? _center(empty, Icons.inbox_outlined)
      : RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            itemBuilder: (_, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: builder(items[index]),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            _tag(tag),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ],
    ),
  );
  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.info.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.info,
      ),
    ),
  );
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
