import 'package:flutter/material.dart';

import '../models/study_set.dart';

/// Flip through cards; mark each "Got it" or "Still learning".
class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.set});

  final StudySet set;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  late List<Flashcard> _deck;
  int _index = 0;
  bool _showDefinition = false;
  final _stillLearning = <Flashcard>[];
  int _known = 0;

  @override
  void initState() {
    super.initState();
    _deck = [...widget.set.cards];
  }

  bool get _finished => _index >= _deck.length;

  void _mark(bool knew) {
    setState(() {
      if (knew) {
        _known++;
      } else {
        _stillLearning.add(_deck[_index]);
      }
      _index++;
      _showDefinition = false;
    });
  }

  void _restart(List<Flashcard> deck) {
    setState(() {
      _deck = [...deck];
      _index = 0;
      _known = 0;
      _stillLearning.clear();
      _showDefinition = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.set.title)),
      body: SafeArea(child: _finished ? _summary(context) : _card(context)),
    );
  }

  Widget _card(BuildContext context) {
    final card = _deck[_index];
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LinearProgressIndicator(value: _index / _deck.length),
          const SizedBox(height: 8),
          Text('${_index + 1} of ${_deck.length}'),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showDefinition = !_showDefinition),
              child: Card(
                color: _showDefinition ? scheme.secondaryContainer : scheme.primaryContainer,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showDefinition ? 'Definition' : 'Term',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _showDefinition ? card.definition : card.term,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 24),
                        Text('Tap to flip', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _mark(false),
                  child: const Text('Still learning'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _mark(true),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summary(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Round complete', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text('Got it: $_known   Still learning: ${_stillLearning.length}'),
            const SizedBox(height: 24),
            if (_stillLearning.isNotEmpty)
              FilledButton(
                onPressed: () => _restart(List.of(_stillLearning)),
                child: Text('Study the ${_stillLearning.length} you missed'),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _restart(widget.set.cards),
              child: const Text('Start over'),
            ),
          ],
        ),
      ),
    );
  }
}
