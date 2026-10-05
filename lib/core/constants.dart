import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // LaunchPad "Night Mission" canvas
  static const Color background = Color(0xFF070B14);
  static const Color surface = Color(0xFF0E1522);
  static const Color surfaceHigh = Color(0xFF151F30);
  static const Color surfaceMuted = Color(0xFF1B2739);
  static const Color border = Color(0xFF243249);
  static const Color borderHigh = Color(0xFF3A506F);
  static const Color ink = Color(0xFF05070C);
  static const Color signalYellow = Color(0xFFFFD166);

  // Student — orbit violet + electric cyan
  static const Color studentPrimary = Color(0xFF9B7BFF);
  static const Color studentAccent = Color(0xFF4EDBFF);
  static const Color studentGlow = Color(0x339B7BFF);

  // Business — launch mint + opportunity amber
  static const Color businessPrimary = Color(0xFF42E8A5);
  static const Color businessAccent = Color(0xFFFFC857);
  static const Color businessGlow = Color(0x3342E8A5);

  // Text hierarchy
  static const Color textPrimary = Color(0xFFF5F7FC);
  static const Color textSecondary = Color(0xFFADB9CD);
  static const Color textMuted = Color(0xFF718099);
  static const Color textDisabled = Color(0xFF47556B);

  // Semantic
  static const Color success = Color(0xFF42E8A5);
  static const Color warning = Color(0xFFFFC857);
  static const Color error = Color(0xFFFF6B7A);
  static const Color info = Color(0xFF4EDBFF);
  static const Color violet = Color(0xFFB28CFF);

  // Animated launch-field glows
  static const Color meshBlue = Color(0x269B7BFF);
  static const Color meshAmber = Color(0x1AFFC857);
  static const Color meshCyan = Color(0x1F4EDBFF);
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
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
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
