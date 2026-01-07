// File: lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import 'quiz_screen.dart';
import 'alphabet_list_screen.dart';

// --- SCHERMATA 1: LA LISTA DELLE LEZIONI (HOME) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.learningPath),
        centerTitle: true,

        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  themeProvider.toggleTheme(!isDark);
                },
              );
            },
          ),
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
        stream: FirebaseFirestore.instance
            .collection('lezioni')
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final documenti = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: documenti.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: isDark
                      ? null
                      : const Color(
                          0xFFE5F6FD,
                        ), // Light blue only in light mode
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 30,
                      child: const Text(
                        "АБ",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    title: Text(
                      l10n.learningPath == "Learning Path"
                          ? "Bulgarian Alphabet"
                          : "Alfabeto Bulgaro",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    subtitle: Text(
                      l10n.learningPath == "Learning Path"
                          ? "Learn the 30 letters"
                          : "Impara le 30 lettere",
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AlphabetListScreen(),
                        ),
                      );
                    },
                  ),
                );
              }

              final docIndex = index - 1;
              final lezione =
                  documenti[docIndex].data() as Map<String, dynamic>;

              // Recupera il titolo in base alla lingua
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
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l10n.lessonEmpty)));
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
