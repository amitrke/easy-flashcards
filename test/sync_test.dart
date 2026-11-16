import 'dart:async';

import 'package:basicflashcards/account/account_service.dart';
import 'package:basicflashcards/data/set_repository.dart';
import 'package:basicflashcards/models/study_set.dart';
import 'package:basicflashcards/state/set_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAccount implements AccountService {
  final _controller = StreamController<AccountUser?>.broadcast();
  AccountUser? _user;
  final cloud = <String, StudySet>{};

  @override
  AccountUser? get currentUser => _user;
  @override
  Stream<AccountUser?> get userChanges => _controller.stream;
  @override
  bool get appleAvailable => false;

  @override
  Future<void> signIn(SignInMethod method) async {
    _user = const AccountUser(uid: 'u1');
    _controller.add(_user);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async => cloud.clear();
  @override
  Future<List<StudySet>> fetchSets() async => cloud.values.toList();
  @override
  Future<void> putSet(StudySet set) async => cloud[set.id] = set;
  @override
  Future<void> removeSet(String id) async => cloud.remove(id);
}

StudySet makeSet(String id, String title, DateTime at) => StudySet(
  id: id,
  title: title,
  cards: const [Flashcard(id: 'c', term: 'T', definition: 'D')],
  updatedAt: at,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('mergeSets keeps the newer copy and the union of ids', () {
    final merged = mergeSets(
      [
        makeSet('a', 'Local A', DateTime.utc(2026, 2, 1)),
        makeSet('b', 'B', DateTime.utc(2026, 1, 1)),
      ],
      [
        makeSet('a', 'Cloud A', DateTime.utc(2026, 3, 1)),
        makeSet('c', 'C', DateTime.utc(2026, 1, 1)),
      ],
    );
    expect(merged.map((s) => s.id).toSet(), {'a', 'b', 'c'});
    expect(merged.firstWhere((s) => s.id == 'a').title, 'Cloud A');
  });

  test('signed out: nothing reaches the cloud', () async {
    final account = FakeAccount();
    final store = SetStore(LocalSetRepository(), account: account);
    await store.load();
    await store.upsert(makeSet('a', 'A', DateTime.utc(2026, 1, 1)));
    expect(account.cloud, isEmpty);
  });

  test('signing in uploads local sets and downloads cloud ones', () async {
    final account = FakeAccount();
    account.cloud['x'] = makeSet('x', 'From cloud', DateTime.utc(2026, 1, 1));
    final store = SetStore(LocalSetRepository(), account: account);
    await store.load();
    await store.upsert(makeSet('a', 'Local', DateTime.utc(2026, 2, 1)));

    await account.signIn(SignInMethod.google);
    await pumpEventQueue();

    expect(account.cloud.keys.toSet(), {'a', 'x'});
    expect(store.sets.map((s) => s.id).toSet(), {'a', 'x'});
  });

  test(
    'signed in: edits and deletes are mirrored; sign-out keeps local',
    () async {
      final account = FakeAccount();
      await account.signIn(SignInMethod.google);
      final store = SetStore(LocalSetRepository(), account: account);
      await store.load();
      await store.upsert(makeSet('a', 'A', DateTime.utc(2026, 1, 1)));
      expect(account.cloud.containsKey('a'), isTrue);
      await store.delete('a');
      expect(account.cloud, isEmpty);

      await store.upsert(makeSet('b', 'B', DateTime.utc(2026, 1, 1)));
      await account.signOut();
      await pumpEventQueue();
      expect(store.sets.single.id, 'b');
    },
  );
}
