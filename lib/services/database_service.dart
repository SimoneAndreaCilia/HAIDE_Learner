import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  // Funzione per aggiornare il progresso
  Future<void> updateLessonProgress(String topicId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Riferimento: users -> UID -> learning_progress -> topicId
        final progressRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('learning_progress')
            .doc(topicId); // es. "alphabet"

        // Aggiorna o Crea il documento
        await progressRef.set({
          'completed_lessons': FieldValue.increment(1), // Aumenta di 1
          'last_played': FieldValue.serverTimestamp(),
          // Se vuoi impostare "completato" quando arriva al massimo, lo faremo dopo
        }, SetOptions(merge: true)); // merge: true è importante!

        debugPrint("Progresso salvato per: $topicId su Firestore");
      } catch (e) {
        debugPrint("Errore salvataggio progresso Firestore: $e");
      }
    } else {
      debugPrint("Nessun utente loggato, impossibile salvare su Firestore");
    }
  }
}
