import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  AppTheme._();

  static final _controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.studentPrimary,
      secondary: AppColors.studentPrimary,
      tertiary: AppColors.studentPrimary,
      error: AppColors.error,
      onSurface: AppColors.textPrimary,
      onPrimary: AppColors.ink,
      outline: AppColors.border,
      surfaceContainerHighest: AppColors.surfaceHigh,
    ),
    textTheme: _textTheme,
    splashFactory: InkRipple.splashFactory,
    iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: GoogleFonts.manrope(color: AppColors.textSecondary),
      hintStyle: GoogleFonts.manrope(color: AppColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.studentPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.studentPrimary,
        disabledBackgroundColor: AppColors.surfaceMuted,
        disabledForegroundColor: AppColors.textDisabled,
        shape: _controlShape,
        textStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.borderHigh),
        shape: _controlShape,
        textStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.studentPrimary,
        shape: _controlShape,
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceHigh,
      selectedColor: AppColors.studentPrimary.withValues(alpha: .14),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      labelStyle: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.studentPrimary.withValues(alpha: .16),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: GoogleFonts.manrope(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.studentPrimary,
      linearTrackColor: AppColors.surfaceMuted,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static LinearGradient studentGradient() => const LinearGradient(
    colors: [AppColors.studentPrimary, AppColors.studentPrimary],
  );
  static LinearGradient businessGradient() => studentGradient();
  static LinearGradient roleGradient(UserRole role) => studentGradient();
  static Color rolePrimary(UserRole role) => AppColors.studentPrimary;
  static Color roleAccent(UserRole role) => AppColors.studentPrimary;

  static TextTheme get _textTheme => TextTheme(
    displayLarge: GoogleFonts.manrope(
      fontSize: 40,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: -1.2,
      height: 1.08,
    ),
    displayMedium: GoogleFonts.manrope(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: -1,
      height: 1.08,
    ),
    displaySmall: GoogleFonts.manrope(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -.8,
      height: 1.12,
    ),
    headlineLarge: GoogleFonts.manrope(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -.5,
    ),
    headlineMedium: GoogleFonts.manrope(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -.3,
    ),
    headlineSmall: GoogleFonts.manrope(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    titleLarge: GoogleFonts.manrope(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    titleMedium: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleSmall: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
    bodyLarge: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.45,
    ),
    bodySmall: GoogleFonts.manrope(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
      height: 1.4,
    ),
    labelLarge: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    labelMedium: GoogleFonts.manrope(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
    labelSmall: GoogleFonts.manrope(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
    ),
  );
}
