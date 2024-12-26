import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rule.dart';
import 'package:flutter/foundation.dart';

class RuleRepository {
  static const String _storageKey = 'rules';
  final SharedPreferences _prefs;

  RuleRepository(this._prefs);

  Future<List<Rule>> loadRules() async {
    final String? rulesJson = _prefs.getString(_storageKey);
    if (rulesJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(rulesJson);
      return decoded.map((json) => Rule.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading rules: $e');
      }
      return [];
    }
  }

  Future<void> addRule(Rule rule) async {
    final rules = await loadRules();
    rules.add(rule);
    await _saveRules(rules);
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
