import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

class StorageRepository {
  late final SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  Future<Map<String, String>> loadUrls() async {
    if (!_initialized) await init();
    return {
      StorageKeys.apiUrlKey:
          _prefs.getString(StorageKeys.apiUrlKey) ?? 'http://10.0.2.2:8000',
      StorageKeys.wsUrlKey:
          _prefs.getString(StorageKeys.wsUrlKey) ?? 'ws://10.0.2.2:8000/ws',
    };
  }

  Future<void> saveUrls({
    required String apiUrl,
    required String wsUrl,
  }) async {
    if (!_initialized) await init();
    await _prefs.setString(StorageKeys.apiUrlKey, apiUrl);
    await _prefs.setString(StorageKeys.wsUrlKey, wsUrl);
  }
}
