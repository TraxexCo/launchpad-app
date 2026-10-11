import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/contract_lifecycle.dart';
import '../../services/contract_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/contract_action_panel.dart';

class ContractWorkspaceScreen extends StatefulWidget {
  final int contractId;
  const ContractWorkspaceScreen({super.key, required this.contractId});

  @override
  State<ContractWorkspaceScreen> createState() =>
      _ContractWorkspaceScreenState();
}

class _ContractWorkspaceScreenState extends State<ContractWorkspaceScreen> {
  final _service = ContractService();
  ContractItem? _contract;
  List<ContractDeliverable> _deliverables = const [];
  List<ContractEvent> _events = const [];
  bool _loading = true;
  bool _working = false;
  String? _error;

  bool get _studentView =>
      _contract?.studentId == Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        _service.getContract(widget.contractId),
        _service.getDeliverables(widget.contractId),
        _service.getEvents(widget.contractId),
      ]);
      if (!mounted) return;
      setState(() {
        _contract = results[0] as ContractItem;
        _deliverables = results[1] as List<ContractDeliverable>;
        _events = results[2] as List<ContractEvent>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _message(Object error) => error is PostgrestException
      ? error.message
      : 'The project workspace could not be loaded.';

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success), backgroundColor: AppColors.success),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_message(error)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<String?> _askReason({
    required String title,
    required String hint,
    required String action,
    required int minimum,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          maxLength: 500,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.length >= minimum) Navigator.pop(dialogContext, value);
            },
            child: Text(action),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _submit() async {
    final title = TextEditingController();
    final summary = TextEditingController();
    final link = TextEditingController();
    PlatformFile? file;
    int? fileSize;
    var submitting = false;
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Submit a milestone',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Attach a file, add a link, or include both. Every submission stays in the project history.',
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Deliverable title',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: summary,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'What changed or was completed?',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: link,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Project or preview link (optional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: submitting
                      ? null
                      : () async {
                          final picked = await FilePicker.pickFile(
                            allowedExtensions: const [
                              'pdf',
                              'zip',
                              'jpg',
                              'jpeg',
                              'png',
                              'txt',
                            ],
                            type: FileType.custom,
                          );
                          if (picked != null) {
                            final size =
                                picked.lengthSync() ?? await picked.length();
                            setSheetState(() {
                              file = picked;
                              fileSize = size;
                            });
                          }
                        },
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(file?.name ?? 'Attach file (max 10 MB)'),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton.student(
                  label: 'Send for review',
                  icon: Icons.rocket_launch_rounded,
                  isLoading: submitting,
                  onPressed: () async {
                    final cleanLink = link.text.trim();
                    if (title.text.trim().length < 2 ||
                        summary.text.trim().length < 10 ||
                        (file == null && cleanLink.isEmpty)) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Add a title, a clear summary, and a file or link.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (file != null &&
                        (fileSize == null || fileSize! > 10 * 1024 * 1024)) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Choose a readable file smaller than 10 MB.',
                          ),
                        ),
                      );
                      return;
                    }
                    setSheetState(() => submitting = true);
                    try {
                      String? storagePath;
                      if (file != null) {
                        final bytes = await file!.readAsBytes();
                        storagePath = await _service.uploadDeliverable(
                          contractId: widget.contractId,
                          fileName: file!.name,
                          bytes: bytes,
                        );
                      }
                      await _service.submitDeliverable(
                        contractId: widget.contractId,
                        title: title.text,
                        summary: summary.text,
                        linkUrl: cleanLink.isEmpty ? null : cleanLink,
                        storagePath: storagePath,
                        fileName: file?.name,
                      );
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext, true);
                      }
                    } catch (error) {
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: Text(_message(error)),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        setSheetState(() => submitting = false);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    title.dispose();
    summary.dispose();
    link.dispose();
    if (submitted == true) await _load();
  }

  Future<void> _openLink(String value) async {
    var uri = Uri.tryParse(value);
    if (uri == null) return;
    if (!uri.hasScheme) uri = Uri.tryParse('https://$value');
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openFile(String path) async {
    final url = await _service.createFileUrl(path);
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project workspace')),
      body: AppBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(onRefresh: _load, child: _content(_contract!)),
      ),
    );
  }

  Widget _content(ContractItem contract) {
    final accent = _studentView
        ? AppColors.studentPrimary
        : AppColors.businessPrimary;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppCard(
          accentColor: accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      contract.jobTitle,
                      style: GoogleFonts.manrope(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _statusPill(contract.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _studentView ? contract.businessName : contract.studentName,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      'BUDGET',
                      '₱${contract.budget.toStringAsFixed(0)}',
                    ),
                  ),
                  Expanded(
                    child: _stat('TIMELINE', '${contract.timelineWeeks} weeks'),
                  ),
                  Expanded(
                    child: _stat('Submissions', '${_deliverables.length}'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (contract.revisionMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          _notice(
            Icons.rate_review_rounded,
            'Revision requested',
            contract.revisionMessage!,
            AppColors.warning,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Next action',
          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        _actions(contract),
        const SizedBox(height: AppSpacing.xl),
        _sectionTitle('Deliverables', Icons.inventory_2_outlined),
        const SizedBox(height: AppSpacing.sm),
        if (_deliverables.isEmpty)
          _empty(
            'No work submitted yet',
            'Files and links will appear here in numbered revisions.',
          )
        else
          ..._deliverables.map(_deliverable),
        const SizedBox(height: AppSpacing.xl),
        _sectionTitle('Activity', Icons.timeline_rounded),
        const SizedBox(height: AppSpacing.sm),
        if (_events.isEmpty)
          _empty(
            'No recorded activity',
            'New contract actions will build a permanent timeline.',
          )
        else
          ..._events.map(_event),
        const SizedBox(height: AppSpacing.xl),
        if (ContractLifecycle.canDispute(contract.status))
          Row(
            children: [
              if (ContractLifecycle.canCancel(
                status: contract.status,
                funded:
                    contract.paymentStatus == 'paid' ||
                    contract.paymentStatus == 'released',
              )) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _working
                        ? null
                        : () async {
                            final reason = await _askReason(
                              title: 'Cancel contract',
                              hint:
                                  'Explain why this unfunded contract should end.',
                              action: 'Cancel contract',
                              minimum: 10,
                            );
                            if (reason != null) {
                              await _run(
                                () => _service.cancelContract(
                                  contract.id,
                                  reason,
                                ),
                                'Contract cancelled.',
                              );
                            }
                          },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _working
                      ? null
                      : () async {
                          final reason = await _askReason(
                            title: 'Open a dispute',
                            hint:
                                'Describe the issue, what happened, and the resolution you need.',
                            action: 'Open dispute',
                            minimum: 20,
                          );
                          if (reason != null) {
                            await _run(
                              () =>
                                  _service.disputeContract(contract.id, reason),
                              'Dispute opened for admin review.',
                            );
                          }
                        },
                  icon: const Icon(Icons.gavel_rounded),
                  label: const Text('Dispute'),
                ),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _actions(ContractItem contract) {
    if (ContractLifecycle.canStart(contract.status)) {
      return _studentView
          ? AppButton.student(
              label: 'Start project work',
              icon: Icons.play_arrow_rounded,
              isLoading: _working,
              onPressed: () => _run(
                () => _service.startWork(contract.id),
                'Project is now in progress.',
              ),
            )
          : _notice(
              Icons.verified_rounded,
              'Funding confirmed',
              'The student can now start the project.',
              AppColors.success,
            );
    }
    if (ContractLifecycle.canSubmit(contract.status)) {
      return _studentView
          ? AppButton.student(
              label: contract.status == 'revision_requested'
                  ? 'Submit revised work'
                  : 'Submit deliverable',
              icon: Icons.upload_file_rounded,
              onPressed: _submit,
            )
          : _notice(
              Icons.engineering_rounded,
              'Work in progress',
              'You will be notified when a deliverable is submitted.',
              AppColors.info,
            );
    }
    if (ContractLifecycle.canReview(contract.status)) {
      if (_studentView) {
        return _notice(
          Icons.hourglass_top_rounded,
          'Under review',
          'The business is reviewing your latest submission.',
          AppColors.warning,
        );
      }
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _working
                  ? null
                  : () async {
                      final note = await _askReason(
                        title: 'Request a revision',
                        hint:
                            'Give specific, actionable changes for the student.',
                        action: 'Send request',
                        minimum: 5,
                      );
                      if (note != null) {
                        await _run(
                          () => _service.respondToCompletion(
                            contract.id,
                            approve: false,
                            revisionNote: note,
                          ),
                          'Revision request sent.',
                        );
                      }
                    },
              child: const Text('Request revision'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FilledButton.icon(
              onPressed: _working
                  ? null
                  : () => _run(
                      () => _service.respondToCompletion(
                        contract.id,
                        approve: true,
                      ),
                      'Project completed.',
                    ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Approve'),
            ),
          ),
        ],
      );
    }
    final detail = contract.status == 'cancelled'
        ? contract.cancellationReason
        : contract.status == 'disputed'
        ? contract.disputeReason
        : 'This project has reached its final state.';
    return _notice(
      Icons.flag_circle_rounded,
      contractStatusLabel(contract.status),
      detail ?? '',
      contractStatusColor(contract.status),
    );
  }

  Widget _deliverable(ContractDeliverable item) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Submission ${item.submissionNumber}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.info,
                ),
              ),
              const Spacer(),
              Text(
                _date(item.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.summary,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          if (item.linkUrl != null || item.storagePath != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (item.linkUrl != null)
                  TextButton.icon(
                    onPressed: () => _openLink(item.linkUrl!),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open link'),
                  ),
                if (item.storagePath != null)
                  TextButton.icon(
                    onPressed: () => _openFile(item.storagePath!),
                    icon: const Icon(Icons.download_rounded),
                    label: Text(item.originalFileName ?? 'Open file'),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );

  Widget _event(ContractEvent item) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: contractStatusColor(item.type).withValues(alpha: .14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _eventIcon(item.type),
            size: 17,
            color: contractStatusColor(item.type),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contractStatusLabel(item.type),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (item.message?.isNotEmpty == true)
                Text(
                  item.message!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              Text(
                _date(item.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _statusPill(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: contractStatusColor(status).withValues(alpha: .14),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      contractStatusLabel(status),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: contractStatusColor(status),
      ),
    ),
  );
  Widget _stat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1,
          color: AppColors.textMuted,
        ),
      ),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
  Widget _sectionTitle(String title, IconData icon) => Row(
    children: [
      Icon(icon, size: 19, color: AppColors.info),
      const SizedBox(width: 8),
      Text(
        title,
        style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    ],
  );
  Widget _empty(String title, String body) => AppCard(
    child: Column(
      children: [
        const Icon(
          Icons.space_dashboard_outlined,
          size: 32,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
  Widget _notice(IconData icon, String title, String body, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          border: Border.all(color: color.withValues(alpha: .28)),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w800, color: color),
                  ),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
  String _date(DateTime value) =>
      '${value.month}/${value.day}/${value.year} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  IconData _eventIcon(String type) => switch (type) {
    'funded' => Icons.account_balance_wallet_rounded,
    'started' => Icons.play_arrow_rounded,
    'submitted' => Icons.upload_file_rounded,
    'revision_requested' => Icons.rate_review_rounded,
    'completed' => Icons.check_circle_rounded,
    'cancelled' => Icons.cancel_rounded,
    'disputed' => Icons.gavel_rounded,
    _ => Icons.bolt_rounded,
  };
}
