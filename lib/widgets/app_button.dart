import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

/// Solid product action with short tactile feedback.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final double height;
  final bool outlined;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor = AppColors.studentPrimary,
    this.foregroundColor = AppColors.ink,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
    this.height = 56.0,
    this.outlined = false,
  });

  factory AppButton.student({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isExpanded = true,
    bool outlined = false,
    IconData? icon,
  }) => AppButton(
    label: label,
    onPressed: onPressed,
    backgroundColor: AppColors.studentPrimary,
    foregroundColor: outlined ? AppColors.studentPrimary : AppColors.ink,
    isLoading: isLoading,
    isExpanded: isExpanded,
    outlined: outlined,
    icon: icon,
  );

  factory AppButton.business({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isExpanded = true,
    bool outlined = false,
    IconData? icon,
  }) => AppButton(
    label: label,
    onPressed: onPressed,
    backgroundColor: AppColors.businessPrimary,
    foregroundColor: outlined ? AppColors.businessPrimary : AppColors.ink,
    isLoading: isLoading,
    isExpanded: isExpanded,
    outlined: outlined,
    icon: icon,
  );

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    Widget button = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: _enabled
              ? () {
                  HapticFeedback.lightImpact();
                  widget.onPressed!();
                }
              : null,
          onHighlightChanged: _enabled
              ? (pressed) => pressed ? _ctrl.forward() : _ctrl.reverse()
              : null,
          onFocusChange: (focused) {
            if (_focused != focused) setState(() => _focused = focused);
          },
          borderRadius: radius,
          focusColor: widget.backgroundColor.withValues(alpha: .20),
          hoverColor: widget.backgroundColor.withValues(alpha: .10),
          child: AnimatedBuilder(
            animation: _scale,
            builder: (_, child) =>
                Transform.scale(scale: _scale.value, child: child),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.outlined
                    ? Colors.transparent
                    : (_enabled
                          ? widget.backgroundColor
                          : AppColors.surfaceMuted),
                borderRadius: radius,
                border: Border.all(
                  color: _focused
                      ? AppColors.textPrimary
                      : widget.outlined
                      ? widget.backgroundColor
                      : Colors.transparent,
                  width: _focused ? 2 : 1.5,
                ),
                boxShadow: widget.outlined || !_enabled
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x3D000000),
                          blurRadius: 0,
                          offset: Offset(0, 3),
                        ),
                      ],
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.foregroundColor,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: widget.outlined
                                  ? widget.backgroundColor
                                  : (!_enabled
                                        ? AppColors.textMuted
                                        : widget.foregroundColor),
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Text(
                            widget.label,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: widget.outlined
                                  ? widget.backgroundColor
                                  : (_enabled
                                        ? widget.foregroundColor
                                        : AppColors.textMuted),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    return widget.isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
