import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/set_store.dart';
import 'quiz_screen.dart';
import 'set_editor_screen.dart';
import 'study_screen.dart';

class SetDetailScreen extends StatelessWidget {
  const SetDetailScreen({super.key, required this.setId});

  final String setId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SetStore>();
    final set = store.byId(setId);
    if (set == null) {
      // Deleted while open.
      return const Scaffold(body: Center(child: Text('This set no longer exists.')));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(set.title),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SetEditorScreen(existing: set)),
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete this set?'),
                  content: Text('"${set.title}" and its ${set.cards.length} cards will be removed.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await store.delete(set.id);
                navigator.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (set.description.isNotEmpty) ...[
            Text(set.description),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.style_outlined),
                  label: const Text('Flashcards'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => StudyScreen(set: set)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text('Quiz'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => QuizScreen(set: set)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('${set.cards.length} cards', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final c in set.cards)
            Card(
              child: ListTile(title: Text(c.term), subtitle: Text(c.definition)),
            ),
        ],
      ),
    );
  }
}
