import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/lesson_score.dart';
import '../services/database_service.dart';

/// Unified progress provider — single source of truth for lesson progress.
///
/// **Offline-first pattern:**
/// 1. On cold start: loads from SharedPreferences instantly, then hydrates
///    from Firestore in the background.
/// 2. On write: saves to SharedPreferences immediately, then syncs to
///    Firestore asynchronously (fire-and-forget).
/// 3. Merge conflicts: the higher `bestScore` wins.
class ProgressProvider extends ChangeNotifier {
  static const String _storageKeyLegacy = 'completed_lessons';
  static const String _storageKeyV2 = 'completed_lessons_v2';

  final DatabaseService _dbService;

  /// Maps "unitId_lessonId" → LessonScore.
  Map<String, LessonScore> _lessonScores = {};
  bool _isLoading = true;
  bool _isHydrating = false;

  bool get isLoading => _isLoading;
  bool get isHydrating => _isHydrating;

  ProgressProvider({DatabaseService? dbService})
    : _dbService = dbService ?? DatabaseService() {
    _loadProgress();
  }

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  Future<void> _loadProgress() async {
    // 1. Load local data (instant, offline-first)
    await _loadFromLocal();
    _isLoading = false;
    notifyListeners(); // UI ready immediately with local data

    // 2. Hydrate from Firestore (async, in background)
    await _hydrateFromFirestore();
  }

  Future<void> _loadFromLocal() async {
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
        await _saveToLocal();
      }
    }
  }

  void _loadFromV2(String jsonData) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonData);
      _lessonScores = decoded.map((key, value) {
        final map = value as Map<String, dynamic>;
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
        bestScore: 0,
        totalQuestions: 0,
        attempts: 1,
        lastPlayed: DateTime.now(),
      );
    }
  }

  // ===========================================================================
  // HYDRATE FROM FIRESTORE
  // ===========================================================================

  /// Downloads all progress from Firestore and merges with local data.
  ///
  /// Merge strategy: for each lesson, the higher `bestScore` wins.
  /// Local-only data is pushed to Firestore. Firestore-only data is pulled locally.
  Future<void> _hydrateFromFirestore() async {
    try {
      _isHydrating = true;

      final cloudData = await _dbService.getAllLessonScores();
      if (cloudData.isEmpty && _lessonScores.isEmpty) {
        _isHydrating = false;
        return;
      }

      bool localChanged = false;

      // 1. Pull Firestore data into local (Firestore → Local)
      for (final entry in cloudData.entries) {
        final topicId = entry.key;
        for (final cloudScore in entry.value) {
          final key = "${topicId}_${cloudScore.lessonId}";
          final localScore = _lessonScores[key];

          if (localScore == null) {
            // Firestore-only: pull to local
            _lessonScores[key] = cloudScore;
            localChanged = true;
          } else {
            // Both exist: merge — higher bestScore wins
            final merged = _merge(localScore, cloudScore);
            if (merged != localScore) {
              _lessonScores[key] = merged;
              localChanged = true;
            }
          }
        }
      }

      // 2. Push local-only data to Firestore (Local → Firestore)
      final cloudKeys = <String>{};
      for (final entry in cloudData.entries) {
        for (final score in entry.value) {
          cloudKeys.add("${entry.key}_${score.lessonId}");
        }
      }

      for (final entry in _lessonScores.entries) {
        if (!cloudKeys.contains(entry.key)) {
          // Local-only: push to Firestore
          final parts = entry.key.split('_');
          if (parts.length >= 2) {
            final topicId = parts[0];
            final lessonId = parts.sublist(1).join('_');
            _syncSingleToFirestore(
              topicId,
              lessonId,
              entry.value.bestScore,
              entry.value.totalQuestions,
            );
          }
        }
      }

      if (localChanged) {
        await _saveToLocal();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Hydrate from Firestore failed (offline?): $e');
    } finally {
      _isHydrating = false;
    }
  }

  /// Merges two LessonScore entries — higher bestScore wins.
  LessonScore _merge(LessonScore local, LessonScore cloud) {
    if (cloud.bestScore > local.bestScore) {
      return cloud;
    } else if (local.bestScore > cloud.bestScore) {
      return local;
    }
    // Equal scores: keep the one with more attempts (more data)
    return cloud.attempts >= local.attempts ? cloud : local;
  }

  // ===========================================================================
  // UNIFIED WRITE (local + cloud in one call)
  // ===========================================================================

  /// Marks a lesson as completed with optional score data.
  ///
  /// Writes to SharedPreferences immediately, then syncs to Firestore async.
  /// Callers no longer need to call [DatabaseService] separately.
  Future<void> markLessonCompleted(
    String unitId,
    String lessonId, {
    int score = 0,
    int totalQuestions = 0,
  }) async {
    final String key = "${unitId}_$lessonId";
    final existing = _lessonScores[key];

    if (existing != null) {
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

    // 1. Save locally (instant)
    await _saveToLocal();
    notifyListeners();

    // 2. Sync to Firestore (async, fire-and-forget)
    _syncToFirestore(unitId, lessonId, score, totalQuestions);
  }

  // ===========================================================================
  // LOCAL PERSISTENCE
  // ===========================================================================

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> serialized = _lessonScores.map(
      (key, value) => MapEntry(key, value.toMap()),
    );
    await prefs.setString(_storageKeyV2, jsonEncode(serialized));
  }

  // ===========================================================================
  // FIRESTORE SYNC
  // ===========================================================================

  /// Syncs a lesson completion to Firestore. Errors are caught silently
  /// (offline-first: local state is always authoritative).
  void _syncToFirestore(
    String unitId,
    String lessonId,
    int score,
    int totalQuestions,
  ) {
    _dbService
        .updateLessonProgress(
          unitId,
          lessonId: lessonId,
          score: score,
          totalQuestions: totalQuestions,
        )
        .catchError((e) {
          debugPrint('Firestore sync failed (will retry on next hydrate): $e');
        });
  }

  /// Pushes a single local-only entry to Firestore.
  void _syncSingleToFirestore(
    String topicId,
    String lessonId,
    int score,
    int totalQuestions,
  ) {
    _dbService
        .updateLessonProgress(
          topicId,
          lessonId: lessonId,
          score: score,
          totalQuestions: totalQuestions,
        )
        .catchError((e) {
          debugPrint('Firestore push failed for $topicId/$lessonId: $e');
        });
  }

  // ===========================================================================
  // READERS
  // ===========================================================================

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
