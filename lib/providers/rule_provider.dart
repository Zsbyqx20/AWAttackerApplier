import 'package:flutter/foundation.dart';
import '../models/rule.dart';
import '../repositories/rule_repository.dart';
import '../repositories/storage_repository.dart';
import '../exceptions/tag_activation_exception.dart';

class RuleProvider extends ChangeNotifier {
  final RuleRepository _repository;
  final StorageRepository _storageRepository;
  List<Rule> _rules = [];
  Set<String> _activeTags = {};
  bool _isLoading = false;
  String? _error;

  RuleProvider(this._repository) : _storageRepository = StorageRepository();

  List<Rule> get rules => List.unmodifiable(_rules);
  Set<String> get activeTags => Set.unmodifiable(_activeTags);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 获取所有已使用的标签
  Set<String> get allTags {
    final tagSet = <String>{};
    for (final rule in _rules) {
      tagSet.addAll(rule.tags);
    }
    return tagSet;
  }

  // 获取标签关联的规则
  List<Rule> getRulesByTag(String tag) {
    return _rules.where((rule) => rule.tags.contains(tag)).toList();
  }

  // 获取激活标签关联的规则
  List<Rule> getRulesByActiveTags() {
    if (_activeTags.isEmpty) return [];
    return _rules
        .where((rule) => rule.tags.any((tag) => _activeTags.contains(tag)))
        .toList();
  }

  // 检查标签是否激活
  bool isTagActive(String tag) => _activeTags.contains(tag);

  // 加载激活的标签
  Future<void> loadActiveTags() async {
    try {
      await _storageRepository.init();
      _activeTags = await _storageRepository.loadActiveTags();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading active tags: $e');
      }
    }
  }

  // 激活标签
  Future<void> activateTag(String tag) async {
    if (!allTags.contains(tag)) {
      throw TagActivationException.notFound(tag);
    }
    if (_activeTags.contains(tag)) {
      throw TagActivationException.alreadyActive(tag);
    }

    try {
      _activeTags.add(tag);
      await _storageRepository.saveActiveTags(_activeTags);

      // 更新包含该标签的规则状态
      for (final rule in _rules.where((r) => r.tags.contains(tag))) {
        if (!rule.isEnabled) {
          final updatedRule = rule.copyWith(isEnabled: true);
          await _repository.updateRule(updatedRule);
          final index = _rules.indexWhere((r) => r.id == rule.id);
          if (index != -1) {
            _rules[index] = updatedRule;
          }
        }
      }

      notifyListeners();
    } catch (e) {
      _activeTags.remove(tag);
      throw TagActivationException.storageError();
    }
  }

  // 反激活标签
  Future<void> deactivateTag(String tag) async {
    if (!_activeTags.contains(tag)) {
      throw TagActivationException.notActive(tag);
    }

    try {
      _activeTags.remove(tag);
      await _storageRepository.saveActiveTags(_activeTags);

      // 更新包含该标签的规则状态
      // 只有当规则的所有标签都未激活时，才禁用规则
      for (final rule in _rules.where((r) => r.tags.contains(tag))) {
        if (rule.isEnabled && !rule.tags.any((t) => _activeTags.contains(t))) {
          final updatedRule = rule.copyWith(isEnabled: false);
          await _repository.updateRule(updatedRule);
          final index = _rules.indexWhere((r) => r.id == rule.id);
          if (index != -1) {
            _rules[index] = updatedRule;
          }
        }
      }

      notifyListeners();
    } catch (e) {
      _activeTags.add(tag);
      throw TagActivationException.storageError();
    }
  }

  // 切换标签激活状态
  Future<void> toggleTagActivation(String tag) async {
    if (_activeTags.contains(tag)) {
      await deactivateTag(tag);
    } else {
      await activateTag(tag);
    }
  }

  // 根据标签筛选规则
  List<Rule> getRulesByTags(List<String> tags) {
    if (tags.isEmpty) return rules;
    return _rules.where((rule) {
      return rule.tags.any((tag) => tags.contains(tag));
    }).toList();
  }

  Future<void> loadRules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rules = await _repository.loadRules();
      await loadActiveTags(); // 同时加载激活的标签
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

  // 从所有规则中删除指定标签
  Future<void> deleteTag(String tag) async {
    try {
      // 如果标签处于激活状态，先反激活
      if (_activeTags.contains(tag)) {
        await deactivateTag(tag);
      }

      // 更新所有包含该标签的规则
      for (final rule in _rules.where((r) => r.tags.contains(tag))) {
        final updatedTags = rule.tags.where((t) => t != tag).toList();
        final updatedRule = rule.copyWith(tags: updatedTags);
        await _repository.updateRule(updatedRule);
        final index = _rules.indexWhere((r) => r.id == rule.id);
        if (index != -1) {
          _rules[index] = updatedRule;
        }
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error deleting tag: $e');
      }
      rethrow;
    }
  }
}
