import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/generated/app_localizations.dart';
import 'alphabet_lesson_screen.dart';

class AlphabetListScreen extends StatefulWidget {
  const AlphabetListScreen({super.key});

  @override
  State<AlphabetListScreen> createState() => _AlphabetListScreenState();
}

class _AlphabetListScreenState extends State<AlphabetListScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Alphabet' : 'Alfabeto'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            onSelected: (value) {
              if (value == 'reset') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      isEnglish ? 'Reset Progress' : 'Resetta Progressi',
                    ),
                    content: Text(
                      isEnglish
                          ? 'Are you sure you want to reset all progress?'
                          : 'Sei sicuro di voler resettare tutti i progressi?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(isEnglish ? 'Cancel' : 'Annulla'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final keys = prefs.getKeys();
                          for (final key in keys) {
                            if (key.startsWith('progress_')) {
                              await prefs.remove(key);
                            }
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                            setState(() {});
                          }
                        },
                        child: Text(
                          isEnglish ? 'Reset' : 'Resetta',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'reset',
                child: Row(
                  children: [
                    const Icon(Icons.refresh, color: Colors.red),
                    const SizedBox(width: 10),
                    Text(isEnglish ? 'Reset Progress' : 'Resetta Progressi'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alphabet_lessons')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text(l10n.lessonEmpty));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final lessonId = docs[index].id;

              String title = data['title'] ?? 'Lesson ${index + 1}';
              if (isEnglish && data['title_en'] != null) {
                title = data['title_en'];
              }

              String description = data['description'] ?? '';
              if (isEnglish && data['description_en'] != null) {
                description = data['description_en'];
              }

              final letters = data['letters'] as List<dynamic>? ?? [];
              final totalLetters = letters.length;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  onTap: () async {
                    final rawQuiz = data['quiz'] as List<dynamic>?;

                    final quizData =
                        rawQuiz
                            ?.map((e) => Map<String, dynamic>.from(e as Map))
                            .toList() ??
                        [];

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlphabetLessonScreen(
                          title: title,
                          letters: letters.cast<Map<String, dynamic>>(),
                          quiz: quizData,
                          allLessons: docs
                              .map((d) => d.data() as Map<String, dynamic>)
                              .toList(),
                          currentIndex: index,
                          lessonId: lessonId,
                        ),
                      ),
                    );
                    // Refresh progress bars
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                        if (totalLetters > 0) ...[
                          const SizedBox(height: 15),
                          FutureBuilder<int>(
                            future: SharedPreferences.getInstance().then(
                              (prefs) =>
                                  prefs.getInt('progress_$lessonId') ?? 0,
                            ),
                            builder: (context, snapshot) {
                              final currentProgress = snapshot.data ?? 0;
                              final percent = (currentProgress / totalLetters)
                                  .clamp(0.0, 1.0);
                              return Row(
                                children: [
                                  Expanded(
                                    child: LinearPercentIndicator(
                                      lineHeight: 10.0,
                                      percent: percent,
                                      progressColor: Colors.blueAccent,
                                      backgroundColor: Colors.grey[300],
                                      barRadius: const Radius.circular(5),
                                      animation: true,
                                      animateFromLastPercent: true,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    '$currentProgress/$totalLetters',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
