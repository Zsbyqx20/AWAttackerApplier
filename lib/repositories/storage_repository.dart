import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import 'dart:convert';

class StorageRepository {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<Map<String, String>> loadUrls() async {
    if (_prefs == null) throw Exception('Storage not initialized');
    return {
      StorageKeys.apiUrlKey:
          _prefs!.getString(StorageKeys.apiUrlKey) ?? 'http://10.0.2.2:8000',
      StorageKeys.wsUrlKey:
          _prefs!.getString(StorageKeys.wsUrlKey) ?? 'ws://10.0.2.2:8000/ws',
    };
  }

  Future<void> saveUrls({
    required String apiUrl,
    required String wsUrl,
  }) async {
    if (_prefs == null) throw Exception('Storage not initialized');
    await _prefs!.setString(StorageKeys.apiUrlKey, apiUrl);
    await _prefs!.setString(StorageKeys.wsUrlKey, wsUrl);
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
