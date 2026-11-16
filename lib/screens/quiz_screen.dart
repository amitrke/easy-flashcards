import 'package:flutter/material.dart';

import '../models/study_set.dart';
import '../quiz/quiz.dart';

/// A test built from a set: multiple choice and written questions.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.set});

  final StudySet set;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuizQuestion> _questions;
  int _index = 0;
  int _correct = 0;
  final _missed = <QuizQuestion>[];

  /// Set once the current question has been answered.
  String? _given;
  bool? _wasCorrect;
  final _written = TextEditingController();

  @override
  void initState() {
    super.initState();
    _questions = buildQuiz(widget.set.cards);
  }

  @override
  void dispose() {
    _written.dispose();
    super.dispose();
  }

  bool get _finished => _index >= _questions.length;
  bool get _answered => _wasCorrect != null;

  void _answer(String given) {
    if (_answered) return;
    final q = _questions[_index];
    final ok = q.isCorrect(given);
    setState(() {
      _given = given;
      _wasCorrect = ok;
      if (ok) {
        _correct++;
      } else {
        _missed.add(q);
      }
    });
  }

  void _next() {
    setState(() {
      _index++;
      _given = null;
      _wasCorrect = null;
      _written.clear();
    });
  }

  void _retake() {
    setState(() {
      _questions = buildQuiz(widget.set.cards);
      _index = 0;
      _correct = 0;
      _missed.clear();
      _given = null;
      _wasCorrect = null;
      _written.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz: ${widget.set.title}')),
      body: SafeArea(child: _finished ? _results(context) : _question(context)),
    );
  }

  Widget _question(BuildContext context) {
    final q = _questions[_index];
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LinearProgressIndicator(value: _index / _questions.length),
        const SizedBox(height: 8),
        Text('Question ${_index + 1} of ${_questions.length}'),
        const SizedBox(height: 24),
        Text(q.prompt, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        if (q.type == QuestionType.multipleChoice)
          for (final option in q.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(16),
                  backgroundColor: !_answered
                      ? null
                      : option == q.answer
                      ? Colors.green.withValues(alpha: 0.2)
                      : option == _given
                      ? scheme.errorContainer
                      : null,
                ),
                onPressed: _answered ? null : () => _answer(option),
                child: Text(option),
              ),
            )
        else ...[
          TextField(
            controller: _written,
            enabled: !_answered,
            decoration: const InputDecoration(labelText: 'Your answer'),
            onSubmitted: (v) => v.trim().isEmpty ? null : _answer(v),
          ),
          const SizedBox(height: 12),
          if (!_answered)
            FilledButton(
              onPressed: () {
                if (_written.text.trim().isNotEmpty) _answer(_written.text);
              },
              child: const Text('Check'),
            ),
        ],
        if (_answered) ...[
          const SizedBox(height: 16),
          Text(
            _wasCorrect! ? 'Correct!' : 'Not quite. The answer is: ${q.answer}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _wasCorrect! ? Colors.green.shade700 : scheme.error,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _next,
            child: Text(
              _index + 1 == _questions.length ? 'See results' : 'Next',
            ),
          ),
        ],
      ],
    );
  }

  Widget _results(BuildContext context) {
    final total = _questions.length;
    final percent = total == 0 ? 0 : (_correct * 100 / total).round();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Text(
            '$percent%',
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ),
        Center(child: Text('$_correct of $total correct')),
        const SizedBox(height: 24),
        if (_missed.isNotEmpty) ...[
          Text('To review', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final q in _missed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(q.prompt),
              subtitle: Text(q.answer),
            ),
          const SizedBox(height: 16),
        ],
        FilledButton(onPressed: _retake, child: const Text('Take it again')),
      ],
    );
  }
}
