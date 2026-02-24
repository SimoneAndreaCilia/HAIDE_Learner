import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/lesson_score.dart';

class ProgressProvider extends ChangeNotifier {
  static const String _storageKeyLegacy = 'completed_lessons';
  static const String _storageKeyV2 = 'completed_lessons_v2';

  /// Maps "unitId_lessonId" → LessonScore.
  Map<String, LessonScore> _lessonScores = {};
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  ProgressProvider() {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // Try V2 format first (JSON map)
    final String? v2Data = prefs.getString(_storageKeyV2);
    if (v2Data != null) {
      _loadFromV2(v2Data);
    } else {
      // Migrate from legacy format (Set<String> of "unitId_lessonId")
      final List<String>? legacy = prefs.getStringList(_storageKeyLegacy);
      if (legacy != null) {
        _migrateFromLegacy(legacy);
        await _saveProgress(); // Persist the migrated data in V2 format
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void _loadFromV2(String jsonData) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonData);
      _lessonScores = decoded.map((key, value) {
        final map = value as Map<String, dynamic>;
        // Extract lessonId from the key (format: "unitId_lessonId")
        final parts = key.split('_');
        final lessonId = parts.length > 1 ? parts.sublist(1).join('_') : key;
        return MapEntry(key, LessonScore.fromMap(lessonId, map));
      });
    } catch (e) {
      debugPrint('Error loading V2 progress: $e');
      _lessonScores = {};
    }
  }

  void _migrateFromLegacy(List<String> legacyKeys) {
    for (final key in legacyKeys) {
      final parts = key.split('_');
      final lessonId = parts.length > 1 ? parts.sublist(1).join('_') : key;
      _lessonScores[key] = LessonScore(
        lessonId: lessonId,
        completed: true,
        // Legacy format has no score data — mark as completed with 0 score
        bestScore: 0,
        totalQuestions: 0,
        attempts: 1,
        lastPlayed: DateTime.now(),
      );
    }
  }

  /// Marks a lesson as completed with optional score data.
  ///
  /// If the lesson was already completed, updates the best score
  /// (only if [score] is higher) and increments the attempt count.
  Future<void> markLessonCompleted(
    String unitId,
    String lessonId, {
    int score = 0,
    int totalQuestions = 0,
  }) async {
    final String key = "${unitId}_$lessonId";
    final existing = _lessonScores[key];

    if (existing != null) {
      // Update existing — use copyWithNewAttempt for best-score logic
      _lessonScores[key] = existing.copyWithNewAttempt(score, totalQuestions);
    } else {
      _lessonScores[key] = LessonScore(
        lessonId: lessonId,
        completed: true,
        bestScore: score,
        totalQuestions: totalQuestions,
        attempts: 1,
        lastPlayed: DateTime.now(),
      );
    }

    await _saveProgress();
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> serialized = _lessonScores.map(
      (key, value) => MapEntry(key, value.toMap()),
    );
    await prefs.setString(_storageKeyV2, jsonEncode(serialized));
  }

  bool isLessonCompleted(String unitId, String lessonId) {
    final key = "${unitId}_$lessonId";
    return _lessonScores[key]?.completed ?? false;
  }

  /// Returns the [LessonScore] for a specific lesson, or `null` if not played.
  LessonScore? getLessonScore(String unitId, String lessonId) {
    return _lessonScores["${unitId}_$lessonId"];
  }

  int getCompletedLessonsCount(String unitId) {
    int count = 0;
    final prefix = "${unitId}_";
    for (var entry in _lessonScores.entries) {
      if (entry.key.startsWith(prefix) && entry.value.completed) {
        count++;
      }
    }
    return count;
  }
}
