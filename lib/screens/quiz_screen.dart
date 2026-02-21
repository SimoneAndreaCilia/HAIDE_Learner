import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/animazione_scossa.dart';
import '../providers/language_provider.dart';
import 'package:flutter/services.dart'; // Per HapticFeedback
import 'dart:ui'; // Per ImageFilter
import 'package:lottie/lottie.dart'; // Per animazioni fluide vettoriali
import '../providers/progress_provider.dart';
import '../services/database_service.dart';
import '../core/models/question.dart';
import '../providers/quiz_provider.dart';

class QuizScreen extends StatefulWidget {
  final String titoloLezione;
  final List<Question> domande;
  final List<Map<String, dynamic>>?
  tips; // Aggiunto parametro opzionale per i tips
  final bool isCustomQuiz;
  final String? heroTag;
  final IconData? lessonIcon;
  final Color? topicColor;
  final String? unitId;
  final String? lessonId;

  const QuizScreen({
    super.key,
    required this.titoloLezione,
    required this.domande,
    this.tips,
    this.isCustomQuiz = false,
    this.heroTag,
    this.lessonIcon,
    this.topicColor,
    this.unitId,
    this.lessonId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  // UI-only state (not quiz logic)
  bool _erroreRecente = false;

  final FlutterTts flutterTts = FlutterTts();
  final GlobalKey<AnimazioneScossaState> _shakeKey =
      GlobalKey<AnimazioneScossaState>();

  // Quiz logic lives in QuizProvider — created once, scoped to this screen
  late final QuizProvider _quizProvider;

  // Animation for the tips lightbulb
  late AnimationController _tipsAnimController;

  @override
  void initState() {
    super.initState();
    _quizProvider = QuizProvider()..initQuiz(widget.domande);
    _configuraVoce();

    // Initialize Wiggle/Shake animation
    _tipsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Start with a delay or immediately, creating a shake effect loop
    _startWiggle();
  }

  void _startWiggle() {
    // Esegue l'animazione avanti e indietro
    _tipsAnimController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _quizProvider.dispose();
    _tipsAnimController.dispose();
    super.dispose();
  }

  void _configuraVoce() async {
    await flutterTts.setLanguage("bg-BG");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.8);
  }

  Future<void> _parlaCurrent() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final isEnglish = languageProvider.currentLocale.languageCode == 'en';
    final domanda = _quizProvider.currentQuestion;

    final testoDaLeggere = domanda.getPronunciation(isEnglish);

    if (testoDaLeggere.isNotEmpty) {
      await flutterTts.speak(testoDaLeggere);
    }
  }

  void _verificaRisposta(String scelta, String corretta) {
    if (_quizProvider.answerGiven || _quizProvider.isGameOver) return;

    final l10n = AppLocalizations.of(context)!;
    final result = _quizProvider.checkAnswer(scelta, corretta);

    setState(() {
      switch (result) {
        case AnswerResult.correct:
          _mostraFeedbackAnimato(l10n.bravo, true);
          _avanzaDomanda();
          break;

        case AnswerResult.wrong:
          _erroreRecente = true;
          _shakeKey.currentState?.scuoti();
          _mostraFeedbackAnimato(l10n.wrongMessage(corretta), false);
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              _quizProvider.clearAnswerState();
              setState(() => _erroreRecente = false);
            }
          });
          break;

        case AnswerResult.gameOver:
          _erroreRecente = true;
          _shakeKey.currentState?.scuoti();
          _mostraFeedbackAnimato(l10n.wrongMessage(corretta), false);
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) _mostraGameOver();
          });
          break;
      }
    });
  }

  void _avanzaDomanda() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!_quizProvider.isGameOver && mounted) {
        if (_quizProvider.advanceQuestion()) {
          setState(() => _erroreRecente = false);
        } else {
          _fineLezione();
        }
      }
    });
  }

  void _mostraFeedbackAnimato(String testo, bool corretto) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, anim1, anim2) {
        return const SizedBox();
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: corretto
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    corretto
                        ? Icons.celebration
                        : Icons.sentiment_very_dissatisfied,
                    color: corretto ? Colors.green : Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    testo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: corretto
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Chiude automaticamente il popup dopo un po'
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  void _mostraGameOver() {
    final l10n = AppLocalizations.of(context)!;

    // Feedback tattile quando perdi (vibrazione leggera)
    HapticFeedback.mediumImpact();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "GameOver",
      barrierColor: Colors.black54, // Sfondo scuro semitrasparente
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, anim1, anim2) {
        return const SizedBox(); // Non usato qui, usiamo transitionBuilder
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        // Curva elastica per l'effetto "BOING" all'entrata
        final curvedValue = Curves.elasticOut.transform(anim1.value);

        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: _buildGameOverDialogContent(ctx, l10n),
          ),
        );
      },
    );
  }

  Widget _buildGameOverDialogContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: 5,
        sigmaY: 5,
      ), // Effetto sfocatura sfondo
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 16,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Animazione Lottie (Sostituisci con il tuo asset locale)
              // Usa un url temporaneo o un asset locale 'assets/heart_broken.json'
              SizedBox(
                height: 150,
                child: Lottie.asset(
                  'assets/animations/game_over.json',
                  fit: BoxFit.contain,
                  repeat:
                      false, // L'animazione si ferma quando finisce la tristezza
                  errorBuilder: (context, error, stackTrace) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.heart_broken, size: 80, color: Colors.red),
                        SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 2. Titolo Grande e Giocoso
              Text(
                l10n.gameOver,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900, // Molto grassetto (stile gaming)
                  color: Color(0xFF4B4B4B), // Grigio scuro morbido
                  // fontFamily: 'Nunito', // Consiglio: usa un font arrotondato se disponibile
                ),
              ),

              const SizedBox(height: 12),

              // 3. Sottotitolo descrittivo
              Text(
                l10n.noLives, // "Hai finito le vite..."
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // 4. Bottone "Chunky" (Bello grosso)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick(); // Click tattile
                    Navigator.of(context).pop();
                    Navigator.of(this.context).pop();
                  },
                  style:
                      ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFFF4B4B,
                        ), // Rosso Duolingo
                        foregroundColor: Colors.white,
                        elevation: 0, // Flat design ma con bordo sotto
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        // Simuliamo l'effetto 3D del bottone con un bordo inferiore
                        side: const BorderSide(color: Colors.transparent),
                      ).copyWith(
                        // Trucco per effetto 3D (ombra solida sotto)
                        shadowColor: WidgetStateProperty.all(
                          Colors.red.shade900,
                        ),
                        elevation: WidgetStateProperty.resolveWith((states) {
                          return states.contains(WidgetState.pressed) ? 0 : 6;
                        }),
                      ),
                  child: Text(
                    l10n.retry.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              // Opzionale: Bottone secondario "Esci"
              // TextButton(
              //   onPressed: () => Navigator.of(context).pop(),
              //   child: Text(
              //     "ESCI",
              //     style: TextStyle(
              //       color: Colors.grey[400],
              //       fontWeight: FontWeight.bold
              //     ),
              //   ),
              // )
            ],
          ),
        ),
      ),
    );
  }

  void _fineLezione() {
    final l10n = AppLocalizations.of(context)!;
    final provider = _quizProvider;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.lessonCompleted),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: Colors.orange, size: 60),
            const SizedBox(height: 20),
            Text(
              "${l10n.score}: ${provider.score} / ${provider.totalQuestions}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.livesLeft(provider.lives),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // Save progress if IDs are present
              if (widget.unitId != null && widget.lessonId != null) {
                // 2. Salva progresso locale (Shared Preferences)
                Provider.of<ProgressProvider>(
                  context,
                  listen: false,
                ).markLessonCompleted(widget.unitId!, widget.lessonId!);

                // 3. Salva progresso Cloud (Firestore)
                await DatabaseService().updateLessonProgress(
                  widget.unitId!,
                ); // Salvo usando unitId come topic (es. "unit_01_survival")
              }

              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text(l10n.continueBtn),
          ),
        ],
      ),
    );
  }

  void _showTipsModal(BuildContext context) {
    if (widget.tips == null || widget.tips!.isEmpty) return;

    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permette alla finestra di essere alta
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6, // Occupa il 60% dello schermo all'inizio
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Maniglia per trascinare
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Titolo della sezione
                  Text(
                    isEnglish ? "Tips & Grammar" : "Note & Grammatica",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lista delle Note
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: widget.tips!.length,
                      itemBuilder: (context, index) {
                        final tip = widget.tips![index];
                        final title = isEnglish
                            ? (tip['title_en'] ?? tip['title'])
                            : tip['title'];
                        final content = isEnglish
                            ? (tip['content_en'] ?? tip['content'])
                            : tip['content'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50], // Sfondo leggero
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                content,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                  height: 1.5, // Migliora la leggibilità
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottone "Ho capito"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(isEnglish ? "Got it!" : "Ho capito!"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _quizProvider,
      child: Consumer<QuizProvider>(
        builder: (context, provider, _) => _buildQuizBody(context, provider),
      ),
    );
  }

  Widget _buildQuizBody(BuildContext context, QuizProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final q = provider.currentQuestion;

    // Recupera lingua corrente
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final isEnglish = languageProvider.currentLocale.languageCode == 'en';

    // Typed accessors — zero fallback chains
    final parolaBulgara = q.bulgarianText.isNotEmpty ? q.bulgarianText : '?';
    final pronuncia = q.pronunciation;
    final opzioni = q.getOptions(isEnglish);
    final String? immagineUrl = q.imgUrl;
    final rispostaCorretta = q.getAnswer(isEnglish);
    final bool isAudioQuestion = q.type == 'audio';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titoloLezione),
        actions: [
          if (widget.tips != null && widget.tips!.isNotEmpty)
            AnimatedBuilder(
              animation: _tipsAnimController,
              builder: (context, child) {
                // Wiggle logic: sine wave
                // Multiplier 3 * 2 * pi makes it shake 3 times per cycle
                // 0.2 is the amplitude (angle in radians)
                final angle =
                    math.sin(_tipsAnimController.value * math.pi * 2 * 3) * 0.2;
                return Transform.rotate(
                  angle: angle,
                  child: IconButton(
                    icon: const Icon(
                      Icons.lightbulb,
                      color: Colors.yellowAccent,
                    ),
                    onPressed: () {
                      _tipsAnimController.stop(); // Stop shaking
                      _tipsAnimController.value = 0; // Reset to center
                      _showTipsModal(context);
                    },
                  ),
                );
              },
            ),
          AnimazioneScossa(
            key: _shakeKey,
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    Text(
                      "${provider.lives}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      _erroreRecente ? Icons.heart_broken : Icons.favorite,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        // Wrap body in Container for gradient/background
        decoration: BoxDecoration(
          gradient: widget.topicColor != null
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.topicColor!.withValues(alpha: 0.1),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.3],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HERO ANIMATION HEADER
              if (widget.heroTag != null && widget.lessonIcon != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Hero(
                      tag: widget.heroTag!,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.topicColor ?? Colors.blue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (widget.topicColor ?? Colors.blue)
                                  .withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.lessonIcon,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),

              // Barra Progresso
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: provider.progress,
                  minHeight: 15,
                  color: provider.lives > 1
                      ? const Color(0xFF58CC02)
                      : Colors.orange,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
              const Spacer(),

              // Domanda: "Come si dice..." oppure "Cos'è questo?" oppure CUSTOM
              Builder(
                builder: (context) {
                  final modelText = q.getQuestionText(isEnglish);
                  final questionText = modelText.isNotEmpty
                      ? modelText
                      : (immagineUrl != null ? l10n.whatIsThis : l10n.howToSay);

                  return Text(
                    questionText,
                    style: TextStyle(
                      color: const Color.fromARGB(255, 155, 154, 154),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              const SizedBox(height: 20),

              // --- AREA CENTRALE DINAMICA (Testo o Immagine) ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    // Se c'è l'immagine, mostrala.
                    if (immagineUrl != null && immagineUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          immagineUrl,
                          height: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Column(
                            children: [
                              const Icon(
                                Icons.error,
                                size: 50,
                                color: Colors.red,
                              ),
                              Text(l10n.imageError),
                            ],
                          ),
                        ),
                      )
                    else if (!isAudioQuestion)
                      // MOSTRIAMO IL TESTO SOLO SE NON È UNA DOMANDA AUDIO
                      Text(
                        parolaBulgara,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      // Placeholder per bilanciare l'altezza se è solo audio
                      const SizedBox(height: 50),

                    const SizedBox(height: 10),

                    // Riga Audio e Pronuncia
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Se c'è l'immagine o È AUDIO, non mostriamo la pronuncia scritta
                        if (immagineUrl == null && !isAudioQuestion)
                          Text(
                            pronuncia,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.blueGrey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                        if (!isAudioQuestion && !widget.isCustomQuiz)
                          const SizedBox(width: 10),

                        // Bottone Audio logic:
                        // 1. If isAudioQuestion -> Show BIG centered button (handled by UI above, essentially)
                        // 2. If !isAudioQuestion AND isCustomQuiz -> HIDE BUTTON (user request)
                        // 3. If !isAudioQuestion AND !isCustomQuiz -> Show Standard button
                        if (isAudioQuestion || !widget.isCustomQuiz)
                          Transform.scale(
                            scale: isAudioQuestion ? 2.0 : 1.0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.volume_up,
                                color: Colors.blue,
                                size: 30,
                              ),
                              onPressed: _parlaCurrent,
                            ),
                          ),
                      ],
                    ),
                    if (isAudioQuestion) const SizedBox(height: 40),
                  ],
                ),
              ),

              const Spacer(),

              // --- PULSANTI RISPOSTA ---
              ...opzioni.map((opzione) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(18),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      surfaceTintColor: Colors.white,
                      side: const BorderSide(color: Colors.grey, width: 2),
                      elevation: 4,
                      shadowColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () =>
                        _verificaRisposta(opzione, rispostaCorretta),
                    child: Text(
                      opzione,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
