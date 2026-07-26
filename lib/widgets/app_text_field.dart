import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

/// Clean, modern text input with subtle border on focus.
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Color accentColor;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.accentColor = AppColors.studentPrimary,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.enabled = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField>
    with SingleTickerProviderStateMixin {
  final FocusNode _focus = FocusNode();
  bool _hide = true;

  @override
  void initState() {
    super.initState();
    _hide = widget.obscureText;
    _focus.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
    );

    final focusedBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: widget.accentColor, width: 2),
    );

    final errorBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    );

    return TextFormField(
      controller: widget.controller,
      focusNode: _focus,
      obscureText: widget.obscureText && _hide,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        filled: true,
        fillColor: widget.enabled ? AppColors.surface : AppColors.surfaceHigh,
        hintStyle: GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 14),
        labelStyle: GoogleFonts.inter(
          color: _focus.hasFocus ? widget.accentColor : AppColors.textSecondary,
          fontSize: 14, fontWeight: FontWeight.w500,
        ),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.obscureText
            ? GestureDetector(
                onTap: () => setState(() => _hide = !_hide),
                child: Icon(
                  _hide ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              )
            : widget.suffixIcon,
        border: borderStyle,
        enabledBorder: borderStyle,
        focusedBorder: focusedBorderStyle,
        errorBorder: errorBorderStyle,
        focusedErrorBorder: errorBorderStyle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}
