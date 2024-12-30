import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rule.dart';
import 'package:flutter/foundation.dart';

class RuleRepository {
  static const String _storageKey = 'rules';
  final SharedPreferences _prefs;

  RuleRepository(this._prefs);

  Future<List<Rule>> loadRules() async {
    try {
      final String? rulesJson = _prefs.getString(_storageKey);
      if (rulesJson == null) return [];

      final List<dynamic> decoded = jsonDecode(rulesJson);
      if (decoded.isEmpty) return [];

      // 验证解码后的数据是否为有效的规则列表
      if (decoded.any((item) => item is! Map<String, dynamic>)) {
        if (kDebugMode) {
          debugPrint('Invalid rule data format, clearing storage');
        }
        await _prefs.remove(_storageKey);
        return [];
      }

      return decoded
          .map((json) => Rule.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading rules: $e');
      }
      // 清除无效的数据
      await _prefs.remove(_storageKey);
      return [];
    }
  }

  Future<Rule> addRule(Rule rule) async {
    final rules = await loadRules();
    rules.add(rule);
    await _saveRules(rules);
    return rule;
  }

  Future<void> updateRule(Rule rule) async {
    final rules = await loadRules();
    final index = rules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      rules[index] = rule;
      await _saveRules(rules);
    }
  }

  Future<void> deleteRule(String ruleId) async {
    final rules = await loadRules();
    rules.removeWhere((rule) => rule.id == ruleId);
    await _saveRules(rules);
  }

  Future<void> _saveRules(List<Rule> rules) async {
    final String rulesJson =
        jsonEncode(rules.map((rule) => rule.toJson()).toList());
    await _prefs.setString(_storageKey, rulesJson);
  }
}
