import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

/// Compact semantic status label.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool pulsing;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.pulsing = false,
  });

  factory StatusBadge.verified() =>
      const StatusBadge(label: 'Verified', color: AppColors.success);
  factory StatusBadge.pending() => const StatusBadge(
    label: 'Pending Review',
    color: AppColors.warning,
    pulsing: true,
  );
  factory StatusBadge.unverified() =>
      const StatusBadge(label: 'Unverified', color: AppColors.error);

  factory StatusBadge.fromProposal(ProposalStatus status) {
    switch (status) {
      case ProposalStatus.draft:
        return const StatusBadge(label: 'Draft', color: AppColors.textMuted);
      case ProposalStatus.sent:
        return const StatusBadge(
          label: 'Sent',
          color: AppColors.info,
          pulsing: true,
        );
      case ProposalStatus.accepted:
        return const StatusBadge(label: 'Accepted', color: AppColors.success);
      case ProposalStatus.rejected:
        return const StatusBadge(label: 'Rejected', color: AppColors.error);
    }
  }

  factory StatusBadge.fromApiStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const StatusBadge(
          label: 'Sent',
          color: AppColors.info,
          pulsing: true,
        );
      case 'accepted':
        return const StatusBadge(label: 'Accepted', color: AppColors.success);
      case 'rejected':
        return const StatusBadge(label: 'Rejected', color: AppColors.error);
      default:
        return const StatusBadge(label: 'Draft', color: AppColors.textMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: color, pulsing: pulsing),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.45,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  final Color color;
  final bool pulsing;
  const _PulseDot({required this.color, required this.pulsing});

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
