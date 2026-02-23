/// Typed, immutable model that normalizes all Firestore question formats.
///
/// Supports three data sources:
/// - `courses` collection (new keys: `options_it`, `answer_it`, `text_question_it`)
/// - `alphabet` auto-generated (old keys: `opzioni`, `soluzione`, `italiano`)
/// - Direct constructor for programmatically built questions
class Question {
  final String bulgarianText;
  final String pronunciation;
  final String? pronunciationEn;
  final List<String> optionsIt;
  final List<String> optionsEn;
  final String answerIt;
  final String answerEn;
  final String questionTextIt;
  final String questionTextEn;
  final String type; // 'text' | 'audio'
  final String? imgUrl;

  const Question({
    required this.bulgarianText,
    this.pronunciation = '',
    this.pronunciationEn,
    required this.optionsIt,
    this.optionsEn = const [],
    required this.answerIt,
    this.answerEn = '',
    this.questionTextIt = '',
    this.questionTextEn = '',
    this.type = 'text',
    this.imgUrl,
  });

  /// Normalizes a Firestore [Map] from ANY known format into a typed [Question].
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      bulgarianText: _str(map['bulgarianText']),
      pronunciation: _str(map['pronunciation']),
      pronunciationEn: map['pronunciationEn'] as String?,
      optionsIt: _strList(map['optionsIt']),
      optionsEn: _strList(map['optionsEn']),
      answerIt: _str(map['answerIt']),
      answerEn: _str(map['answerEn']),
      questionTextIt: _str(map['questionTextIt']),
      questionTextEn: _str(map['questionTextEn']),
      type: _str(map['type']).isNotEmpty ? _str(map['type']) : 'text',
      imgUrl: map['imgUrl'] as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // Language-aware accessors
  // ---------------------------------------------------------------------------

  /// Returns options for the given language, falling back to IT if EN is empty.
  List<String> getOptions(bool isEnglish) {
    if (isEnglish && optionsEn.isNotEmpty) return optionsEn;
    return optionsIt;
  }

  /// Returns the correct answer for the given language, falling back to IT.
  String getAnswer(bool isEnglish) {
    if (isEnglish && answerEn.isNotEmpty) return answerEn;
    return answerIt;
  }

  /// Returns the question text for the given language, falling back to IT.
  String getQuestionText(bool isEnglish) {
    if (isEnglish && questionTextEn.isNotEmpty) return questionTextEn;
    if (questionTextIt.isNotEmpty) return questionTextIt;
    return ''; // Caller provides a default (e.g. l10n.howToSay)
  }

  /// Returns the pronunciation text for TTS.
  String getPronunciation(bool isEnglish) {
    if (isEnglish && pronunciationEn != null && pronunciationEn!.isNotEmpty) {
      return pronunciationEn!;
    }
    return pronunciation;
  }

  // ---------------------------------------------------------------------------
  // Immutable transformations
  // ---------------------------------------------------------------------------

  /// Returns a new [Question] with shuffled option lists.
  /// The original instance is NOT modified.
  Question withShuffledOptions() {
    final shuffledIt = List<String>.of(optionsIt)..shuffle();
    final shuffledEn = List<String>.of(optionsEn)..shuffle();
    return Question(
      bulgarianText: bulgarianText,
      pronunciation: pronunciation,
      pronunciationEn: pronunciationEn,
      optionsIt: shuffledIt,
      optionsEn: shuffledEn,
      answerIt: answerIt,
      answerEn: answerEn,
      questionTextIt: questionTextIt,
      questionTextEn: questionTextEn,
      type: type,
      imgUrl: imgUrl,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _str(dynamic value) => value?.toString() ?? '';

  static List<String> _strList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  @override
  String toString() =>
      'Question(bulgarian: $bulgarianText, answerIt: $answerIt, '
      'type: $type, optionsIt: ${optionsIt.length})';
}
