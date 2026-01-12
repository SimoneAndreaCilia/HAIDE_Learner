import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==============================================================================
  // 1. LEZIONI & GIOCO (Update Progress, Streak, XP)
  // ==============================================================================

  /// Aggiorna il progresso di una lezione specifica, l'XP e controlla lo Streak.
  /// Chiama questa funzione quando l'utente finisce una lezione.
  Future<void> updateLessonProgress(String topicId) async {
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

        // C. Salviamo il dettaglio della lezione specifica
        final progressRef = _db
            .collection('users')
            .doc(user.uid)
            .collection('learning_progress')
            .doc(topicId); // es. "alphabet"

        await progressRef.set({
          'completed_lessons': FieldValue.increment(1),
          'last_played': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint("Progresso, Streak e XP salvati per: $topicId");
      } catch (e) {
        debugPrint("Errore salvataggio progresso Firestore: $e");
      }
    } else {
      debugPrint("Nessun utente loggato.");
    }
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
