import 'package:flutter/foundation.dart';
import '../core/models/question.dart';

/// Result of answering a quiz question.
enum AnswerResult { correct, wrong, gameOver }

/// Pure quiz logic provider — zero Flutter UI dependencies.
///
/// Owns: score, lives, question index, game-over state.
/// Does NOT own: dialogs, TTS, animations, haptics, navigation.
class QuizProvider extends ChangeNotifier {
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _lives = 3;
  bool _answerGiven = false;
  bool _isGameOver = false;
  AnswerResult? _lastResult;

  /// True if the user already gave a wrong answer on the current question.
  /// Once set, a correct retry will NOT increment the score.
  bool _wrongOnCurrent = false;

  // ---------------------------------------------------------------------------
  // Getters (read-only)
  // ---------------------------------------------------------------------------

  List<Question> get questions => _questions;
  Question get currentQuestion => _questions[_currentIndex];
  int get currentIndex => _currentIndex;
  int get totalQuestions => _questions.length;
  int get score => _score;
  int get lives => _lives;
  bool get answerGiven => _answerGiven;
  bool get isGameOver => _isGameOver;
  AnswerResult? get lastResult => _lastResult;

  /// True when the last question has been answered correctly.
  bool get isQuizComplete =>
      _currentIndex >= _questions.length - 1 && _answerGiven && !_isGameOver;

  /// Progress fraction [0.0, 1.0].
  double get progress =>
      _questions.isEmpty ? 0 : (_currentIndex + 1) / _questions.length;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes or resets the quiz with new questions (shuffled options).
  void initQuiz(List<Question> questions) {
    _questions = questions.map((q) => q.withShuffledOptions()).toList();
    _currentIndex = 0;
    _score = 0;
    _lives = 3;
    _answerGiven = false;
    _isGameOver = false;
    _lastResult = null;
    _wrongOnCurrent = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Core logic
  // ---------------------------------------------------------------------------

  /// Checks [choice] against [correct] and updates state.
  ///
  /// Returns [AnswerResult] so the widget can trigger the appropriate UI
  /// feedback (dialog, shake, haptics) without the provider knowing about UI.
  AnswerResult checkAnswer(String choice, String correct) {
    if (_answerGiven || _isGameOver) return _lastResult ?? AnswerResult.wrong;

    _answerGiven = true;

    if (choice == correct) {
      // Only award points if this is the first attempt on this question
      if (!_wrongOnCurrent) {
        _score++;
      }
      _lastResult = AnswerResult.correct;
    } else {
      _wrongOnCurrent = true;
      _lives--;
      if (_lives <= 0) {
        _isGameOver = true;
        _lastResult = AnswerResult.gameOver;
      } else {
        _lastResult = AnswerResult.wrong;
      }
    }

    notifyListeners();
    return _lastResult!;
  }

  /// Advances to the next question.
  ///
  /// Returns `true` if there are more questions, `false` if the quiz is done.
  bool advanceQuestion() {
    if (_isGameOver) return false;

    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _answerGiven = false;
      _lastResult = null;
      _wrongOnCurrent = false;
      notifyListeners();
      return true;
    }

    // Quiz complete — don't advance
    return false;
  }

  /// Clears the "answer given" lock after a wrong answer, allowing retry.
  void clearAnswerState() {
    _answerGiven = false;
    _lastResult = null;
    // NOTE: _wrongOnCurrent intentionally NOT reset — stays true for this question
    notifyListeners();
  }

  /// Full reset for "Retry" after game over — re-shuffles questions.
  void resetForRetry() {
    _questions = _questions.map((q) => q.withShuffledOptions()).toList();
    _currentIndex = 0;
    _score = 0;
    _lives = 3;
    _answerGiven = false;
    _isGameOver = false;
    _lastResult = null;
    _wrongOnCurrent = false;
    notifyListeners();
  }
}
