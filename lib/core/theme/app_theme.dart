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

  // ── Landscape / Sky colors (light mode) ──────────────────────────────────
  static const skyHigh = Color(0xFF29B6F6);
  static const skyMid = Color(0xFF4FC3F7);
  static const skyLow = Color(0xFF81D4FA);
  static const skyPale = Color(0xFFB3E5FC);
  static const grassDark = Color(0xFF388E3C);
  static const grassLight = Color(0xFF66BB6A);
  static const grassPale = Color(0xFF81C784);
  static const hillDark = Color(0xFF4CAF50);
  static const hillLight = Color(0xFFA5D6A7);
  static const hillPale = Color(0xFFC8E6C9);
  static const earthDark = Color(0xFF5D4037);
  static const earthLight = Color(0xFF8D6E63);
  static const earthPale = Color(0xFFA1887F);

  // ── Night sky / dark mode landscape ──────────────────────────────────────
  static const nightSkyDeep = Color(0xFF0D1B2A);
  static const nightSkyMid = Color(0xFF1B2838);
  static const nightSkyLow = Color(0xFF1A237E);
  static const nightGrassDark = Color(0xFF1B5E20);
  static const nightGrassLight = Color(0xFF2E7D32);
  static const nightHill = Color(0xFF2E7D32);
  static const nightEarth = Color(0xFF3E2723);
  static const starWhite = Color(0xFFF5F5F5);

  // ── Bulgarian accent colors (for decorations) ────────────────────────────
  static const bulgarianWhite = Color(0xFFF5F5F5);
  static const roseRed = Color(0xFFE91E63);
  static const rosePinkLight = Color(0xFFF48FB1);
  static const rosePinkDark = Color(0xFFC2185B);
  static const flowerYellow = Color(0xFFFFEB3B);
  static const flowerWhite = Color(0xFFFFF9C4);
}
