import 'package:cloud_firestore/cloud_firestore.dart';

/// Immutable model representing a user's score for a specific lesson.
///
/// Stored in Firestore at:
///   `users/{uid}/learning_progress/{topicId}/lessons/{lessonId}`
///
/// Also persisted locally via [ProgressProvider] in SharedPreferences.
class LessonScore {
  final String lessonId;
  final bool completed;
  final int bestScore;
  final int totalQuestions;
  final int attempts;
  final DateTime? lastPlayed;

  const LessonScore({
    required this.lessonId,
    this.completed = false,
    this.bestScore = 0,
    this.totalQuestions = 0,
    this.attempts = 0,
    this.lastPlayed,
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Deserializes from a Firestore document or JSON map.
  factory LessonScore.fromMap(String lessonId, Map<String, dynamic> map) {
    DateTime? lastPlayed;
    final rawDate = map['last_played'];
    if (rawDate is Timestamp) {
      lastPlayed = rawDate.toDate();
    } else if (rawDate is String) {
      lastPlayed = DateTime.tryParse(rawDate);
    }

    return LessonScore(
      lessonId: lessonId,
      completed: map['completed'] as bool? ?? false,
      bestScore: map['best_score'] as int? ?? 0,
      totalQuestions: map['total_questions'] as int? ?? 0,
      attempts: map['attempts'] as int? ?? 0,
      lastPlayed: lastPlayed,
    );
  }

  /// Serializes to a map suitable for Firestore `set(..., merge: true)`.
  Map<String, dynamic> toMap() {
    return {
      'completed': completed,
      'best_score': bestScore,
      'total_questions': totalQuestions,
      'attempts': attempts,
      'last_played': lastPlayed?.toIso8601String(),
    };
  }

  /// Serializes with Firestore server timestamp (for cloud writes).
  Map<String, dynamic> toFirestoreMap() {
    return {
      'completed': completed,
      'best_score': bestScore,
      'total_questions': totalQuestions,
      'attempts': attempts,
      'last_played': FieldValue.serverTimestamp(),
    };
  }

  // ---------------------------------------------------------------------------
  // Transformations
  // ---------------------------------------------------------------------------

  /// Returns a new [LessonScore] recording a new attempt.
  ///
  /// - `bestScore` is updated only if [score] is higher than the current best.
  /// - `attempts` is incremented by 1.
  /// - `completed` is set to `true`.
  /// - `lastPlayed` is set to now.
  LessonScore copyWithNewAttempt(int score, int total) {
    return LessonScore(
      lessonId: lessonId,
      completed: true,
      bestScore: score > bestScore ? score : bestScore,
      totalQuestions: total,
      attempts: attempts + 1,
      lastPlayed: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'LessonScore(lessonId: $lessonId, best: $bestScore/$totalQuestions, '
      'attempts: $attempts, completed: $completed)';
}
