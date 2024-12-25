import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_flutter/models/rule.dart';

class RuleStorage {
  static const String _key = 'rules';

  static Future<List<Rule>> loadRules() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rulesJson = prefs.getString(_key);
    if (rulesJson == null) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(rulesJson);
      return decoded.map((json) => Rule.fromJson(json)).toList();
    } catch (e) {
      print('Error loading rules: $e');
      return [];
    }
  }

  static Future<void> saveRules(List<Rule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    final String rulesJson =
        jsonEncode(rules.map((rule) => rule.toJson()).toList());
    await prefs.setString(_key, rulesJson);
  }
}
