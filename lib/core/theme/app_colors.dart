import 'package:flutter/material.dart';

/// Color palette for Popcorn Diary.
///
/// The UI is intentionally dark and minimal so posters — the primary
/// visual object — do the work. Metadata and chrome stay quiet.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0B0B10);
  static const Color surface = Color(0xFF15151C);
  static const Color surfaceElevated = Color(0xFF1C1C25);
  static const Color surfaceInput = Color(0xFF20202B);

  // Accent — used for primary actions, active nav, selected chips
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentMuted = Color(0xFF2A4A7A);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF9A9AA5);
  static const Color textTertiary = Color(0xFF6B6B76);

  // Ratings
  static const Color star = Color(0xFF3B82F6);
  static const Color starEmpty = Color(0xFF3A3A46);

  // Semantic
  static const Color danger = Color(0xFFE5484D);
  static const Color success = Color(0xFF4ADE80);

  // Dividers
  static const Color divider = Color(0xFF26262F);

  // Week/date pill badges (unread-count style circle seen in the diary list)
  static const Color badge = accent;
}
