import 'package:flutter/foundation.dart';
import '../models/rule.dart';
import '../models/overlay_style.dart';
import '../repositories/rule_repository.dart';
import '../repositories/storage_repository.dart';
import '../exceptions/tag_activation_exception.dart';
import '../models/rule_import.dart';
import '../exceptions/rule_import_exception.dart';
import '../utils/rule_field_validator.dart';
import '../models/rule_validation_result.dart';
import '../models/rule_merge_result.dart';
import '../utils/rule_merger.dart';
import '../extensions/rule_extensions.dart';

class RuleProvider extends ChangeNotifier {
  final RuleRepository _repository;
  final StorageRepository _storageRepository;
  List<Rule> _rules = [];
  Set<String> _activeTags = {};
  bool _isLoading = false;
  String? _error;
  final Map<String, RuleValidationResult> _validationResults = {};

  RuleProvider(this._repository) : _storageRepository = StorageRepository();

  List<Rule> get rules => List.unmodifiable(_rules);
  Set<String> get activeTags => Set.unmodifiable(_activeTags);
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, RuleValidationResult> get validationResults =>
      Map.unmodifiable(_validationResults);

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

  /// 验证单个字段
  RuleValidationResult validateField(String fieldName, dynamic value) {
    RuleValidationResult result;

    try {
      switch (fieldName) {
        case 'name':
          result = RuleFieldValidator.validateName(value as String?);
          break;
        case 'packageName':
          result = RuleFieldValidator.validatePackageName(value as String?);
          break;
        case 'activityName':
          result = RuleFieldValidator.validateActivityName(value as String?);
          break;
        case 'tags':
          result = RuleFieldValidator.validateTags(value as List<String>?);
          break;
        case 'overlayStyle':
          result =
              RuleFieldValidator.validateOverlayStyle(value as OverlayStyle?);
          break;
        default:
          result = RuleValidationResult.fieldError(
            fieldName,
            '未知字段',
            code: 'UNKNOWN_FIELD',
          );
      }

      _validationResults[fieldName] = result;
      notifyListeners();
      return result;
    } catch (e) {
      if (e is RuleImportException) {
        result = RuleValidationResult.fromException(e);
      } else {
        result = RuleValidationResult.fieldError(
          fieldName,
          e.toString(),
          code: 'VALIDATION_ERROR',
        );
      }
      _validationResults[fieldName] = result;
      notifyListeners();
      return result;
    }
  }

  /// 清除字段验证结果
  void clearFieldValidation(String fieldName) {
    _validationResults.remove(fieldName);
    notifyListeners();
  }

  /// 清除所有验证结果
  void clearAllValidations() {
    _validationResults.clear();
    notifyListeners();
  }

  /// 验证整个规则
  bool validateRule(Rule rule) {
    try {
      // 验证规则名称
      final nameResult = validateField('name', rule.name);
      if (!nameResult.isValid) return false;

      // 验证包名
      final packageResult = validateField('packageName', rule.packageName);
      if (!packageResult.isValid) return false;

      // 验证活动名
      final activityResult = validateField('activityName', rule.activityName);
      if (!activityResult.isValid) return false;

      // 验证标签
      final tagsResult = validateField('tags', rule.tags);
      if (!tagsResult.isValid) return false;

      // 验证悬浮窗样式
      for (final style in rule.overlayStyles) {
        final styleResult = validateField('overlayStyle', style);
        if (!styleResult.isValid) return false;
      }

      return true;
    } catch (e) {
      if (e is RuleImportException) {
        _validationResults[e.code ?? 'UNKNOWN'] =
            RuleValidationResult.fromException(e);
      } else {
        _validationResults['UNKNOWN'] = RuleValidationResult.fieldError(
          'rule',
          e.toString(),
          code: 'VALIDATION_ERROR',
        );
      }
      notifyListeners();
      return false;
    }
  }

  /// 获取字段验证结果
  RuleValidationResult? getFieldValidation(String fieldName) {
    return _validationResults[fieldName];
  }

  /// 检查字段是否有效
  bool isFieldValid(String fieldName) {
    final result = _validationResults[fieldName];
    return result?.isValid ?? true;
  }

  /// 获取字段错误信息
  String? getFieldError(String fieldName) {
    final result = _validationResults[fieldName];
    return result?.isValid == false ? result?.errorMessage : null;
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

      // 生成新规则的哈希值
      final newHashId = rule.generateHashId();

      // 检查是否存在相同内容的规则
      final hasDuplicate = _rules.any((r) => r.generateHashId() == newHashId);

      if (hasDuplicate) {
        throw RuleImportException(
          '规则已存在: ${rule.packageName}/${rule.activityName}',
          code: 'DUPLICATE_RULE',
        );
      }

      // 添加新规则
      _rules.add(rule);
      await _repository.addRule(rule);

      clearAllValidations();
      notifyListeners();
    } catch (e) {
      if (e is RuleImportException) {
        rethrow;
      }
      throw RuleImportException(e.toString());
    }
  }

  Future<void> updateRule(Rule rule) async {
    try {
      // 验证规则
      if (!validateRule(rule)) {
        throw RuleImportException('规则验证失败');
      }

      // 生成新规则的哈希值
      final newHashId = rule.generateHashId();

      // 检查是否存在相同内容的其他规则（排除自身）
      final hasDuplicate =
          _rules.any((r) => r.id != rule.id && r.generateHashId() == newHashId);

      if (hasDuplicate) {
        throw RuleImportException.invalidFieldValue(
          'rule',
          '规则已存在: ${rule.packageName}/${rule.activityName}',
        );
      }

      // 先更新内存中的规则
      final index = _rules.indexWhere((r) => r.id == rule.id);
      if (index != -1) {
        _rules[index] = rule;
      } else {
        _rules.add(rule);
      }

      // 再保存到存储
      await _repository.updateRule(rule);

      clearAllValidations();
      notifyListeners();
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
      // 获取要删除的规则
      final ruleToDelete = _rules.firstWhere((r) => r.id == ruleId);
      final tagsToCheck = ruleToDelete.tags.toSet();

      // 删除规则
      await _repository.deleteRule(ruleId);
      _rules = await _repository.loadRules();

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

  /// 导入规则
  Future<List<RuleMergeResult>> importRules(List<Rule> newRules) async {
    final results = <RuleMergeResult>[];

    try {
      // 验证所有规则
      for (final rule in newRules) {
        if (!validateRule(rule)) {
          final errorMessage = _validationResults.values
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
          final index = _rules.indexWhere((r) => r.id == mergedRule.id);
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
