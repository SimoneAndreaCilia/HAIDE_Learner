import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // Helper to get the correct scroll image based on the lesson title
  String _getScrollImage(String titleEn, String titleIt) {
    final tEn = titleEn.toLowerCase();

    if (tEn.contains('friendly')) {
      return 'assets/images/card_friendlyletters.png';
    } else if (tEn.contains('false')) {
      return 'assets/images/card_falsefriends.png';
    } else if (tEn.contains('familiar')) {
      return 'assets/images/card_familiarsounds.png';
    } else if (tEn.contains('complex')) {
      return 'assets/images/card_complexsounds.png';
    } else if (tEn.contains('quiz')) {
      return 'assets/images/card_quizfinale.png';
    }
    // Default fallback
    return 'assets/images/card_quizfinale.png';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      extendBodyBehindAppBar: true, // Allows body to go behind AppBar
      appBar: AppBar(
        title: Text(
          isEnglish ? 'Alphabet Arena' : 'Arena Alfabeto',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            fontSize: 28,
            color: const Color(0xFFFFD700), // Gold
            shadows: [
              const Shadow(
                offset: Offset(0, 2),
                blurRadius: 3.0,
                color: Colors.black,
              ),
              const Shadow(
                // Outline effect
                offset: Offset(-1, -1),
                blurRadius: 0,
                color: Color(0xFF3E2723),
              ),
              const Shadow(
                // Outline effect
                offset: Offset(1, 1),
                blurRadius: 0,
                color: Color(0xFF3E2723),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.white),
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
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_alphabet.png',
              fit: BoxFit.cover,
            ),
          ),

          // Content
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('alphabet_lessons')
                .orderBy('order')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    l10n.lessonEmpty,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  100,
                  20,
                  20,
                ), // Top padding for AppBar
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final lessonId = docs[index].id;

                  // Titles
                  final titleEn =
                      data['title_en'] as String? ??
                      data['title'] as String? ??
                      'Lesson ${index + 1}';
                  final titleIt = data['title'] as String? ?? 'Lezione';
                  final displayTitle = isEnglish ? titleEn : titleIt;

                  String description = data['description'] ?? '';
                  if (isEnglish && data['description_en'] != null) {
                    description = data['description_en'];
                  }

                  final letters = data['letters'] as List<dynamic>? ?? [];
                  final totalLetters = letters.length;

                  // Determine background image based on English title keywords
                  final bgImage = _getScrollImage(titleEn, titleIt);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF1A237E,
                                ).withValues(alpha: 0.5),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              bgImage,
                              fit: BoxFit.fitWidth,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                final rawQuiz = data['quiz'] as List<dynamic>?;

                                final quizData =
                                    rawQuiz
                                        ?.map(
                                          (e) => Map<String, dynamic>.from(
                                            e as Map,
                                          ),
                                        )
                                        .toList() ??
                                    [];

                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AlphabetLessonScreen(
                                      title: displayTitle,
                                      letters: letters
                                          .cast<Map<String, dynamic>>(),
                                      quiz: quizData,
                                      allLessons: docs
                                          .map(
                                            (d) =>
                                                d.data()
                                                    as Map<String, dynamic>,
                                          )
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
                                padding: const EdgeInsets.fromLTRB(
                                  140,
                                  20,
                                  50,
                                  20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Title with "Ink" effect
                                    Text(
                                      displayTitle,
                                      style: GoogleFonts.medievalSharp(
                                        // Fantasy style
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(
                                          0xFF3E2723,
                                        ), // Ink color
                                        shadows: [
                                          Shadow(
                                            blurRadius: 1.0,
                                            color: Colors.grey.withValues(
                                              alpha: 0.5,
                                            ),
                                            offset: const Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        description,
                                        style: GoogleFonts.crimsonText(
                                          // "Handwritten" serif
                                          color: const Color(0xFF4E342E),
                                          fontSize:
                                              15, // Slightly larger as it's a smaller font visually
                                          fontWeight: FontWeight.w600,
                                          height: 1.0,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 0.5,
                                              color: Colors.grey.withValues(
                                                alpha: 0.4,
                                              ),
                                              offset: const Offset(0.5, 0.5),
                                            ),
                                          ],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (totalLetters > 0) ...[
                                      const SizedBox(height: 1),
                                      FutureBuilder<int>(
                                        future: SharedPreferences.getInstance()
                                            .then(
                                              (prefs) =>
                                                  prefs.getInt(
                                                    'progress_$lessonId',
                                                  ) ??
                                                  0,
                                            ),
                                        builder: (context, snapshot) {
                                          final currentProgress =
                                              snapshot.data ?? 0;
                                          final percent =
                                              (currentProgress / totalLetters)
                                                  .clamp(0.0, 1.0);
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: LinearPercentIndicator(
                                                    lineHeight: 8.0,
                                                    percent: percent,
                                                    progressColor: const Color(
                                                      0xFF00966E,
                                                    ), // Bulgaria Green
                                                    backgroundColor: const Color(
                                                      0xFFD7CCC8,
                                                    ), // Light parchment color
                                                    barRadius:
                                                        const Radius.circular(
                                                          5,
                                                        ),
                                                    padding: EdgeInsets.zero,
                                                    animation: true,
                                                    animateFromLastPercent:
                                                        true,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              // Golden Badge for count
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          Color(0xFFFFD700),
                                                          Color(0xFFFFA000),
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  '$currentProgress/$totalLetters',
                                                  style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w900,
                                                    color: const Color(
                                                      0xFF3E2723,
                                                    ),
                                                    fontSize: 11,
                                                  ),
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
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
