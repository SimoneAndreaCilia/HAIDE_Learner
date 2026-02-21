import 'package:flutter_test/flutter_test.dart';
import 'package:haide/providers/quiz_provider.dart';
import 'package:haide/core/models/question.dart';

/// Helper to create a minimal Question for testing.
Question _q({
  String answerIt = 'Roma',
  String answerEn = 'Rome',
  List<String> optionsIt = const ['Roma', 'Milano', 'Napoli'],
  List<String> optionsEn = const ['Rome', 'Milan', 'Naples'],
}) {
  return Question(
    bulgarianText: 'Рим',
    pronunciation: 'Rim',
    optionsIt: optionsIt,
    optionsEn: optionsEn,
    answerIt: answerIt,
    answerEn: answerEn,
    questionTextIt: 'Qual è la capitale?',
    questionTextEn: 'What is the capital?',
    type: 'text',
  );
}

void main() {
  late QuizProvider provider;
  late List<Question> questions;

  setUp(() {
    provider = QuizProvider();
    questions = [
      _q(answerIt: 'Roma', answerEn: 'Rome'),
      _q(
        answerIt: 'Parigi',
        answerEn: 'Paris',
        optionsIt: ['Roma', 'Parigi', 'Berlino'],
        optionsEn: ['Rome', 'Paris', 'Berlin'],
      ),
      _q(
        answerIt: 'Berlino',
        answerEn: 'Berlin',
        optionsIt: ['Roma', 'Parigi', 'Berlino'],
        optionsEn: ['Rome', 'Paris', 'Berlin'],
      ),
    ];
    provider.initQuiz(questions);
  });

  group('initQuiz', () {
    test('sets initial state correctly', () {
      expect(provider.currentIndex, 0);
      expect(provider.score, 0);
      expect(provider.lives, 3);
      expect(provider.answerGiven, false);
      expect(provider.isGameOver, false);
      expect(provider.lastResult, null);
      expect(provider.totalQuestions, 3);
    });

    test('shuffles options (different instance, same elements)', () {
      final originalOptions = questions[0].optionsIt;
      final shuffled = provider.questions[0].optionsIt;
      // Same elements, possibly different order
      expect(shuffled.toSet(), originalOptions.toSet());
    });
  });

  group('checkAnswer', () {
    test('correct answer increments score and returns correct', () {
      final result = provider.checkAnswer('Roma', 'Roma');

      expect(result, AnswerResult.correct);
      expect(provider.score, 1);
      expect(provider.answerGiven, true);
    });

    test('wrong answer decrements lives and returns wrong', () {
      final result = provider.checkAnswer('Milano', 'Roma');

      expect(result, AnswerResult.wrong);
      expect(provider.lives, 2);
      expect(provider.score, 0);
      expect(provider.answerGiven, true);
    });

    test('third wrong answer triggers gameOver', () {
      provider.checkAnswer('Milano', 'Roma'); // lives: 2
      provider.clearAnswerState();

      provider.checkAnswer('Napoli', 'Roma'); // lives: 1
      provider.clearAnswerState();

      final result = provider.checkAnswer('Milano', 'Roma'); // lives: 0

      expect(result, AnswerResult.gameOver);
      expect(provider.isGameOver, true);
      expect(provider.lives, 0);
    });

    test('does nothing when answerGiven is true', () {
      provider.checkAnswer('Roma', 'Roma'); // score: 1, answerGiven: true
      provider.checkAnswer('Roma', 'Roma'); // should be ignored

      expect(provider.score, 1);
    });

    test('does nothing when gameOver is true', () {
      provider.checkAnswer('X', 'Roma');
      provider.clearAnswerState();
      provider.checkAnswer('X', 'Roma');
      provider.clearAnswerState();
      provider.checkAnswer('X', 'Roma'); // game over

      final result = provider.checkAnswer('Roma', 'Roma');

      expect(result, AnswerResult.gameOver);
      expect(provider.score, 0);
    });
  });

  group('advanceQuestion', () {
    test('advances to next question and returns true', () {
      provider.checkAnswer('Roma', 'Roma');
      final advanced = provider.advanceQuestion();

      expect(advanced, true);
      expect(provider.currentIndex, 1);
      expect(provider.answerGiven, false);
      expect(provider.lastResult, null);
    });

    test('returns false when at last question', () {
      // Advance to last question
      provider.checkAnswer('Roma', 'Roma');
      provider.advanceQuestion();
      provider.checkAnswer('Parigi', 'Parigi');
      provider.advanceQuestion();

      // Already at question index 2 (last), should not advance
      expect(provider.currentIndex, 2);
      provider.checkAnswer('Berlino', 'Berlino');
      final advanced = provider.advanceQuestion();

      expect(advanced, false);
      expect(provider.currentIndex, 2);
    });

    test('returns false when gameOver', () {
      provider.checkAnswer('X', 'Roma');
      provider.clearAnswerState();
      provider.checkAnswer('X', 'Roma');
      provider.clearAnswerState();
      provider.checkAnswer('X', 'Roma'); // game over

      final advanced = provider.advanceQuestion();

      expect(advanced, false);
    });
  });

  group('clearAnswerState', () {
    test('resets answerGiven and lastResult', () {
      provider.checkAnswer('X', 'Roma');
      expect(provider.answerGiven, true);
      expect(provider.lastResult, AnswerResult.wrong);

      provider.clearAnswerState();
      expect(provider.answerGiven, false);
      expect(provider.lastResult, null);
    });
  });

  group('resetForRetry', () {
    test('fully resets quiz state after game over', () {
      provider.checkAnswer('X', 'Roma');
      provider.clearAnswerState();
      provider.checkAnswer('X', 'Roma');
      provider.clearAnswerState();
      provider.checkAnswer('X', 'Roma'); // game over

      provider.resetForRetry();

      expect(provider.currentIndex, 0);
      expect(provider.score, 0);
      expect(provider.lives, 3);
      expect(provider.answerGiven, false);
      expect(provider.isGameOver, false);
      expect(provider.lastResult, null);
    });
  });

  group('computed getters', () {
    test('progress is correct fraction', () {
      expect(provider.progress, 1 / 3); // index 0, 3 questions

      provider.checkAnswer('Roma', 'Roma');
      provider.advanceQuestion();
      expect(provider.progress, 2 / 3); // index 1

      provider.checkAnswer('Parigi', 'Parigi');
      provider.advanceQuestion();
      expect(provider.progress, 3 / 3); // index 2
    });

    test('isQuizComplete is true after last correct answer', () {
      provider.checkAnswer('Roma', 'Roma');
      provider.advanceQuestion();
      provider.checkAnswer('Parigi', 'Parigi');
      provider.advanceQuestion();
      provider.checkAnswer('Berlino', 'Berlino');

      expect(provider.isQuizComplete, true);
    });

    test('isQuizComplete is false mid-quiz', () {
      provider.checkAnswer('Roma', 'Roma');
      expect(provider.isQuizComplete, false);
    });

    test('isQuizComplete is false after game over', () {
      provider.checkAnswer('X', 'Roma');
      provider.clearAnswerState();
      provider.checkAnswer('X', 'Roma');
      provider.clearAnswerState();
      provider.checkAnswer('X', 'Roma');

      expect(provider.isQuizComplete, false);
    });
  });

  group('notifyListeners', () {
    test('checkAnswer notifies listeners', () {
      int callCount = 0;
      provider.addListener(() => callCount++);

      provider.checkAnswer('Roma', 'Roma');

      expect(callCount, 1);
    });

    test('advanceQuestion notifies listeners', () {
      provider.checkAnswer('Roma', 'Roma');

      int callCount = 0;
      provider.addListener(() => callCount++);

      provider.advanceQuestion();

      expect(callCount, 1);
    });
  });
}
