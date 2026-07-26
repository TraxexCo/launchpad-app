import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        surface:    AppColors.surface,
        primary:    AppColors.studentPrimary,
        secondary:  AppColors.studentAccent,
        tertiary:   AppColors.businessPrimary,
        error:      AppColors.error,
        onSurface:  AppColors.textPrimary,
        onPrimary:  Colors.white,
        outline:    AppColors.border,
      ),
      textTheme: _buildTextTheme(),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor:    Colors.transparent,
        surfaceTintColor:   Colors.transparent,
        elevation:          0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  // Role-tinted gradient helpers
  static LinearGradient studentGradient() => const LinearGradient(
        colors: [AppColors.studentPrimary, AppColors.studentAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient businessGradient() => const LinearGradient(
        colors: [AppColors.businessPrimary, AppColors.businessAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient roleGradient(UserRole role) =>
      role == UserRole.student ? studentGradient() : businessGradient();

  static Color rolePrimary(UserRole role) =>
      role == UserRole.student ? AppColors.studentPrimary : AppColors.businessPrimary;

  static Color roleAccent(UserRole role) =>
      role == UserRole.student ? AppColors.studentAccent : AppColors.businessAccent;

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 52, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, letterSpacing: -2.5, height: 1.05,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 40, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, letterSpacing: -2.0, height: 1.08,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 32, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -1.5, height: 1.12,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 28, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -1.0,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -0.5,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.textMuted, height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.jetBrainsMono(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 10, fontWeight: FontWeight.w400,
        color: AppColors.textMuted, letterSpacing: 0.5,
      ),
    );
  }
}