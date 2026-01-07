import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/generated/app_localizations.dart';
import 'quiz_screen.dart';

class UnitLessonsScreen extends StatelessWidget {
  final String unitId;
  final String title;
  final String description;

  const UnitLessonsScreen({
    super.key,
    required this.unitId,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .doc(unitId)
            .collection('lessons')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data!.docs;

          if (documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.lessonEmpty, // Reusing existing string or "No lessons found"
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final lessonData =
                  documents[index].data() as Map<String, dynamic>;

              // Determine title based on language
              String lessonTitle = lessonData['title'] ?? 'Lesson';
              if (isEnglish && lessonData['title_en'] != null) {
                lessonTitle = lessonData['title_en'];
              }

              // Determine description based on language
              String lessonDesc = lessonData['description'] ?? '';
              if (isEnglish && lessonData['description_en'] != null) {
                lessonDesc = lessonData['description_en'];
              }

              final questions = List<Map<String, dynamic>>.from(
                lessonData['questions'] ?? [],
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
                    backgroundColor: Colors.teal,
                    radius: 30,
                    child:
                        (lessonTitle.contains('Saluti') ||
                            lessonTitle.contains('Greetings'))
                        ? const Icon(
                            Icons.waving_hand,
                            color: Colors.white,
                            size: 30,
                          )
                        : (lessonTitle.contains('Cortesia') ||
                              lessonTitle.contains('Cortesy') ||
                              lessonTitle.contains('Courtesy'))
                        ? const Icon(
                            Icons.handshake,
                            color: Colors.white,
                            size: 30,
                          )
                        : Text(
                            "${index + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                  ),
                  title: Text(
                    lessonTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lessonDesc.isNotEmpty) ...[
                        Text(lessonDesc),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        l10n.questionsCount(questions.length),
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    if (questions.isNotEmpty) {
                      // Extract tips if available
                      final tips = lessonData['tips'] != null
                          ? List<Map<String, dynamic>>.from(lessonData['tips'])
                          : null;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizScreen(
                            titoloLezione: lessonTitle,
                            domande: questions,
                            tips: tips,
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
