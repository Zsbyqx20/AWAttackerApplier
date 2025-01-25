import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

class StorageRepository {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<Set<String>> loadActiveTags() async {
    if (_prefs == null) throw Exception('Storage not initialized');

    final prefs = _prefs;
    if (prefs == null) return {};

    final json = prefs.getString(StorageKeys.activeTagsKey);
    if (json == null) return {};

    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return {};

      return decoded.map((e) => e as String).toSet();
    } catch (e) {
      return {};
    }
  }

  Future<void> saveActiveTags(Set<String> tags) async {
    if (_prefs == null) throw Exception('Storage not initialized');

    final prefs = _prefs;
    if (prefs == null) return;

    final json = jsonEncode(tags.toList());
    await prefs.setString(StorageKeys.activeTagsKey, json);
  }
}
