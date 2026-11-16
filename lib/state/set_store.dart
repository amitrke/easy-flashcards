import 'package:flutter/foundation.dart';

import '../data/set_repository.dart';
import '../models/study_set.dart';

class SetStore extends ChangeNotifier {
  SetStore(this._repository);

  final SetRepository _repository;
  List<StudySet> _sets = [];
  bool _loaded = false;

  bool get loaded => _loaded;

  /// Newest first.
  List<StudySet> get sets => List.unmodifiable(_sets);

  StudySet? byId(String id) {
    for (final s in _sets) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> load() async {
    _sets = await _repository.loadAll();
    _sort();
    _loaded = true;
    notifyListeners();
  }

  Future<void> upsert(StudySet set) async {
    final i = _sets.indexWhere((s) => s.id == set.id);
    if (i >= 0) {
      _sets[i] = set;
    } else {
      _sets.add(set);
    }
    _sort();
    notifyListeners();
    await _repository.saveAll(_sets);
  }

  Future<void> delete(String id) async {
    _sets.removeWhere((s) => s.id == id);
    notifyListeners();
    await _repository.saveAll(_sets);
  }

  void _sort() => _sets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
}
