import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../services/contract_service.dart';

String contractStatusLabel(String status) => switch (status) {
  'funded' => 'Funded',
  'submitted' => 'Submitted',
  'revision_requested' => 'Revision Requested',
  'completed' => 'Completed',
  'cancelled' => 'Cancelled',
  'disputed' => 'Disputed',
  'started' => 'Work Started',
  _ => 'In Progress',
};

Color contractStatusColor(String status) => switch (status) {
  'funded' => AppColors.success,
  'submitted' || 'revision_requested' => AppColors.warning,
  'completed' => AppColors.info,
  'cancelled' || 'disputed' => AppColors.error,
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
  final bool _working = false;

  String _errorMessage(Object error) {
    if (error is PostgrestException) return error.message;
    return 'Something went wrong. Please try again.';
  }

  Future<void> _requestCompletion() async {
    await context.push('/contract/${widget.contract.id}');
    await widget.onChanged();
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

  Future<void> _openPayment() async {
    final contract = widget.contract;
    final route = Uri(
      path: '/payment/${contract.id}',
      queryParameters: {
        'title': contract.jobTitle,
        'amount': contract.budget.toStringAsFixed(2),
        if (widget.studentView) 'student': '1',
      },
    ).toString();
    final changed = await context.push<bool>(route);
    if (changed == true) await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.contract.status;
    final paymentStatus = widget.contract.paymentStatus;
    final funded = paymentStatus == 'paid' || paymentStatus == 'released';

    if (!funded && status != 'completed') {
      if (widget.studentView) {
        return InkWell(
          onTap: _openPayment,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: _message(
            Icons.hourglass_bottom_rounded,
            paymentStatus == 'checkout_created'
                ? 'Business payment awaiting confirmation · View'
                : 'Waiting for business to fund project · View',
            AppColors.warning,
          ),
        );
      }
      return FilledButton.icon(
        onPressed: _working ? null : _openPayment,
        icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
        label: Text(
          paymentStatus == 'checkout_created'
              ? 'Continue PayMongo payment'
              : 'Fund project with PayMongo',
        ),
      );
    }
    if (status == 'completed') {
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          OutlinedButton.icon(
            onPressed: _openPayment,
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Payment receipt'),
          ),
          widget.contract.reviewedByMe
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
        ],
      );
    }

    return FilledButton.icon(
      onPressed: _working ? null : _requestCompletion,
      icon: const Icon(Icons.space_dashboard_outlined, size: 18),
      label: Text(
        status == 'submitted' && !widget.studentView
            ? 'Review deliverable'
            : 'Open project workspace',
      ),
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
            style: GoogleFonts.manrope(
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
