import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Base canvas
  static const Color background  = Color(0xFFF8FAFC); // slate-50
  static const Color surface     = Color(0xFFFFFFFF); // white
  static const Color surfaceHigh = Color(0xFFF1F5F9); // slate-100
  static const Color border      = Color(0xFFE2E8F0); // slate-200
  static const Color borderHigh  = Color(0xFFCBD5E1); // slate-300

  // Student — Fresh Indigo
  static const Color studentPrimary = Color(0xFF4F46E5); // indigo-600
  static const Color studentAccent  = Color(0xFF818CF8); // indigo-400
  static const Color studentGlow    = Color(0x224F46E5);

  // Business — Trustworthy Emerald
  static const Color businessPrimary = Color(0xFF059669); // emerald-600
  static const Color businessAccent  = Color(0xFF34D399); // emerald-400
  static const Color businessGlow    = Color(0x22059669);

  // Text hierarchy
  static const Color textPrimary   = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF475569); // slate-600
  static const Color textMuted     = Color(0xFF94A3B8); // slate-400
  static const Color textDisabled  = Color(0xFFCBD5E1); // slate-300

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // Animated mesh orbs (Faint pastels for light mode)
  static const Color meshBlue  = Color(0x0C4F46E5); // faint indigo
  static const Color meshAmber = Color(0x0C059669); // faint emerald
  static const Color meshCyan  = Color(0x0CF43F5E); // faint rose

}

// ─────────────────────────────────────────────────────────────────────────────
// SPACING
// ─────────────────────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
  static const double xxxl = 64.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// BORDER RADIUS
// ─────────────────────────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 28.0;
  static const double full = 999.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// DURATIONS
// ─────────────────────────────────────────────────────────────────────────────
class AppDurations {
  AppDurations._();
  static const Duration fast     = Duration(milliseconds: 150);
  static const Duration normal   = Duration(milliseconds: 300);
  static const Duration slow     = Duration(milliseconds: 500);
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
  'Flutter', 'React', 'Vue.js', 'Next.js', 'Angular',
  'PHP', 'Laravel', 'Node.js', 'Python', 'FastAPI',
  'MySQL', 'PostgreSQL', 'MongoDB', 'Firebase', 'Supabase',
  'Figma', 'UI/UX', 'REST API', 'GraphQL',
  'Android', 'iOS', 'React Native', 'Kotlin', 'Swift',
  'Docker', 'Git', 'AWS',
];
