import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

/// Terminal-style status badge with optional pulsing dot.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool pulsing;

  const StatusBadge({super.key, required this.label, required this.color, this.pulsing = false});

  factory StatusBadge.verified() =>
      const StatusBadge(label: 'Verified', color: AppColors.success);
  factory StatusBadge.pending() =>
      const StatusBadge(label: 'Pending Review', color: AppColors.warning, pulsing: true);
  factory StatusBadge.unverified() =>
      const StatusBadge(label: 'Unverified', color: AppColors.error);

  factory StatusBadge.fromProposal(ProposalStatus status) {
    switch (status) {
      case ProposalStatus.draft:
        return const StatusBadge(label: 'Draft', color: AppColors.textMuted);
      case ProposalStatus.sent:
        return const StatusBadge(label: 'Sent', color: AppColors.info, pulsing: true);
      case ProposalStatus.accepted:
        return const StatusBadge(label: 'Accepted', color: AppColors.success);
      case ProposalStatus.rejected:
        return const StatusBadge(label: 'Rejected', color: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: color, pulsing: pulsing),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 10, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  final bool pulsing;
  const _PulseDot({required this.color, required this.pulsing});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _anim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.pulsing) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        width: 6, height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: widget.pulsing ? _anim.value : 1.0),
        ),
      ),
    );
  }
}
