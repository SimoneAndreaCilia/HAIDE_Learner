import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/generated/app_localizations.dart';
import 'quiz_screen.dart';

class AlphabetLessonScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> letters;
  final List<Map<String, dynamic>> allLessons;
  final int currentIndex;
  final List<Map<String, dynamic>>? quiz;
  final String lessonId;

  const AlphabetLessonScreen({
    super.key,
    required this.title,
    required this.letters,
    this.allLessons = const [],
    this.currentIndex = -1,
    this.quiz,
    this.lessonId = '',
  });

  @override
  State<AlphabetLessonScreen> createState() => _AlphabetLessonScreenState();
}

class _AlphabetLessonScreenState extends State<AlphabetLessonScreen> {
  final PageController _pageController = PageController();
  final FlutterTts flutterTts = FlutterTts();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await flutterTts.setLanguage("bg-BG");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.8);
  }

  void _startQuiz() async {
    // If we have a pre-defined quiz, use it
    if (widget.quiz != null && widget.quiz!.isNotEmpty) {
      final questions = widget.quiz!.map((q) {
        // Helper per gestire tipi dynamic in modo sicuro
        String safeStr(dynamic val) => val?.toString() ?? '';
        List<String> safeList(dynamic val) {
          if (val is List) {
            return val.map((e) => e.toString()).toList();
          }
          return [];
        }

        return {
          'domanda': safeStr(q['question_it']).isNotEmpty
              ? safeStr(q['question_it'])
              : 'Come si dice?',
          'domanda_en': q['question_en'], // Lasciamo raw per QuizScreen
          'question_it': q['question_it'],
          'question_en': q['question_en'],
          'bulgaro': safeStr(q['bulgarian_text']),
          'pronuncia': safeStr(q['audio_text']),
          'opzioni': safeList(q['options']),
          'soluzione': safeStr(q['correct_answer']),
          'italiano': safeStr(q['correct_answer']),
          'inglese': safeStr(q['correct_answer']),
          'type': safeStr(q['type']), // Pass type (text/audio)
        };
      }).toList();

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            titoloLezione: '${widget.title} Quiz',
            domande: questions,
            isCustomQuiz: true,
          ),
        ),
      );

      if (result == true && mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    // Fallback to auto-generated quiz if no specific quiz data is provided
    final questions = <Map<String, dynamic>>[];
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final random = Random();

    for (var letter in widget.letters) {
      final correctSound = isEnglish
          ? (letter['transliteration_en'] ?? letter['transliteration'])
          : letter['transliteration'];
      if (correctSound == null) continue;

      final otherLetters = widget.letters.where((l) => l != letter).toList();
      otherLetters.shuffle(random);

      final wrong1 = otherLetters.isNotEmpty
          ? (isEnglish
                ? (otherLetters[0]['transliteration_en'] ??
                      otherLetters[0]['transliteration'])
                : otherLetters[0]['transliteration'])
          : 'X';
      final wrong2 = otherLetters.length > 1
          ? (isEnglish
                ? (otherLetters[1]['transliteration_en'] ??
                      otherLetters[1]['transliteration'])
                : otherLetters[1]['transliteration'])
          : 'Y';

      final options = [correctSound, wrong1, wrong2];
      options.shuffle(random);

      questions.add({
        'domanda': isEnglish ? 'What sound is this?' : 'Che suono è?',
        'bulgaro': letter['character'],
        'opzioni': options,
        'soluzione': correctSound,
        'pronuncia': '',
        'italiano': correctSound, // Fallback for QuizScreen logic
        'inglese': correctSound, // Fallback for QuizScreen logic
        'type': 'text',
      });
    }

    // Add audio recognition questions if examples exist
    for (var letter in widget.letters) {
      final example = letter['example']; // Word like "MAMA"
      if (example != null && example.isNotEmpty) {
        final options = [example];
        // Add 2 wrong words from other letters
        final otherLetters = widget.letters
            .where((l) => l != letter && l['example'] != null)
            .toList();
        otherLetters.shuffle(random);
        if (otherLetters.isNotEmpty) options.add(otherLetters[0]['example']);
        if (otherLetters.length > 1) options.add(otherLetters[1]['example']);

        if (options.length > 1) {
          // Only if we have options
          options.shuffle(random);
          questions.add({
            'domanda': isEnglish
                ? 'Listen and choose the word'
                : 'Ascolta e scegli la parola',
            'bulgaro': '', // No text displayed, just audio
            'pronuncia': example, // TTS reads this
            'opzioni': options,
            'soluzione': example,
            'italiano': example,
            'inglese': example,
            'type': 'audio',
          });
        }
      }
    }

    if (questions.isEmpty) return;

    questions.shuffle(random);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          titoloLezione: '${widget.title} Quiz',
          domande: questions,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final totalPages = widget.letters.length + 1;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: totalPages,
              onPageChanged: (idx) async {
                setState(() {
                  _currentPage = idx;
                });

                // Persist progress
                if (widget.lessonId.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  final key = 'progress_${widget.lessonId}';
                  final currentMax = prefs.getInt(key) ?? 0;
                  if (idx > currentMax) {
                    await prefs.setInt(key, idx);
                  }
                  // If completed (last page is the completion card)
                  if (idx == widget.letters.length) {
                    await prefs.setInt(key, widget.letters.length);
                  }
                }
              },
              itemBuilder: (context, index) {
                if (index == widget.letters.length) {
                  final hasNextLesson =
                      widget.currentIndex != -1 &&
                      widget.currentIndex + 1 < widget.allLessons.length;

                  return Center(
                    child: Card(
                      margin: const EdgeInsets.all(30),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasNextLesson ? Icons.check_circle : Icons.school,
                              size: 80,
                              color: hasNextLesson
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(height: 30),
                            Text(
                              isEnglish
                                  ? (hasNextLesson
                                        ? "Lesson Completed!"
                                        : "All Lessons Completed!")
                                  : (hasNextLesson
                                        ? "Lezione Completata!"
                                        : "Hai finito tutte le lezioni!"),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              isEnglish
                                  ? (hasNextLesson
                                        ? "Ready for the next one?"
                                        : "Test your knowledge with a quiz.")
                                  : (hasNextLesson
                                        ? "Passa all'altra lezione"
                                        : "Mettiti alla prova con un quiz."),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 40),
                            if (hasNextLesson) ...[
                              ElevatedButton.icon(
                                onPressed: () {
                                  final nextIndex = widget.currentIndex + 1;
                                  final nextLessonData =
                                      widget.allLessons[nextIndex];

                                  String nextTitle =
                                      nextLessonData['title'] ?? 'Lesson';
                                  if (isEnglish &&
                                      nextLessonData['title_en'] != null) {
                                    nextTitle = nextLessonData['title_en'];
                                  }

                                  final nextLetters =
                                      (nextLessonData['letters']
                                                  as List<dynamic>? ??
                                              [])
                                          .cast<Map<String, dynamic>>();

                                  final rawNextQuiz =
                                      nextLessonData['quiz'] as List<dynamic>?;

                                  final nextQuiz =
                                      rawNextQuiz
                                          ?.map(
                                            (e) => Map<String, dynamic>.from(
                                              e as Map,
                                            ),
                                          )
                                          .toList() ??
                                      [];

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AlphabetLessonScreen(
                                        title: nextTitle,
                                        letters: nextLetters,
                                        quiz: nextQuiz,
                                        allLessons: widget.allLessons,
                                        currentIndex: nextIndex,
                                        lessonId:
                                            nextLessonData['title'] ??
                                            '', // Simple ID for now
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward),
                                label: Text(
                                  isEnglish
                                      ? "Next Lesson"
                                      : "Prossima Lezione",
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 15,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  isEnglish
                                      ? "No, back to lessons"
                                      : "No, torna alle lezioni",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ] else
                              ElevatedButton.icon(
                                onPressed: _startQuiz,
                                icon: const Icon(Icons.play_arrow),
                                label: Text(l10n.startQuiz),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 15,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final letterData = widget.letters[index];
                return FlashcardWidget(
                  letterData: letterData,
                  tts: flutterTts,
                  isEnglish: isEnglish,
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalPages, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 12 : 8,
                      height: _currentPage == index ? 12 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.blue
                            : Colors.grey[300],
                      ),
                    );
                  }),
                ),
                if (_currentPage < widget.letters.length) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Pulsante Indietro (Se non siamo alla prima pagina)
                        if (_currentPage > 0)
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                backgroundColor: Colors.grey[400],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 3,
                              ),
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: const Icon(Icons.arrow_back),
                            ),
                          ),

                        if (_currentPage > 0) const SizedBox(width: 20),

                        // Pulsante Avanti
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 3,
                            ),
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Text(
                              isEnglish ? "Next Letter" : "Prossima Lettera",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FlashcardWidget extends StatefulWidget {
  final Map<String, dynamic> letterData;
  final FlutterTts tts;
  final bool isEnglish;

  const FlashcardWidget({
    super.key,
    required this.letterData,
    required this.tts,
    required this.isEnglish,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    final char = widget.letterData['character'] ?? '?';
    final translit = widget.isEnglish
        ? (widget.letterData['transliteration_en'] ??
              widget.letterData['transliteration'] ??
              '')
        : (widget.letterData['transliteration'] ?? '');
    final tip = widget.isEnglish
        ? (widget.letterData['pronunciation_tip_en'] ??
              widget.letterData['pronunciation_tip'] ??
              '')
        : (widget.letterData['pronunciation_tip'] ?? '');
    final example = widget.letterData['example'] ?? '';
    final translation = widget.isEnglish
        ? (widget.letterData['translation_en'] ??
              widget.letterData['translation'] ??
              '')
        : (widget.letterData['translation'] ?? '');

    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isUnder = _animation.value > 0.5;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isUnder
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildBack(char, translit, example, translation),
                  )
                : _buildFront(char, tip),
          );
        },
      ),
    );
  }

  Widget _buildCard(Widget child, Color color, Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: borderColor, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildFront(String char, String tip) {
    return _buildCard(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            char,
            style: const TextStyle(
              fontSize: 140,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              tip,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 50),
          IconButton(
            icon: const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              child: Icon(Icons.volume_up, size: 30, color: Colors.white),
            ),
            onPressed: () {
              // Speak the character or standard sound
              widget.tts.speak(char);
            },
          ),
          const SizedBox(height: 20),
          const Text(
            "Tap to flip",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const Color(0xFF58CC02), // Duolingo green-ish
      const Color(0xFF46A302),
    );
  }

  Widget _buildBack(
    String char,
    String translit,
    String example,
    String translation,
  ) {
    return _buildCard(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            translit,
            style: const TextStyle(
              fontSize: 100,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  example,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  translation,
                  style: const TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          IconButton(
            icon: const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.indigoAccent,
              child: Icon(Icons.volume_up, size: 30, color: Colors.white),
            ),
            onPressed: () {
              widget.tts.speak(example);
            },
          ),
        ],
      ),
      Colors.white,
      Colors.indigo,
    );
  }
}
