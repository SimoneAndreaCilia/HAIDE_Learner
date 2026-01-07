// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get helloWorld => 'Ciao Mondo!';

  @override
  String get startQuiz => 'Inizia Quiz';

  @override
  String get quizTitle => 'Quiz';

  @override
  String get question => 'Domanda';

  @override
  String get score => 'Punteggio';

  @override
  String get correct => 'Corretto!';

  @override
  String get wrong => 'Sbagliato!';

  @override
  String get nextQuestion => 'Prossima Domanda';

  @override
  String get finishQuiz => 'Termina Quiz';

  @override
  String get resultTime => 'Tempo';

  @override
  String get settings => 'Impostazioni';

  @override
  String get language => 'Lingua';

  @override
  String get learningPath => 'Percorso di Apprendimento';

  @override
  String get lessonEmpty => 'Questa lezione è vuota!';

  @override
  String questionsCount(int count) {
    return '$count domande';
  }

  @override
  String get whatIsThis => 'Cos\'è questo?';

  @override
  String get howToSay => 'Come si dice...';

  @override
  String get bravo => 'браво!🎉 (bravo)';

  @override
  String wrongMessage(String correct) {
    return 'SBAGLIATO! 😢 Era: $correct';
  }

  @override
  String get gameOver => 'GAME OVER';

  @override
  String get noLives => 'Hai finito le vite! Devi ricominciare la lezione.';

  @override
  String get retry => 'Riprova';

  @override
  String get lessonCompleted => 'Lezione Completata! 🏆';

  @override
  String get continueBtn => 'CONTINUA';

  @override
  String livesLeft(int count) {
    return 'Vite rimaste: $count ❤️';
  }

  @override
  String get imageError => 'Errore immagine';
}
