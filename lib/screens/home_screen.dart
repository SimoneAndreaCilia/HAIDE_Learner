// File: lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/language_provider.dart';
import 'quiz_screen.dart';

// --- SCHERMATA 1: LA LISTA DELLE LEZIONI (HOME) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.learningPath),
        centerTitle: true,
        backgroundColor: const Color(0xFF58CC02),
        foregroundColor: Colors.white,
        actions: [
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return PopupMenuButton<Locale>(
                icon: const Icon(Icons.language),
                onSelected: (Locale locale) {
                  languageProvider.changeLanguage(locale);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
                  const PopupMenuItem<Locale>(
                    value: Locale('it'),
                    child: Text('Italiano'),
                  ),
                  const PopupMenuItem<Locale>(
                    value: Locale('en'),
                    child: Text('English'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('lezioni').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final documenti = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: documenti.length,
            itemBuilder: (context, index) {
              final lezione = documenti[index].data() as Map<String, dynamic>;
              
              // Recupera il titolo in base alla lingua
              final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
              final isEnglish = languageProvider.currentLocale.languageCode == 'en';
              String titolo = lezione['titolo'] ?? 'Lezione';
              if (isEnglish && lezione['titolo_en'] != null) {
                titolo = lezione['titolo_en'];
              }

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
                  subtitle: Text(l10n.questionsCount(listaDomande.length)),
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
                        SnackBar(
                          content: Text(l10n.lessonEmpty),
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
