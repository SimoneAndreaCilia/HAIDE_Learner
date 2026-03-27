import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/progress_provider.dart';
import '../widgets/animated_sky_background.dart';
import 'quiz_screen.dart';
import '../core/models/question.dart';

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
      // Helper per gestire tipi dynamic in modo sicuro
      String safeStr(dynamic val) => val?.toString() ?? '';
      List<String> safeList(dynamic val) {
        if (val is List) {
          return val.map((e) => e.toString()).toList();
        }
        return [];
      }

      final questions = widget.quiz!.map((q) {
        return Question(
          bulgarianText: safeStr(q['bulgarianText']),
          pronunciation: safeStr(q['pronunciation']),
          optionsIt: safeList(q['optionsIt']),
          optionsEn: safeList(q['optionsEn']),
          answerIt: safeStr(q['answerIt']),
          answerEn: safeStr(q['answerEn']),
          questionTextIt: safeStr(q['questionTextIt']).isNotEmpty
              ? safeStr(q['questionTextIt'])
              : 'Come si dice?',
          questionTextEn: safeStr(q['questionTextEn']),
          type: safeStr(q['type']),
        );
      }).toList();

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            titoloLezione: '${widget.title} Quiz',
            domande: questions,
            isCustomQuiz: true,
            unitId: 'alphabet',
            lessonId: widget.lessonId,
          ),
        ),
      );

      if (result == true && mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    // Fallback to auto-generated quiz if no specific quiz data is provided
    final questions = <Question>[];
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

      questions.add(
        Question(
          questionTextIt: isEnglish ? 'What sound is this?' : 'Che suono è?',
          bulgarianText: letter['character'] ?? '',
          optionsIt: options.cast<String>(),
          answerIt: correctSound,
          answerEn: correctSound,
          type: 'text',
        ),
      );
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
          questions.add(
            Question(
              questionTextIt: isEnglish
                  ? 'Listen and choose the word'
                  : 'Ascolta e scegli la parola',
              bulgarianText: '',
              pronunciation: example, // TTS reads this
              optionsIt: options.cast<String>(),
              answerIt: example,
              answerEn: example,
              type: 'audio',
            ),
          );
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
          unitId: 'alphabet',
          lessonId: widget.lessonId,
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Material(
          color: Colors.transparent,
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFFD700), // Gold
              shadows: [
                const Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4.0,
                  color: Colors.black,
                ),
                const Shadow(
                  // Stronger outline effect
                  offset: Offset(0, 0),
                  blurRadius: 8.0,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
          shadows: [
            Shadow(offset: Offset(0, 1), blurRadius: 2.0, color: Colors.black),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Animated Sky Background
          const Positioned.fill(child: AnimatedSkyBackground()),
          // Content
          Column(
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
                        if (!context.mounted) return;
                        // Unified save: ProgressProvider handles local + cloud
                        await Provider.of<ProgressProvider>(
                          context,
                          listen: false,
                        ).markLessonCompleted(
                          'alphabet',
                          widget.lessonId,
                          score: widget.letters.length,
                          totalQuestions: widget.letters.length,
                        );
                      }
                    }
                  },
                  itemBuilder: (context, index) {
                    if (index == widget.letters.length) {
                      final hasNextLesson =
                          widget.currentIndex != -1 &&
                          widget.currentIndex + 1 < widget.allLessons.length;

                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 60,
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFD4A574),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/flipcard.png'),
                              fit: BoxFit.fill,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF5D4037,
                                ).withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hasNextLesson ? '🏆' : '🎓',
                                  style: const TextStyle(fontSize: 70),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  isEnglish
                                      ? (hasNextLesson
                                            ? "Lesson Completed!"
                                            : "All Lessons Completed!")
                                      : (hasNextLesson
                                            ? "Lezione Completata!"
                                            : "Hai finito tutte le lezioni!"),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF3E2723),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isEnglish
                                      ? (hasNextLesson
                                            ? "Ready for the next one?"
                                            : "Test your knowledge with a quiz.")
                                      : (hasNextLesson
                                            ? "Passa all'altra lezione"
                                            : "Mettiti alla prova con un quiz."),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF5D4037),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                if (hasNextLesson) ...[
                                  _buildFantasyButton(
                                    label: isEnglish
                                        ? "Next Lesson"
                                        : "Prossima Lezione",
                                    icon: Icons.arrow_forward,
                                    onTap: () {
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
                                          nextLessonData['quiz']
                                              as List<dynamic>?;

                                      final nextQuiz =
                                          rawNextQuiz
                                              ?.map(
                                                (e) =>
                                                    Map<String, dynamic>.from(
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
                                  ),
                                  const SizedBox(height: 15),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      isEnglish
                                          ? "No, back to lessons"
                                          : "No, torna alle lezioni",
                                      style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        color: const Color(0xFF5D4037),
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ] else
                                  _buildFantasyButton(
                                    label: l10n.startQuiz,
                                    icon: Icons.play_arrow,
                                    onTap: _startQuiz,
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.7),
                      Colors.white.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(totalPages, (index) {
                        final isActive = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 12 : 8,
                          height: isActive ? 12 : 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? const Color(0xFFFFD700)
                                : const Color(0xFFD7CCC8),
                            border: isActive
                                ? Border.all(
                                    color: const Color(0xFF3E2723),
                                    width: 1,
                                  )
                                : null,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFFD700,
                                      ).withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
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
                              GestureDetector(
                                onTap: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFFA000),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Color(0xFF3E2723),
                                    size: 24,
                                  ),
                                ),
                              ),

                            if (_currentPage > 0) const SizedBox(width: 20),

                            // Pulsante Avanti
                            Expanded(
                              flex: 4,
                              child: GestureDetector(
                                onTap: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  height: 75,
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(
                                        'assets/images/next_bottom.png',
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.only(
                                    bottom: 5,
                                  ), // Adjust for text centering if needed
                                  child: Text(
                                    isEnglish
                                        ? "Next Letter"
                                        : "Prossima Lettera",
                                    style: GoogleFonts.nunito(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(
                                        0xFFFFF8E1,
                                      ), // Cream/Gold
                                      shadows: [
                                        const Shadow(
                                          blurRadius: 2.0,
                                          color: Colors.black,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
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
        ],
      ),
    );
  }

  Widget _buildFantasyButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFFFECB3), width: 2.0),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8D6E63), Color(0xFF3E2723)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFFFECB3), size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFECB3),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
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

  Widget _buildCard(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD4A574), width: 2.0),
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/images/flipcard.png'),
          fit: BoxFit.fill,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D4037).withValues(alpha: 0.4),
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
            style: GoogleFonts.nunito(
              fontSize: 140,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3E2723), // Dark Brown/Sepia
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              tip,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 26,
                color: const Color(0xFF3E2723), // Ink color
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () {
              widget.tts.speak(char);
            },
            child: Image.asset(
              'assets/images/corno_speaker.png',
              width: 60,
              height: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.isEnglish ? "Tap to flip" : "Tocca per girare",
            style: GoogleFonts.nunito(
              color: const Color(0xFF5D4037),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
            style: GoogleFonts.nunito(
              fontSize: 100,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3E2723),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                Text(
                  example,
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3E2723),
                  ),
                ),
                Text(
                  translation,
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () {
              widget.tts.speak(example);
            },
            child: Image.asset(
              'assets/images/corno_speaker.png',
              width: 60,
              height: 60,
            ),
          ),
        ],
      ),
    );
  }
}
