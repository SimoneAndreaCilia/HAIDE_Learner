import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressProvider extends ChangeNotifier {
  static const String _storageKey = 'completed_lessons';

  // Set of formatted strings: "unitId_lessonId"
  Set<String> _completedLessons = {};
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  ProgressProvider() {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_storageKey);
    if (stored != null) {
      _completedLessons = stored.toSet();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markLessonCompleted(String unitId, String lessonId) async {
    final String key = "${unitId}_$lessonId";
    if (!_completedLessons.contains(key)) {
      _completedLessons.add(key);
      await _saveProgress();
      notifyListeners();
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _completedLessons.toList());
  }

  bool isLessonCompleted(String unitId, String lessonId) {
    return _completedLessons.contains("${unitId}_$lessonId");
  }

  int getCompletedLessonsCount(String unitId) {
    // Count keys that start with "unitId_"
    // Note: If unitId contains underscores, ensure uniqueness.
    // Usually unit IDs are distinct enough.
    int count = 0;
    final prefix = "${unitId}_";
    for (var key in _completedLessons) {
      if (key.startsWith(prefix)) {
        count++;
      }
    }
    return count;
  }
}
