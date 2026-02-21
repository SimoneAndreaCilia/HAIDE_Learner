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
  ///
  /// Key resolution order (first non-null wins):
  /// - Options IT: `options_it` → `opzioni`
  /// - Options EN: `options_en` → `opzioni_en`
  /// - Answer IT:  `answer_it` → `soluzione` → `italiano`
  /// - Answer EN:  `answer_en` → `inglese`
  /// - Question IT: `text_question_it` → `question_it` → `question` → `domanda`
  /// - Question EN: `text_question_en` → `question_en` → `domanda_en`
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      bulgarianText: _str(map['bulgaro']),
      pronunciation: _str(map['pronuncia']),
      pronunciationEn: map['pronuncia_en'] as String?,
      optionsIt: _strList(map['options_it'] ?? map['opzioni']),
      optionsEn: _strList(map['options_en'] ?? map['opzioni_en']),
      answerIt: _str(map['answer_it'] ?? map['soluzione'] ?? map['italiano']),
      answerEn: _str(map['answer_en'] ?? map['inglese']),
      questionTextIt: _str(
        map['text_question_it'] ??
            map['question_it'] ??
            map['question'] ??
            map['domanda'],
      ),
      questionTextEn: _str(
        map['text_question_en'] ?? map['question_en'] ?? map['domanda_en'],
      ),
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
