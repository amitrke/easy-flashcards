import 'dart:async';

import '../models/study_set.dart';

/// The signed-in person, if any. Signing in is optional: without it the app
/// works entirely on the device.
class AccountUser {
  const AccountUser({required this.uid, this.email, this.displayName});
  final String uid;
  final String? email;
  final String? displayName;
}

enum SignInMethod { google, apple }

/// Sign-in plus the cloud copy of the signed-in user's sets.
abstract class AccountService {
  AccountUser? get currentUser;
  Stream<AccountUser?> get userChanges;
  bool get appleAvailable;

  Future<void> signIn(SignInMethod method);
  Future<void> signOut();

  /// Deletes the cloud data and the account itself (required by both stores).
  Future<void> deleteAccount();

  Future<List<StudySet>> fetchSets();
  Future<void> putSet(StudySet set);
  Future<void> removeSet(String id);
}

/// Merges local and cloud sets by id; the newer `updatedAt` wins.
List<StudySet> mergeSets(List<StudySet> local, List<StudySet> cloud) {
  final byId = <String, StudySet>{for (final s in local) s.id: s};
  for (final c in cloud) {
    final existing = byId[c.id];
    if (existing == null || c.updatedAt.isAfter(existing.updatedAt)) {
      byId[c.id] = c;
    }
  }
  return byId.values.toList();
}
