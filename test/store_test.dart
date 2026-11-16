import 'package:basicflashcards/data/set_repository.dart';
import 'package:basicflashcards/models/study_set.dart';
import 'package:basicflashcards/state/set_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

StudySet makeSet(String id, String title, DateTime at) => StudySet(
      id: id,
      title: title,
      cards: const [Flashcard(id: 'c1', term: 'T', definition: 'D')],
      updatedAt: at,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('JSON round trip keeps every field', () {
    final s = makeSet('1', 'Animals', DateTime.utc(2026, 1, 2));
    final back = StudySet.fromJson(s.toJson());
    expect(back.title, 'Animals');
    expect(back.cards.single.definition, 'D');
    expect(back.updatedAt, DateTime.utc(2026, 1, 2));
  });

  test('sets persist across store instances, newest first', () async {
    final repo = LocalSetRepository();
    final store = SetStore(repo);
    await store.load();
    await store.upsert(makeSet('old', 'Old', DateTime.utc(2026, 1, 1)));
    await store.upsert(makeSet('new', 'New', DateTime.utc(2026, 6, 1)));

    final reopened = SetStore(LocalSetRepository());
    await reopened.load();
    expect(reopened.sets.map((s) => s.id), ['new', 'old']);
  });

  test('upsert replaces by id and delete removes', () async {
    final store = SetStore(LocalSetRepository());
    await store.load();
    await store.upsert(makeSet('a', 'First', DateTime.utc(2026, 1, 1)));
    await store.upsert(makeSet('a', 'Renamed', DateTime.utc(2026, 2, 1)));
    expect(store.sets.length, 1);
    expect(store.byId('a')!.title, 'Renamed');
    await store.delete('a');
    expect(store.sets, isEmpty);
  });

  test('corrupt stored data loads as empty instead of crashing', () async {
    SharedPreferences.setMockInitialValues({'study_sets_v1': 'not json'});
    final store = SetStore(LocalSetRepository());
    await store.load();
    expect(store.sets, isEmpty);
    expect(store.loaded, isTrue);
  });
}
