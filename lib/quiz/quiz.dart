import 'dart:math';

import '../models/study_set.dart';

enum QuestionType { multipleChoice, written }

class QuizQuestion {
  const QuizQuestion({
    required this.card,
    required this.type,
    this.options = const [],
  });

  final Flashcard card;
  final QuestionType type;

  /// Shuffled answer choices; only used for multiple choice.
  final List<String> options;

  String get prompt => card.term;
  String get answer => card.definition;

  bool isCorrect(String given) => answersMatch(given, answer);
}

/// Case, spacing and trailing punctuation do not make a written answer wrong.
bool answersMatch(String a, String b) => _normalize(a) == _normalize(b);

String _normalize(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim()
    .replaceAll(RegExp(r'[.!?,;:]+$'), '');

/// Builds a shuffled quiz from [cards].
///
/// With both types enabled, questions alternate. A multiple choice question
/// needs at least one distinct wrong answer; otherwise it becomes a written
/// question. [count] limits the number of questions.
List<QuizQuestion> buildQuiz(
  List<Flashcard> cards, {
  bool multipleChoice = true,
  bool written = true,
  int? count,
  Random? random,
}) {
  assert(multipleChoice || written, 'enable at least one question type');
  final rng = random ?? Random();
  final shuffled = [...cards]..shuffle(rng);
  final picked = count == null ? shuffled : shuffled.take(count).toList();

  final questions = <QuizQuestion>[];
  for (var i = 0; i < picked.length; i++) {
    final card = picked[i];
    final wantMc = multipleChoice && (!written || i.isEven);
    if (wantMc) {
      final wrong =
          cards
              .where(
                (c) =>
                    c.id != card.id &&
                    !answersMatch(c.definition, card.definition),
              )
              .map((c) => c.definition)
              .toSet()
              .toList()
            ..shuffle(rng);
      if (wrong.isNotEmpty) {
        final options = [card.definition, ...wrong.take(3)]..shuffle(rng);
        questions.add(
          QuizQuestion(
            card: card,
            type: QuestionType.multipleChoice,
            options: options,
          ),
        );
        continue;
      }
    }
    questions.add(QuizQuestion(card: card, type: QuestionType.written));
  }
  return questions;
}
