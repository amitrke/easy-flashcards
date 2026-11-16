import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/study_set.dart';
import '../state/set_store.dart';

/// Creates a new set, or edits [existing].
class SetEditorScreen extends StatefulWidget {
  const SetEditorScreen({super.key, this.existing});

  final StudySet? existing;

  @override
  State<SetEditorScreen> createState() => _SetEditorScreenState();
}

class _CardDraft {
  _CardDraft({String? id, String term = '', String definition = ''})
    : id = id ?? const Uuid().v4(),
      term = TextEditingController(text: term),
      definition = TextEditingController(text: definition);

  final String id;
  final TextEditingController term;
  final TextEditingController definition;

  void dispose() {
    term.dispose();
    definition.dispose();
  }
}

class _SetEditorScreenState extends State<SetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final List<_CardDraft> _cards;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _title = TextEditingController(text: s?.title ?? '');
    _description = TextEditingController(text: s?.description ?? '');
    _cards = [
      for (final c in s?.cards ?? const <Flashcard>[])
        _CardDraft(id: c.id, term: c.term, definition: c.definition),
    ];
    while (_cards.length < 2) {
      _cards.add(_CardDraft());
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final c in _cards) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cards = [
      for (final c in _cards)
        if (c.term.text.trim().isNotEmpty &&
            c.definition.text.trim().isNotEmpty)
          Flashcard(
            id: c.id,
            term: c.term.text.trim(),
            definition: c.definition.text.trim(),
          ),
    ];
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one card with a term and a definition.'),
        ),
      );
      return;
    }
    final existing = widget.existing;
    final set = StudySet(
      id: existing?.id ?? const Uuid().v4(),
      title: _title.text.trim(),
      description: _description.text.trim(),
      cards: cards,
      updatedAt: DateTime.now(),
    );
    final store = context.read<SetStore>();
    final navigator = Navigator.of(context);
    await store.upsert(set);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New set' : 'Edit set'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Give the set a title'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 24),
            Text('Cards', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < _cards.length; i++)
              Card(
                key: ValueKey(_cards[i].id),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TextField(
                              controller: _cards[i].term,
                              decoration: InputDecoration(
                                labelText: 'Term ${i + 1}',
                              ),
                            ),
                            TextField(
                              controller: _cards[i].definition,
                              decoration: const InputDecoration(
                                labelText: 'Definition',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove card',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _cards.length <= 1
                            ? null
                            : () =>
                                  setState(() => _cards.removeAt(i).dispose()),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _cards.add(_CardDraft())),
              icon: const Icon(Icons.add),
              label: const Text('Add card'),
            ),
          ],
        ),
      ),
    );
  }
}
