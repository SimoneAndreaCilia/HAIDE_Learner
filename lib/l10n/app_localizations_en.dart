// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World!';

  @override
  String get startQuiz => 'Start Quiz';

  @override
  String get quizTitle => 'Quiz';

  @override
  String get question => 'Question';

  @override
  String get score => 'Score';

  @override
  String get correct => 'Correct!';

  @override
  String get wrong => 'Wrong!';

  @override
  String get nextQuestion => 'Next Question';

  @override
  String get finishQuiz => 'Finish Quiz';

  @override
  String get resultTime => 'Time';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get learningPath => 'Learning Path';

  @override
  String get lessonEmpty => 'This lesson is empty!';

  @override
  String questionsCount(int count) {
    return '$count questions';
  }

  @override
  String get whatIsThis => 'What is this?';

  @override
  String get howToSay => 'How do you say...';

  @override
  String get bravo => 'BRAVO! 🎉';

  @override
  String wrongMessage(String correct) {
    return 'WRONG! 😢 It was: $correct';
  }

  @override
  String get gameOver => 'GAME OVER';

  @override
  String get noLives => 'No lives left! You must restart the lesson.';

  @override
  String get retry => 'Retry';

  @override
  String get lessonCompleted => 'Lesson Completed! 🏆';

  @override
  String get continueBtn => 'CONTINUE';

  @override
  String livesLeft(int count) {
    return 'Lives left: $count ❤️';
  }

  @override
  String get imageError => 'Image Error';
}
