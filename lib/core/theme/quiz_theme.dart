import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Bundles all visual customizations for a quiz session.
///
/// Instead of scattering `topicColor`, `heroTag`, and `lessonIcon`
/// across the [QuizScreen] constructor, callers pass a single
/// [QuizTheme] that describes the quiz's visual identity.
///
/// A sensible parchment/gold default is provided via [QuizTheme.defaultTheme].
@immutable
class QuizTheme {
  /// Dominant topic color (used for background gradient, borders, hero badge).
  final Color primary;

  /// Icon shown in the hero badge at the top of the quiz. Nullable.
  final IconData? icon;

  /// Hero animation tag for shared-element transitions. Nullable.
  final String? heroTag;

  const QuizTheme({required this.primary, this.icon, this.heroTag});

  /// Default parchment/gold theme — used by alphabet and unthemed quizzes.
  static const QuizTheme defaultTheme = QuizTheme(primary: AppColors.tan);

  /// Creates a theme from an arena color, icon, and heroTag.
  ///
  /// This is the main factory used by [unit_lessons_screen] callers
  /// that already have a `Color` from [ArenaData].
  const QuizTheme.fromTopic({required this.primary, this.icon, this.heroTag});
}
