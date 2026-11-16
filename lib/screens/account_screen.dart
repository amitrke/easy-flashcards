import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../account/account_service.dart';
import '../state/set_store.dart';

/// Optional sign-in. Signing in backs the sets up to the cloud and syncs them
/// across devices; signing out keeps them on this device.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      _error = 'That did not work. Please try again.';
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _confirmDelete(AccountService account) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This deletes your account and the cloud copy of your sets. '
          'Sets stay on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await _run(account.deleteAccount);
  }

  @override
  Widget build(BuildContext context) {
    final account = context.read<AccountService?>()!;
    final store = context.watch<SetStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: StreamBuilder<AccountUser?>(
        stream: account.userChanges,
        initialData: account.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (user == null) ...[
                const Text(
                  'You do not need an account. Sign in only if you want your '
                  'sets backed up and available on your other devices.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() => account.signIn(SignInMethod.google)),
                  icon: const Icon(Icons.login),
                  label: const Text('Continue with Google'),
                ),
                if (account.appleAvailable) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(() => account.signIn(SignInMethod.apple)),
                    icon: const Icon(Icons.apple),
                    label: const Text('Continue with Apple'),
                  ),
                ],
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: Text(user.displayName ?? user.email ?? 'Signed in'),
                  subtitle: Text(
                    store.syncing
                        ? 'Syncing...'
                        : (store.syncError ?? 'Your sets are synced'),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(account.signOut),
                  child: const Text('Sign out'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : () => _confirmDelete(account),
                  child: const Text('Delete account'),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://easy-flashcards-quiz.web.app/privacy.html',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text('Privacy policy'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
