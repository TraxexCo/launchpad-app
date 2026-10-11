import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Campus Utility palette: neutral graphite with one brand action color.
  static const Color background = Color(0xFF101114);
  static const Color surface = Color(0xFF181A1F);
  static const Color surfaceHigh = Color(0xFF202228);
  static const Color surfaceMuted = Color(0xFF292C33);
  static const Color border = Color(0xFF34363D);
  static const Color borderHigh = Color(0xFF50535C);
  static const Color ink = Color(0xFF17181B);
  static const Color signalYellow = Color(0xFFFF6A3D);
  static const Color brandWarm = Color(0xFFFF9A5A);
  static const Color brandDeep = Color(0xFF9F3520);

  // Role is communicated through content, not competing color systems.
  static const Color studentPrimary = Color(0xFFFF6A3D);
  static const Color studentAccent = Color(0xFFFF6A3D);
  static const Color studentGlow = Color(0x00FF6A3D);
  static const Color businessPrimary = Color(0xFFFF6A3D);
  static const Color businessAccent = Color(0xFFFF6A3D);
  static const Color businessGlow = Color(0x00FF6A3D);

  // Text hierarchy
  static const Color textPrimary = Color(0xFFF6F3EA);
  static const Color textSecondary = Color(0xFFC7C6C2);
  static const Color textMuted = Color(0xFF92959D);
  static const Color textDisabled = Color(0xFF666A73);

  // Semantic
  static const Color success = Color(0xFF4FB286);
  static const Color warning = Color(0xFFE6A64C);
  static const Color error = Color(0xFFE06464);
  static const Color info = Color(0xFF6FA8DC);
  static const Color violet = Color(0xFFFF6A3D);

  // Animated launch-field glows
  static const Color meshBlue = Color(0x00FFFFFF);
  static const Color meshAmber = Color(0x00FFFFFF);
  static const Color meshCyan = Color(0x00FFFFFF);
}

// ─────────────────────────────────────────────────────────────────────────────
// SPACING
// ─────────────────────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// BORDER RADIUS
// ─────────────────────────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 16.0;
  static const double full = 999.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// DURATIONS
// ─────────────────────────────────────────────────────────────────────────────
class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  static const Duration orbCycle = Duration(seconds: 14);
}

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────
enum UserRole { student, business }

enum ProposalStatus { draft, sent, accepted, rejected }

// ─────────────────────────────────────────────────────────────────────────────
// STATIC DATA
// ─────────────────────────────────────────────────────────────────────────────
const List<String> kSkillOptions = [
  'Flutter',
  'Dart',
  'React',
  'Vue.js',
  'Next.js',
  'Angular',
  'PHP',
  'Laravel',
  'Node.js',
  'Python',
  'FastAPI',
  'MySQL',
  'PostgreSQL',
  'MongoDB',
  'Firebase',
  'Supabase',
  'Figma',
  'UI/UX',
  'REST API',
  'GraphQL',
  'Android',
  'iOS',
  'React Native',
  'Kotlin',
  'Swift',
  'Docker',
  'Git',
  'AWS',
];
