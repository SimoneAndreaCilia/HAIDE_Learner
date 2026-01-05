// File: lib/screens/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/animazione_scossa.dart';
import '../providers/language_provider.dart';

class QuizScreen extends StatefulWidget {
  final String titoloLezione;
  final List<Map<String, dynamic>> domande;

  const QuizScreen({
    super.key,
    required this.titoloLezione,
    required this.domande,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _indiceDomanda = 0;
  int _punteggio = 0;
  int _vite = 3;
  bool _rispostaData = false;
  bool _erroreRecente = false;
  bool _gameOver = false;

  final FlutterTts flutterTts = FlutterTts();
  final GlobalKey<AnimazioneScossaState> _shakeKey =
      GlobalKey<AnimazioneScossaState>();

  @override
  void initState() {
    super.initState();
    _configuraVoce();
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
    final domanda = widget.domande[_indiceDomanda];

    String testoDaLeggere = '';

    if (isEnglish) {
      testoDaLeggere = domanda['pronuncia_en'] ?? domanda['pronuncia'] ?? '';
    } else {
      testoDaLeggere = domanda['pronuncia'] ?? '';
    }

    if (testoDaLeggere.isNotEmpty) {
      await flutterTts.speak(testoDaLeggere);
    }
  }

  void _verificaRisposta(String scelta, String corretta) {
    if (_rispostaData || _gameOver) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _rispostaData = true;

      if (scelta == corretta) {
        _punteggio++;
        _mostraMessaggio(l10n.bravo, Colors.green);
        _avanzaDomanda();
      } else {
        _vite--;
        _erroreRecente = true;
        _shakeKey.currentState?.scuoti();
        _mostraMessaggio(
          l10n.wrongMessage(corretta),
          Colors.red,
        ); // Ti dice qual era quella giusta

        if (_vite == 0) {
          _gameOver = true;
          _mostraGameOver();
        } else {
          Future.delayed(const Duration(milliseconds: 1500), () {
            // Tempo aumentato un po' per leggere l'errore
            if (mounted) {
              setState(() {
                _rispostaData = false;
                _erroreRecente = false;
              });
            }
          });
        }
      }
    });
  }

  void _avanzaDomanda() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_vite > 0 && mounted) {
        if (_indiceDomanda < widget.domande.length - 1) {
          setState(() {
            _indiceDomanda++;
            _rispostaData = false;
            _erroreRecente = false;
          });
        } else {
          _fineLezione();
        }
      }
    });
  }

  void _mostraMessaggio(String testo, Color colore) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          testo,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        backgroundColor: colore,
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _mostraGameOver() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.heart_broken, color: Colors.red, size: 30),
            const SizedBox(width: 10),
            Text(l10n.gameOver),
          ],
        ),
        content: Text(l10n.noLives),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              l10n.retry,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _fineLezione() {
    final l10n = AppLocalizations.of(context)!;
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
              "${l10n.score}: $_punteggio / ${widget.domande.length}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.livesLeft(_vite),
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
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(l10n.continueBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final domandaCorrente = widget.domande[_indiceDomanda];

    // --- LOGICA IBRIDA ---
    // 0. Recupera lingua corrente
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ); // O usa listen: true se vuoi rebuild al cambio lingua qui (ma non c'è tasto)
    final isEnglish = languageProvider.currentLocale.languageCode == 'en';

    // 1. Dati comuni
    final parolaBulgara = domandaCorrente['bulgaro'] ?? '?';
    final pronuncia = domandaCorrente['pronuncia'] ?? '';

    // Scelta opzioni in base alla lingua
    List<String> opzioni;
    if (isEnglish && domandaCorrente['opzioni_en'] != null) {
      opzioni = List<String>.from(domandaCorrente['opzioni_en']);
    } else {
      opzioni = List<String>.from(domandaCorrente['opzioni'] ?? []);
    }

    // 2. Controllo se c'è un'immagine
    final String? immagineUrl = domandaCorrente['immagine'];

    // 3. Determina la risposta corretta
    String rispostaCorretta;
    if (isEnglish) {
      // Se inglese, usa il campo 'inglese', fallback su 'soluzione' o 'italiano' se mancasse (meglio evitare errori)
      rispostaCorretta =
          domandaCorrente['inglese'] ??
          domandaCorrente['soluzione'] ??
          domandaCorrente['italiano'] ??
          '';
    } else {
      // Se italiano
      rispostaCorretta =
          domandaCorrente['soluzione'] ?? domandaCorrente['italiano'] ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titoloLezione),
        actions: [
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
                      "$_vite",
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra Progresso
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_indiceDomanda + 1) / widget.domande.length,
                minHeight: 15,
                color: _vite > 1 ? const Color(0xFF58CC02) : Colors.orange,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const Spacer(),

            // Domanda: "Come si dice..." oppure "Cos'è questo?"
            Text(
              immagineUrl != null ? l10n.whatIsThis : l10n.howToSay,
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
              textAlign: TextAlign.center,
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
                  // Se c'è l'immagine, mostrala. Altrimenti mostra il testo bulgaro.
                  if (immagineUrl != null && immagineUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        immagineUrl,
                        height: 200, // Altezza fissa per non sballare il layout
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
                  else
                    Text(
                      parolaBulgara,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Riga Audio e Pronuncia
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Se c'è l'immagine, non mostriamo la pronuncia scritta (sarebbe un suggerimento troppo facile!)
                      if (immagineUrl == null)
                        Text(
                          pronuncia,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.blueGrey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(
                          Icons.volume_up,
                          color: Colors.blue,
                          size: 30,
                        ),
                        onPressed: _parlaCurrent,
                      ),
                    ],
                  ),
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
                  onPressed: () => _verificaRisposta(opzione, rispostaCorretta),
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
    );
  }
}
