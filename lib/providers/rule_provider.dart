import 'package:flutter/foundation.dart';

import '../exceptions/rule_import_exception.dart';
import '../exceptions/tag_activation_exception.dart';
import '../models/rule.dart';
import '../models/rule_import.dart';
import '../models/rule_merge_result.dart';
import '../models/rule_validation_result.dart';
import '../providers/rule_validation_provider.dart';
import '../repositories/rule_repository.dart';
import '../repositories/storage_repository.dart';
import '../utils/rule_merger.dart';

class RuleProvider extends ChangeNotifier {
  final RuleRepository _repository;
  final StorageRepository _storageRepository;
  final RuleValidationProvider _validationProvider;

  List<Rule> _rules = [];
  Set<String> _activeTags = {};
  String? _error;
  bool _isLoading = false;

  RuleProvider(
    this._repository,
    this._storageRepository,
    this._validationProvider,
  );

  List<Rule> get rules => _rules;
  Set<String> get activeTags => _activeTags;
  String? get error => _error;
  bool get isLoading => _isLoading;

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
          final index = _rules.indexOf(rule);
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

  // 取消激活标签
  Future<void> deactivateTag(String tag) async {
    if (!_activeTags.contains(tag)) {
      throw TagActivationException.notActive(tag);
    }

    try {
      _activeTags.remove(tag);
      await _storageRepository.saveActiveTags(_activeTags);

      // 更新包含该标签的规则状态
      for (final rule in _rules.where((r) => r.tags.contains(tag))) {
        if (rule.isEnabled) {
          final updatedRule = rule.copyWith(isEnabled: false);
          await _repository.updateRule(updatedRule);
          final index = _rules.indexOf(rule);
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
      notifyListeners();
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

  /// 验证整个规则
  bool validateRule(Rule rule) {
    try {
      _validationProvider.validateRule(rule);
      return _validationProvider.state.isValid;
    } catch (e) {
      if (e is RuleImportException) {
        // 保持原有的错误处理逻辑
        _validationProvider.state.fieldResults[e.code ?? 'UNKNOWN'] =
            RuleValidationResult.fromException(e);
      } else {
        _validationProvider.state.fieldResults['UNKNOWN'] =
            RuleValidationResult.fieldError(
          'rule',
          e.toString(),
          code: 'VALIDATION_ERROR',
        );
      }
      notifyListeners();
      return false;
    }
  }

  /// 检查规则是否存在冲突
  RuleMergeResult checkRuleConflict(Rule newRule) {
    for (final existingRule in _rules) {
      final result = RuleMerger.checkConflict(existingRule, newRule);
      if (result.isConflict || result.isMergeable) {
        return result;
      }
    }
    return RuleMergeResult.success(newRule);
  }

  /// 添加规则
  Future<void> addRule(Rule rule) async {
    try {
      // 验证规则
      if (!validateRule(rule)) {
        throw RuleImportException('规则验证失败');
      }

      // 检查是否存在相同内容的规则
      if (_rules.contains(rule)) {
        throw RuleImportException(
          '规则已存在: ${rule.packageName}/${rule.activityName}',
          code: 'DUPLICATE_RULE',
        );
      }

      // 添加新规则
      await _repository.addRule(rule);
      _rules.add(rule);

      _validationProvider.clearAllValidations();
      notifyListeners();
    } catch (e) {
      if (e is RuleImportException) {
        rethrow;
      }
      throw RuleImportException(e.toString());
    }
  }

  // 更新规则
  Future<void> updateRule(Rule rule) async {
    try {
      // 验证规则
      if (!validateRule(rule)) {
        throw RuleImportException('规则验证失败');
      }

      // 先删除具有相同包名和活动名的规则
      _rules.removeWhere((r) =>
          r.packageName == rule.packageName &&
          r.activityName == rule.activityName);

      // 添加更新后的规则
      _rules.add(rule);
      await _repository.updateRule(rule);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating rule: $e');
      }
      rethrow;
    }
  }

  // 删除规则
  Future<void> deleteRule(Rule rule) async {
    try {
      final tagsToCheck = List<String>.from(rule.tags);

      // 删除规则
      await _repository.deleteRule(rule);
      _rules.remove(rule);

      // 检查每个标签是否还被其他规则使用
      for (final tag in tagsToCheck) {
        final isTagUsed = _rules.any((r) => r.tags.contains(tag));
        if (!isTagUsed) {
          // 如果标签不再被使用，则完全删除它
          if (_activeTags.contains(tag)) {
            _activeTags.remove(tag);
            await _storageRepository.saveActiveTags(_activeTags);
          }
          // 彻底删除不再使用的标签
          await deleteTag(tag);
        }
      }

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
      final index = _rules.indexOf(rule);
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

  /// 从所有规则中删除指定标签
  Future<void> deleteTag(String tag) async {
    try {
      // 如果标签处于激活状态，先取消激活
      if (_activeTags.contains(tag)) {
        await deactivateTag(tag);
      }

      // 更新所有包含该标签的规则
      for (final rule in _rules.where((r) => r.tags.contains(tag))) {
        final updatedTags = rule.tags.where((t) => t != tag).toList();
        final updatedRule = rule.copyWith(tags: updatedTags);
        await _repository.updateRule(updatedRule);
        final index = _rules.indexOf(rule);
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

  /// 导入规则
  Future<List<RuleMergeResult>> importRules(List<Rule> newRules) async {
    final results = <RuleMergeResult>[];

    try {
      // 验证所有规则
      for (final rule in newRules) {
        if (!validateRule(rule)) {
          final errorMessage = _validationProvider.state.fieldResults.values
              .where((r) => !r.isValid)
              .map((r) => r.toString())
              .join('\n');
          results.add(RuleMergeResult.conflict(
            errorMessage: '规则验证失败: ${rule.name}\n$errorMessage',
          ));
          continue;
        }
      }

      // 如果有验证失败的规则，直接返回结果
      if (results.isNotEmpty) {
        return results;
      }

      // 检查所有规则的冲突情况
      final mergeResults = RuleMerger.checkConflicts(_rules, newRules);

      // 处理每个规则的导入结果
      for (final result in mergeResults) {
        if (result.isConflict) {
          // 记录冲突结果
          results.add(result);
          continue;
        }

        if (result.isMergeable) {
          // 更新现有规则
          final mergedRule = result.mergedRule!;
          await _repository.updateRule(mergedRule);
          final index = _rules.indexOf(mergedRule);
          if (index != -1) {
            _rules[index] = mergedRule;
          }
        } else {
          // 添加新规则
          final savedRule = await _repository.addRule(result.mergedRule!);
          _rules.add(savedRule);
        }

        results.add(result);
      }

      notifyListeners();
      return results;
    } catch (e) {
      if (e is RuleImportException) {
        rethrow;
      }
      throw RuleImportException(e.toString());
    }
  }

  /// 导出规则
  String exportRules() {
    return RuleImport(
      version: RuleImport.currentVersion,
      rules: List.from(_rules),
    ).toJson();
  }
}
