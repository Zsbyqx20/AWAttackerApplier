import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import 'dart:convert';

class StorageRepository {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<Set<String>> loadActiveTags() async {
    if (_prefs == null) throw Exception('Storage not initialized');

    final json = _prefs!.getString(StorageKeys.activeTagsKey);
    if (json == null) return {};

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => e as String).toSet();
    } catch (e) {
      return {};
    }
  }

  Future<void> saveActiveTags(Set<String> tags) async {
    if (_prefs == null) throw Exception('Storage not initialized');

    final json = jsonEncode(tags.toList());
    await _prefs!.setString(StorageKeys.activeTagsKey, json);
  }
}
