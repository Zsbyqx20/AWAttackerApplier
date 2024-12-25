import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_flutter/constants/storage_keys.dart';

class StorageService {
  static Future<void> saveUrls({
    required String apiUrl,
    required String wsUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.apiUrlKey, apiUrl);
    await prefs.setString(StorageKeys.wsUrlKey, wsUrl);
  }

  static Future<Map<String, String>> loadUrls() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      StorageKeys.apiUrlKey:
          prefs.getString(StorageKeys.apiUrlKey) ?? 'http://10.0.2.2:8000',
      StorageKeys.wsUrlKey:
          prefs.getString(StorageKeys.wsUrlKey) ?? 'ws://10.0.2.2:8000/ws',
    };
  }
}
