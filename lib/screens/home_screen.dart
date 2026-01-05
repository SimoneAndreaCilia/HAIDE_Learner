// File: lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_screen.dart'; // Importiamo la pagina del quiz

// --- SCHERMATA 1: LA LISTA DELLE LEZIONI (HOME) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Percorso di Apprendimento"),
        centerTitle: true,
        backgroundColor: const Color(0xFF58CC02),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('lezioni').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final documenti = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: documenti.length,
            itemBuilder: (context, index) {
              final lezione = documenti[index].data() as Map<String, dynamic>;
              final titolo = lezione['titolo'] ?? 'Lezione';
              final listaDomande = List<Map<String, dynamic>>.from(
                lezione['domande'] ?? [],
              );

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    radius: 30,
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  title: Text(
                    titolo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  subtitle: Text("${listaDomande.length} domande"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    if (listaDomande.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizScreen(
                            titoloLezione: titolo,
                            domande: listaDomande,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Questa lezione è vuota!"),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
