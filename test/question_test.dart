import 'package:flutter_test/flutter_test.dart';
import 'package:haide/core/models/question.dart';

void main() {
  group('Question.fromMap', () {
    test('parses new-format (courses) keys correctly', () {
      final map = {
        'bulgaro': 'Здравей',
        'pronuncia': 'Zdravey',
        'pronuncia_en': 'Zdravey EN',
        'options_it': ['Ciao', 'Arrivederci', 'Grazie'],
        'options_en': ['Hello', 'Goodbye', 'Thanks'],
        'answer_it': 'Ciao',
        'answer_en': 'Hello',
        'text_question_it': 'Come si dice?',
        'text_question_en': 'How do you say?',
        'type': 'text',
        'imgUrl': 'https://example.com/img.png',
      };

      final q = Question.fromMap(map);

      expect(q.bulgarianText, 'Здравей');
      expect(q.pronunciation, 'Zdravey');
      expect(q.pronunciationEn, 'Zdravey EN');
      expect(q.optionsIt, ['Ciao', 'Arrivederci', 'Grazie']);
      expect(q.optionsEn, ['Hello', 'Goodbye', 'Thanks']);
      expect(q.answerIt, 'Ciao');
      expect(q.answerEn, 'Hello');
      expect(q.questionTextIt, 'Come si dice?');
      expect(q.questionTextEn, 'How do you say?');
      expect(q.type, 'text');
      expect(q.imgUrl, 'https://example.com/img.png');
    });

    test('parses old-format (lezioni/alphabet) keys correctly', () {
      final map = {
        'bulgaro': 'Да',
        'pronuncia': 'Da',
        'opzioni': ['Sì', 'No', 'Forse'],
        'opzioni_en': ['Yes', 'No', 'Maybe'],
        'soluzione': 'Sì',
        'inglese': 'Yes',
        'question': 'Come si dice "Da"?',
        'type': 'audio',
      };

      final q = Question.fromMap(map);

      expect(q.bulgarianText, 'Да');
      expect(q.pronunciation, 'Da');
      expect(q.optionsIt, ['Sì', 'No', 'Forse']);
      expect(q.optionsEn, ['Yes', 'No', 'Maybe']);
      expect(q.answerIt, 'Sì');
      expect(q.answerEn, 'Yes');
      expect(q.questionTextIt, 'Come si dice "Da"?');
      expect(q.type, 'audio');
    });

    test('new keys take priority over old keys', () {
      final map = {
        'options_it': ['Nuovo'],
        'opzioni': ['Vecchio'],
        'answer_it': 'Nuovo',
        'soluzione': 'Vecchio',
        'text_question_it': 'Domanda nuova',
        'question': 'Domanda vecchia',
        'bulgaro': 'Test',
      };

      final q = Question.fromMap(map);

      expect(q.optionsIt, ['Nuovo']);
      expect(q.answerIt, 'Nuovo');
      expect(q.questionTextIt, 'Domanda nuova');
    });

    test('defaults to empty values when fields are missing', () {
      final q = Question.fromMap({});

      expect(q.bulgarianText, '');
      expect(q.pronunciation, '');
      expect(q.pronunciationEn, isNull);
      expect(q.optionsIt, isEmpty);
      expect(q.optionsEn, isEmpty);
      expect(q.answerIt, '');
      expect(q.answerEn, '');
      expect(q.questionTextIt, '');
      expect(q.questionTextEn, '');
      expect(q.type, 'text'); // default
      expect(q.imgUrl, isNull);
    });

    test('type defaults to "text" when missing', () {
      final q = Question.fromMap({'bulgaro': 'X'});
      expect(q.type, 'text');
    });
  });

  group('Language-aware accessors', () {
    late Question q;

    setUp(() {
      q = const Question(
        bulgarianText: 'Б',
        optionsIt: ['A', 'B'],
        optionsEn: ['C', 'D'],
        answerIt: 'A',
        answerEn: 'C',
        questionTextIt: 'Domanda?',
        questionTextEn: 'Question?',
        pronunciation: 'be',
        pronunciationEn: 'bee',
      );
    });

    test('getOptions returns IT when isEnglish=false', () {
      expect(q.getOptions(false), ['A', 'B']);
    });

    test('getOptions returns EN when isEnglish=true', () {
      expect(q.getOptions(true), ['C', 'D']);
    });

    test('getOptions falls back to IT when EN is empty', () {
      final noEn = Question(
        bulgarianText: 'X',
        optionsIt: ['A'],
        answerIt: 'A',
      );
      expect(noEn.getOptions(true), ['A']);
    });

    test('getAnswer returns correct language', () {
      expect(q.getAnswer(false), 'A');
      expect(q.getAnswer(true), 'C');
    });

    test('getAnswer falls back to IT when EN is empty', () {
      final noEn = Question(
        bulgarianText: 'X',
        optionsIt: ['A'],
        answerIt: 'A',
      );
      expect(noEn.getAnswer(true), 'A');
    });

    test('getQuestionText returns correct language', () {
      expect(q.getQuestionText(false), 'Domanda?');
      expect(q.getQuestionText(true), 'Question?');
    });

    test('getPronunciation returns correct language', () {
      expect(q.getPronunciation(false), 'be');
      expect(q.getPronunciation(true), 'bee');
    });

    test('getPronunciation falls back to IT when EN is null', () {
      final noEn = Question(
        bulgarianText: 'X',
        optionsIt: ['A'],
        answerIt: 'A',
        pronunciation: 'test',
      );
      expect(noEn.getPronunciation(true), 'test');
    });
  });

  group('withShuffledOptions', () {
    test('returns a new instance with same data', () {
      const original = Question(
        bulgarianText: 'Б',
        optionsIt: ['A', 'B', 'C'],
        optionsEn: ['D', 'E', 'F'],
        answerIt: 'A',
        answerEn: 'D',
      );

      final shuffled = original.withShuffledOptions();

      // Data preserved
      expect(shuffled.bulgarianText, 'Б');
      expect(shuffled.answerIt, 'A');
      expect(shuffled.answerEn, 'D');

      // Options have same elements (possibly different order)
      expect(shuffled.optionsIt, unorderedEquals(['A', 'B', 'C']));
      expect(shuffled.optionsEn, unorderedEquals(['D', 'E', 'F']));
    });

    test('does not mutate the original', () {
      const original = Question(
        bulgarianText: 'Б',
        optionsIt: ['A', 'B', 'C'],
        answerIt: 'A',
      );

      // Shuffle many times — original should stay unchanged
      for (var i = 0; i < 10; i++) {
        original.withShuffledOptions();
      }

      expect(original.optionsIt, ['A', 'B', 'C']);
    });
  });
}
