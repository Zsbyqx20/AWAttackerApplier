import 'package:flutter/foundation.dart';
import '../models/rule.dart';
import '../repositories/rule_repository.dart';

class RuleProvider extends ChangeNotifier {
  final RuleRepository _repository;
  List<Rule> _rules = [];
  bool _isLoading = false;
  String? _error;

  RuleProvider(this._repository);

  List<Rule> get rules => List.unmodifiable(_rules);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rules = await _repository.loadRules();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading rules: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRule(Rule rule) async {
    try {
      await _repository.addRule(rule);
      _rules.add(rule);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error adding rule: $e');
      }
      rethrow;
    }
  }

  Future<void> updateRule(Rule rule) async {
    try {
      await _repository.updateRule(rule);
      final index = _rules.indexWhere((r) => r.id == rule.id);
      if (index != -1) {
        _rules[index] = rule;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating rule: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteRule(String ruleId) async {
    try {
      await _repository.deleteRule(ruleId);
      _rules = await _repository.loadRules();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error deleting rule: $e');
      }
      rethrow;
    }
  }

  Future<void> toggleRuleState(Rule rule) async {
    try {
      final updatedRule = rule.copyWith(isEnabled: !rule.isEnabled);
      await _repository.updateRule(updatedRule);
      final index = _rules.indexWhere((r) => r.id == rule.id);
      if (index != -1) {
        _rules[index] = updatedRule;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error toggling rule state: $e');
      }
      rethrow;
    }
  }
}
