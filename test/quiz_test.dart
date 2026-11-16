import 'dart:math';

import 'package:basicflashcards/quiz/quiz.dart';
import 'package:basicflashcards/models/study_set.dart';
import 'package:flutter_test/flutter_test.dart';

Flashcard card(String id, String term, String def) =>
    Flashcard(id: id, term: term, definition: def);

void main() {
  final cards = [
    card('1', 'Cat', 'A small pet'),
    card('2', 'Dog', 'A loyal pet'),
    card('3', 'Cow', 'Gives milk'),
    card('4', 'Hen', 'Lays eggs'),
    card('5', 'Pig', 'Lives on a farm'),
  ];

  group('answersMatch', () {
    test('ignores case, spacing and trailing punctuation', () {
      expect(answersMatch('  A  Small PET. ', 'a small pet'), isTrue);
    });
    test('different answers do not match', () {
      expect(answersMatch('a big pet', 'a small pet'), isFalse);
    });
  });

  group('buildQuiz', () {
    test('asks about every card once', () {
      final q = buildQuiz(cards, random: Random(1));
      expect(q.map((e) => e.card.id).toSet(), cards.map((c) => c.id).toSet());
      expect(q.length, cards.length);
    });

    test(
      'multiple choice has the answer plus up to three distinct wrong ones',
      () {
        final q = buildQuiz(cards, written: false, random: Random(2));
        for (final question in q) {
          expect(question.type, QuestionType.multipleChoice);
          expect(question.options.length, 4);
          expect(question.options.toSet().length, 4);
          expect(question.options, contains(question.answer));
        }
      },
    );

    test('mixed mode produces both kinds', () {
      final types = buildQuiz(
        cards,
        random: Random(3),
      ).map((e) => e.type).toSet();
      expect(types, {QuestionType.multipleChoice, QuestionType.written});
    });

    test('a single card falls back to a written question', () {
      final q = buildQuiz([cards.first], written: false);
      expect(q.single.type, QuestionType.written);
    });

    test(
      'cards with identical definitions are not offered as wrong answers',
      () {
        final twins = [card('a', 'X', 'Same'), card('b', 'Y', 'Same')];
        final q = buildQuiz(twins, written: false);
        expect(q.every((e) => e.type == QuestionType.written), isTrue);
      },
    );

    test('count limits the number of questions', () {
      expect(buildQuiz(cards, count: 2).length, 2);
    });

    test('isCorrect accepts the right written answer only', () {
      final q = buildQuiz(
        [cards.first],
        written: true,
        multipleChoice: false,
      ).single;
      expect(q.isCorrect('a small pet'), isTrue);
      expect(q.isCorrect('nope'), isFalse);
    });
  });
}
