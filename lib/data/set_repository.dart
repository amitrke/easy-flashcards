import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_set.dart';

/// Where study sets are persisted. The app only talks to this interface, so a
/// cloud-backed implementation (Firebase) can be added later without touching
/// the screens.
abstract class SetRepository {
  Future<List<StudySet>> loadAll();
  Future<void> saveAll(List<StudySet> sets);
}

/// Stores every set as one JSON string on the device.
class LocalSetRepository implements SetRepository {
  static const _key = 'study_sets_v1';

  @override
  Future<List<StudySet>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => StudySet.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      // Corrupt data: start empty instead of crashing on launch.
      return [];
    }
  }

  @override
  Future<void> saveAll(List<StudySet> sets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(sets.map((s) => s.toJson()).toList()),
    );
  }
}
