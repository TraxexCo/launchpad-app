import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../services/contract_service.dart';

String contractStatusLabel(String status) => switch (status) {
  'completion_requested' => 'Awaiting Approval',
  'completed' => 'Completed',
  _ => 'In Progress',
};

Color contractStatusColor(String status) => switch (status) {
  'completion_requested' => AppColors.warning,
  'completed' => AppColors.info,
  _ => AppColors.success,
};

class ContractActionPanel extends StatefulWidget {
  final ContractItem contract;
  final bool studentView;
  final Future<void> Function() onChanged;

  const ContractActionPanel({
    super.key,
    required this.contract,
    required this.studentView,
    required this.onChanged,
  });

  @override
  State<ContractActionPanel> createState() => _ContractActionPanelState();
}

class _ContractActionPanelState extends State<ContractActionPanel> {
  bool _working = false;

  Future<bool> _confirm(String title, String message, String action) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _errorMessage(Object error) {
    if (error is PostgrestException) return error.message;
    return 'Something went wrong. Please try again.';
  }

  Future<void> _perform(
    Future<void> Function() operation,
    String success,
  ) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await operation();
      await widget.onChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success), backgroundColor: AppColors.success),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage(error)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _requestCompletion() async {
    final confirmed = await _confirm(
      'Submit completed work?',
      'The business will review the work and either approve it or request changes.',
      'Submit',
    );
    if (!confirmed) return;
    await _perform(
      () => ContractService().requestCompletion(widget.contract.id),
      'Work submitted for business approval.',
    );
  }

  Future<void> _respond(bool approve) async {
    final confirmed = await _confirm(
      approve ? 'Approve project completion?' : 'Request more work?',
      approve
          ? 'This completes the contract and closes the related job.'
          : 'The contract will return to in progress. Explain the changes in project chat.',
      approve ? 'Approve' : 'Request changes',
    );
    if (!confirmed) return;
    await _perform(
      () => ContractService().respondToCompletion(
        widget.contract.id,
        approve: approve,
      ),
      approve
          ? 'Project marked as completed.'
          : 'Contract returned to in progress.',
    );
  }

  Future<void> _openReview() async {
    var rating = 5;
    final controller = TextEditingController();
    var submitting = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: !submitting,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            widget.studentView ? 'Review the business' : 'Review the student',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How was your experience on this project?'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    tooltip: '${index + 1} stars',
                    onPressed: submitting
                        ? null
                        : () => setDialogState(() => rating = index + 1),
                    icon: Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ),
              TextField(
                controller: controller,
                enabled: !submitting,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Review',
                  hintText: 'Share specific, constructive feedback.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (controller.text.trim().length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Write at least 10 characters.'),
                          ),
                        );
                        return;
                      }
                      setDialogState(() => submitting = true);
                      try {
                        await ContractService().submitReview(
                          contractId: widget.contract.id,
                          rating: rating,
                          body: controller.text,
                        );
                        await widget.onChanged();
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Review submitted.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => submitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_errorMessage(error)),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit review'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.contract.status;
    if (status == 'completed') {
      return Align(
        alignment: Alignment.centerLeft,
        child: widget.contract.reviewedByMe
            ? _message(
                Icons.verified_rounded,
                'Review submitted',
                AppColors.info,
              )
            : OutlinedButton.icon(
                onPressed: _working ? null : _openReview,
                icon: const Icon(Icons.star_outline_rounded, size: 18),
                label: Text(
                  widget.studentView ? 'Review business' : 'Review student',
                ),
              ),
      );
    }

    if (status == 'completion_requested') {
      if (widget.studentView) {
        return _message(
          Icons.hourglass_top_rounded,
          'Waiting for business approval',
          AppColors.warning,
        );
      }
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          OutlinedButton(
            onPressed: _working ? null : () => _respond(false),
            child: const Text('Request changes'),
          ),
          FilledButton.icon(
            onPressed: _working ? null : () => _respond(true),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('Approve completion'),
          ),
        ],
      );
    }

    if (widget.studentView) {
      return FilledButton.icon(
        onPressed: _working ? null : _requestCompletion,
        icon: const Icon(Icons.task_alt_rounded, size: 18),
        label: const Text('Submit for approval'),
      );
    }

    return _message(
      Icons.engineering_outlined,
      'Student is working on this project',
      AppColors.success,
    );
  }

  Widget _message(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
