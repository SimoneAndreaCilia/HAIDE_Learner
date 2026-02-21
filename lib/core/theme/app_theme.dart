import 'package:flutter/material.dart';

/// Centralized design tokens — all magic color numbers live here.
///
/// Usage: `AppColors.gold`, `AppColors.brownDark`, etc.
/// Structure: `abstract final class` (Dart 3) — no instance, no subclass.
/// Every token is `const` for zero runtime allocation.
abstract final class AppColors {
  // ── Gold family (parchment / fantasy theme) ──────────────────────────────
  static const gold = Color(0xFFFFD700);
  static const goldDark = Color(0xFFFFA000);
  static const goldLight = Color(0xFFFFECB3);
  static const parchment = Color(0xFFF5E0B6);
  static const cream = Color(0xFFFDFDF5);

  // ── Brown family (text, borders, gradients) ──────────────────────────────
  static const brownDark = Color(0xFF3E2723);
  static const brown = Color(0xFF5D4037);
  static const brownMedium = Color(0xFF4E342E);
  static const brownLight = Color(0xFF8D6E63);
  static const tan = Color(0xFFD4A574);
  static const warmGray = Color(0xFFD7CCC8);

  // ── Dark mode surfaces ───────────────────────────────────────────────────
  static const darkBg = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkCard = Color(0xFF2C2C2C);
  static const darkCardAlt = Color(0xFF303030);

  // ── Accents ──────────────────────────────────────────────────────────────
  static const indigo = Color(0xFF5C6BC0);
  static const successGreen = Color(0xFF58CC02);
  static const bulgarianGreen = Color(0xFF00966E);
  static const bulgarianRed = Color(0xFFD62612);
  static const rosePink = Color(0xFFEC407A);
  static const quizGray = Color(0xFF4B4B4B);
  static const errorRed = Color(0xFFFF4B4B);
}
