import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../account/account_service.dart';
import '../state/set_store.dart';
import 'account_screen.dart';
import 'set_detail_screen.dart';
import 'set_editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SetStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Easy Flashcards & Quiz'),
        actions: [
          if (context.read<AccountService?>() != null)
            IconButton(
              tooltip: 'Account',
              icon: Icon(
                store.signedIn
                    ? Icons.account_circle
                    : Icons.account_circle_outlined,
              ),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AccountScreen())),
            ),
        ],
      ),
      body: !store.loaded
          ? const Center(child: CircularProgressIndicator())
          : store.sets.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: store.sets.length,
              itemBuilder: (context, i) {
                final s = store.sets[i];
                return Card(
                  child: ListTile(
                    title: Text(s.title),
                    subtitle: Text(
                      s.cards.length == 1
                          ? '1 card'
                          : '${s.cards.length} cards',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SetDetailScreen(setId: s.id),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SetEditorScreen())),
        icon: const Icon(Icons.add),
        label: const Text('New set'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.style_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No study sets yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a set of terms and definitions, then flip through the cards or take a quiz.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
