import 'dart:async';

import 'package:flutter/foundation.dart';

import '../account/account_service.dart';
import '../data/set_repository.dart';
import '../models/study_set.dart';

class SetStore extends ChangeNotifier {
  SetStore(this._repository, {AccountService? account}) : _account = account {
    _userSub = account?.userChanges.listen((_) => sync());
  }

  final SetRepository _repository;
  final AccountService? _account;
  StreamSubscription<AccountUser?>? _userSub;
  bool _syncing = false;
  String? _syncError;

  /// The last cloud error, or null. Local data is never lost to a sync error.
  String? get syncError => _syncError;
  bool get syncing => _syncing;
  bool get signedIn => _account?.currentUser != null;
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
    await sync();
  }

  /// Merges this device's sets with the signed-in account's cloud copy.
  Future<void> sync() async {
    final account = _account;
    if (account == null || account.currentUser == null || !_loaded) return;
    _syncing = true;
    _syncError = null;
    notifyListeners();
    try {
      final cloud = await account.fetchSets();
      final merged = mergeSets(_sets, cloud);
      final cloudById = {for (final c in cloud) c.id: c};
      for (final s in merged) {
        final c = cloudById[s.id];
        if (c == null || s.updatedAt.isAfter(c.updatedAt)) {
          await account.putSet(s);
        }
      }
      _sets = merged;
      _sort();
      await _repository.saveAll(_sets);
    } catch (e) {
      _syncError = 'Could not sync. Your sets are safe on this device.';
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> _mirror(Future<void> Function(AccountService a) op) async {
    final account = _account;
    if (account == null || account.currentUser == null) return;
    try {
      await op(account);
      _syncError = null;
    } catch (_) {
      _syncError = 'Could not sync. Your sets are safe on this device.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
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
    await _mirror((a) => a.putSet(set));
  }

  Future<void> delete(String id) async {
    _sets.removeWhere((s) => s.id == id);
    notifyListeners();
    await _repository.saveAll(_sets);
    await _mirror((a) => a.removeSet(id));
  }

  void _sort() => _sets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
}
