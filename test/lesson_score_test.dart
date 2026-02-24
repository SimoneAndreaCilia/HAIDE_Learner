import 'package:flutter_test/flutter_test.dart';
import 'package:haide/core/models/lesson_score.dart';

void main() {
  group('LessonScore constructor', () {
    test('creates instance with defaults', () {
      const score = LessonScore(lessonId: 'lesson_1');

      expect(score.lessonId, 'lesson_1');
      expect(score.completed, false);
      expect(score.bestScore, 0);
      expect(score.totalQuestions, 0);
      expect(score.attempts, 0);
      expect(score.lastPlayed, null);
    });

    test('creates instance with all fields', () {
      final now = DateTime(2026, 2, 24, 12, 0);
      final score = LessonScore(
        lessonId: 'lesson_2',
        completed: true,
        bestScore: 8,
        totalQuestions: 10,
        attempts: 3,
        lastPlayed: now,
      );

      expect(score.completed, true);
      expect(score.bestScore, 8);
      expect(score.totalQuestions, 10);
      expect(score.attempts, 3);
      expect(score.lastPlayed, now);
    });
  });

  group('fromMap', () {
    test('deserializes complete map', () {
      final score = LessonScore.fromMap('lesson_1', {
        'completed': true,
        'best_score': 7,
        'total_questions': 10,
        'attempts': 2,
        'last_played': '2026-02-24T12:00:00.000',
      });

      expect(score.lessonId, 'lesson_1');
      expect(score.completed, true);
      expect(score.bestScore, 7);
      expect(score.totalQuestions, 10);
      expect(score.attempts, 2);
      expect(score.lastPlayed, isNotNull);
    });

    test('handles partial map with defaults', () {
      final score = LessonScore.fromMap('lesson_2', {'completed': true});

      expect(score.lessonId, 'lesson_2');
      expect(score.completed, true);
      expect(score.bestScore, 0);
      expect(score.totalQuestions, 0);
      expect(score.attempts, 0);
      expect(score.lastPlayed, null);
    });

    test('handles empty map', () {
      final score = LessonScore.fromMap('lesson_3', {});

      expect(score.lessonId, 'lesson_3');
      expect(score.completed, false);
      expect(score.bestScore, 0);
    });

    test('handles ISO date string for last_played', () {
      final score = LessonScore.fromMap('lesson_4', {
        'last_played': '2026-01-15T10:30:00.000Z',
      });

      expect(score.lastPlayed, isNotNull);
      expect(score.lastPlayed!.year, 2026);
      expect(score.lastPlayed!.month, 1);
    });
  });

  group('toMap', () {
    test('serializes all fields', () {
      final now = DateTime(2026, 2, 24, 12, 0);
      final score = LessonScore(
        lessonId: 'lesson_1',
        completed: true,
        bestScore: 8,
        totalQuestions: 10,
        attempts: 3,
        lastPlayed: now,
      );

      final map = score.toMap();

      expect(map['completed'], true);
      expect(map['best_score'], 8);
      expect(map['total_questions'], 10);
      expect(map['attempts'], 3);
      expect(map['last_played'], now.toIso8601String());
    });

    test('roundtrip fromMap → toMap → fromMap', () {
      final original = LessonScore(
        lessonId: 'roundtrip',
        completed: true,
        bestScore: 5,
        totalQuestions: 8,
        attempts: 2,
        lastPlayed: DateTime(2026, 3, 1),
      );

      final map = original.toMap();
      final restored = LessonScore.fromMap('roundtrip', map);

      expect(restored.lessonId, original.lessonId);
      expect(restored.completed, original.completed);
      expect(restored.bestScore, original.bestScore);
      expect(restored.totalQuestions, original.totalQuestions);
      expect(restored.attempts, original.attempts);
      expect(restored.lastPlayed, original.lastPlayed);
    });
  });

  group('copyWithNewAttempt', () {
    test('updates best score when new score is higher', () {
      const original = LessonScore(
        lessonId: 'lesson_1',
        completed: true,
        bestScore: 5,
        totalQuestions: 10,
        attempts: 1,
      );

      final updated = original.copyWithNewAttempt(8, 10);

      expect(updated.bestScore, 8);
      expect(updated.totalQuestions, 10);
      expect(updated.attempts, 2);
      expect(updated.completed, true);
      expect(updated.lastPlayed, isNotNull);
    });

    test('keeps best score when new score is lower', () {
      const original = LessonScore(
        lessonId: 'lesson_1',
        completed: true,
        bestScore: 8,
        totalQuestions: 10,
        attempts: 2,
      );

      final updated = original.copyWithNewAttempt(3, 10);

      expect(updated.bestScore, 8); // unchanged
      expect(updated.attempts, 3); // incremented
    });

    test('keeps best score when new score is equal', () {
      const original = LessonScore(
        lessonId: 'lesson_1',
        completed: true,
        bestScore: 5,
        totalQuestions: 10,
        attempts: 1,
      );

      final updated = original.copyWithNewAttempt(5, 10);

      expect(updated.bestScore, 5); // unchanged
      expect(updated.attempts, 2);
    });

    test('sets completed to true for first attempt', () {
      const original = LessonScore(
        lessonId: 'lesson_1',
        completed: false,
        bestScore: 0,
        totalQuestions: 0,
        attempts: 0,
      );

      final updated = original.copyWithNewAttempt(7, 10);

      expect(updated.completed, true);
      expect(updated.bestScore, 7);
      expect(updated.attempts, 1);
    });

    test('does not modify original instance', () {
      const original = LessonScore(
        lessonId: 'lesson_1',
        completed: true,
        bestScore: 5,
        totalQuestions: 10,
        attempts: 1,
      );

      original.copyWithNewAttempt(10, 10);

      // Original should be unchanged
      expect(original.bestScore, 5);
      expect(original.attempts, 1);
    });
  });

  group('toString', () {
    test('produces readable output', () {
      const score = LessonScore(
        lessonId: 'lesson_1',
        completed: true,
        bestScore: 8,
        totalQuestions: 10,
        attempts: 3,
      );

      final str = score.toString();
      expect(str, contains('lesson_1'));
      expect(str, contains('8/10'));
      expect(str, contains('attempts: 3'));
    });
  });
}
