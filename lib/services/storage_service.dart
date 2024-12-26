import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../constants/storage_keys.dart';
import '../models/rule.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;
  List<Rule>? _cachedRules;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 通用存储方法
  Future<bool> _setValue(String key, dynamic value) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();

    if (value is String) {
      return await prefs.setString(key, value);
    } else if (value is int) {
      return await prefs.setInt(key, value);
    } else if (value is double) {
      return await prefs.setDouble(key, value);
    } else if (value is bool) {
      return await prefs.setBool(key, value);
    } else if (value is List<String>) {
      return await prefs.setStringList(key, value);
    } else {
      final jsonString = json.encode(value);
      return await prefs.setString(key, jsonString);
    }
  }

  // 通用读取方法
  T? _getValue<T>(String key) {
    final prefs = _prefs;
    if (prefs == null) return null;

    final value = prefs.get(key);
    if (value == null) return null;

    return value as T;
  }

  // 服务器配置相关方法
  Future<void> saveUrls({
    required String apiUrl,
    required String wsUrl,
  }) async {
    await _setValue(StorageKeys.apiUrlKey, apiUrl);
    await _setValue(StorageKeys.wsUrlKey, wsUrl);
  }

  Future<Map<String, String>> loadUrls() async {
    final apiUrl = _getValue<String>(StorageKeys.apiUrlKey);
    final wsUrl = _getValue<String>(StorageKeys.wsUrlKey);

    return {
      StorageKeys.apiUrlKey: apiUrl ?? 'http://10.0.2.2:8000',
      StorageKeys.wsUrlKey: wsUrl ?? 'ws://10.0.2.2:8000/ws',
    };
  }

  // 规则相关方法
  Future<void> saveRules(List<Rule> rules) async {
    try {
      final rulesJson = rules.map((rule) => rule.toJson()).toList();
      await _setValue(StorageKeys.rulesKey, rulesJson);
      await _setValue(
          StorageKeys.lastRuleUpdateKey, DateTime.now().toIso8601String());
      _cachedRules = List.from(rules);

      if (kDebugMode) {
        print('StorageService: Saved ${rules.length} rules');
      }
    } catch (e) {
      if (kDebugMode) {
        print('StorageService: Error saving rules - $e');
      }
      rethrow;
    }
  }

  Future<List<Rule>> loadRules() async {
    try {
      if (_cachedRules != null) {
        return List.from(_cachedRules!);
      }

      final jsonString = _getValue<String>(StorageKeys.rulesKey);
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      final rules = jsonList
          .map((json) => Rule.fromJson(json as Map<String, dynamic>))
          .toList();

      _cachedRules = List.from(rules);

      if (kDebugMode) {
        print('StorageService: Loaded ${rules.length} rules');
      }

      return rules;
    } catch (e) {
      if (kDebugMode) {
        print('StorageService: Error loading rules - $e');
      }
      return [];
    }
  }

  // 缓存管理
  void clearRuleCache() {
    _cachedRules = null;
  }

  Future<void> clearAll() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.clear();
    clearRuleCache();
  }
}
