import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/models/lesson_score.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==============================================================================
  // 1. LEZIONI & GIOCO (Update Progress, Streak, XP)
  // ==============================================================================

  /// Aggiorna il progresso di una lezione specifica, l'XP e controlla lo Streak.
  /// Chiama questa funzione quando l'utente finisce una lezione.
  ///
  /// If [lessonId], [score] and [totalQuestions] are provided, also writes
  /// a granular per-lesson score to the `lessons/{lessonId}` subcollection.
  Future<void> updateLessonProgress(
    String topicId, {
    String? lessonId,
    int? score,
    int? totalQuestions,
  }) async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        // A. Aggiorniamo lo Streak globale dell'utente (Giorni consecutivi)
        await _updateUserStreak(user.uid);

        // B. Aggiorniamo anche gli XP totali nel documento principale
        // Diamo 10 XP per ogni lezione completata (puoi cambiare il valore)
        await _db.collection('users').doc(user.uid).set({
          'xp': FieldValue.increment(10),
          'last_activity': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // C. Salviamo il dettaglio della lezione specifica (contatore)
        final progressRef = _db
            .collection('users')
            .doc(user.uid)
            .collection('learning_progress')
            .doc(topicId); // es. "alphabet"

        await progressRef.set({
          'completed_lessons': FieldValue.increment(1),
          'last_played': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // D. Score granulare per lezione (subcollection)
        if (lessonId != null && score != null && totalQuestions != null) {
          await _saveGranularScore(
            uid: user.uid,
            topicId: topicId,
            lessonId: lessonId,
            score: score,
            totalQuestions: totalQuestions,
          );
        }

        debugPrint("Progresso, Streak e XP salvati per: $topicId");
      } catch (e) {
        debugPrint("Errore salvataggio progresso Firestore: $e");
      }
    } else {
      debugPrint("Nessun utente loggato.");
    }
  }

  /// Writes or updates a per-lesson score document.
  ///
  /// Only updates `best_score` if the new [score] is higher than the existing
  /// best. Always increments `attempts`.
  Future<void> _saveGranularScore({
    required String uid,
    required String topicId,
    required String lessonId,
    required int score,
    required int totalQuestions,
  }) async {
    final lessonRef = _db
        .collection('users')
        .doc(uid)
        .collection('learning_progress')
        .doc(topicId)
        .collection('lessons')
        .doc(lessonId);

    final existing = await lessonRef.get();

    if (existing.exists) {
      final data = existing.data()!;
      final currentBest = data['best_score'] as int? ?? 0;
      await lessonRef.set({
        'completed': true,
        'best_score': score > currentBest ? score : currentBest,
        'total_questions': totalQuestions,
        'attempts': FieldValue.increment(1),
        'last_played': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await lessonRef.set({
        'completed': true,
        'best_score': score,
        'total_questions': totalQuestions,
        'attempts': 1,
        'last_played': FieldValue.serverTimestamp(),
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 1b. LESSON SCORE READERS
  // ---------------------------------------------------------------------------

  /// Returns the score for a single lesson, or `null` if not yet played.
  Future<LessonScore?> getLessonScore(String topicId, String lessonId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db
        .collection('users')
        .doc(user.uid)
        .collection('learning_progress')
        .doc(topicId)
        .collection('lessons')
        .doc(lessonId)
        .get();

    if (!doc.exists) return null;
    return LessonScore.fromMap(lessonId, doc.data()!);
  }

  /// Streams all per-lesson scores for a topic.
  Stream<List<LessonScore>> getLessonScoresStream(String topicId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('learning_progress')
        .doc(topicId)
        .collection('lessons')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LessonScore.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // 1c. BULK READERS (for hydrate / sync)
  // ---------------------------------------------------------------------------

  /// Returns all topicIds that have progress documents for the current user.
  Future<List<String>> getKnownTopicIds() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('learning_progress')
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// Downloads ALL per-lesson scores across ALL topics for the current user.
  ///
  /// Returns a map of `topicId → List<LessonScore>`.
  /// Used by [ProgressProvider] to hydrate from Firestore on cold start.
  Future<Map<String, List<LessonScore>>> getAllLessonScores() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final Map<String, List<LessonScore>> result = {};

    final topicIds = await getKnownTopicIds();
    for (final topicId in topicIds) {
      final lessonsSnapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('learning_progress')
          .doc(topicId)
          .collection('lessons')
          .get();

      if (lessonsSnapshot.docs.isNotEmpty) {
        result[topicId] = lessonsSnapshot.docs
            .map((doc) => LessonScore.fromMap(doc.id, doc.data()))
            .toList();
      }
    }

    return result;
  }

  // --- LOGICA PRIVATA PER LO STREAK (Giorni consecutivi) ---
  Future<void> _updateUserStreak(String uid) async {
    final userDocRef = _db.collection('users').doc(uid);

    final docSnapshot = await userDocRef.get();
    final data = docSnapshot.data();

    // Data di oggi "pulita" (senza ore/minuti)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int currentStreak = 0;
    DateTime? lastStreakDate;

    // Recupera dati precedenti
    if (data != null) {
      if (data.containsKey('current_streak')) {
        currentStreak = data['current_streak'];
      }
      if (data.containsKey('last_streak_date')) {
        Timestamp ts = data['last_streak_date'];
        DateTime dateFromTs = ts.toDate();
        lastStreakDate = DateTime(
          dateFromTs.year,
          dateFromTs.month,
          dateFromTs.day,
        );
      }
    }

    // Calcolo Logica
    if (lastStreakDate == today) {
      // Ha già fatto esercizio oggi: non cambiare lo streak.
      return;
    } else if (lastStreakDate != null &&
        today.difference(lastStreakDate).inDays == 1) {
      // Ieri ha fatto esercizio: Aumenta lo streak!
      currentStreak++;
    } else {
      // Primo giorno O ha saltato un giorno: Reset a 1.
      currentStreak = 1;
    }

    // Salva i dati aggiornati
    await userDocRef.set({
      'current_streak': currentStreak,
      'last_streak_date': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==============================================================================
  // 2. PROFILO UTENTE (Nome, Avatar, Stream Dati)
  // ==============================================================================

  /// Ascolta i cambiamenti dei dati utente in tempo reale (per Home e Profile).
  Stream<DocumentSnapshot> getUserDataStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _db.collection('users').doc(user.uid).snapshots();
    } else {
      return Stream.empty();
    }
  }

  /// Aggiorna il Nome Utente (Display Name) su Auth e su Firestore.
  Future<void> updateUserName(String newName) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // 1. Aggiorna profilo Firebase Auth (cache locale)
        await user.updateDisplayName(newName);
        await user.reload();

        // 2. Aggiorna database Firestore
        await _db.collection('users').doc(user.uid).set(
          {'username': newName, 'updated_at': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        ); // Usa merge per non sovrascrivere XP o Streak!

        debugPrint("Nome aggiornato con successo: $newName");
      } catch (e) {
        debugPrint("Errore aggiornamento nome: $e");
        rethrow;
      }
    }
  }

  /// Aggiorna l'Avatar selezionato (salva solo una stringa ID o path).
  Future<void> updateUserAvatar(String avatarId) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _db.collection('users').doc(user.uid).set({
          'avatar_id': avatarId, // Es. "goat_1", "bear_2"
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("Avatar aggiornato: $avatarId");
      } catch (e) {
        debugPrint("Errore aggiornamento avatar: $e");
      }
    }
  }

  /// (Opzionale) Ottieni i dati utente una volta sola (senza stream)
  Future<Map<String, dynamic>?> getUserDataOnce() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.data();
    }
    return null;
  }
}
