import 'package:flutter/foundation.dart';
import '../models/rule.dart';
import '../models/rule_validation_result.dart';
import '../utils/rule_field_validator.dart';

/// 规则验证状态
class RuleValidationState {
  final Map<String, RuleValidationResult> fieldResults;
  final bool isValid;

  const RuleValidationState({
    required this.fieldResults,
    required this.isValid,
  });

  /// 创建初始状态
  factory RuleValidationState.initial() {
    return const RuleValidationState(
      fieldResults: {},
      isValid: false,
    );
  }

  /// 创建新的状态
  RuleValidationState copyWith({
    Map<String, RuleValidationResult>? fieldResults,
    bool? isValid,
  }) {
    return RuleValidationState(
      fieldResults: fieldResults ?? this.fieldResults,
      isValid: isValid ?? this.isValid,
    );
  }
}

/// 规则验证状态管理器
class RuleValidationProvider extends ChangeNotifier {
  RuleValidationState _state = RuleValidationState.initial();
  RuleValidationState get state => _state;

  /// 验证单个字段
  void validateField(String fieldName, dynamic value) {
    RuleValidationResult result;

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
        result = RuleFieldValidator.validateOverlayStyle(value);
        break;
      default:
        result = RuleValidationResult.fieldError(
          fieldName,
          '未知字段',
          code: 'UNKNOWN_FIELD',
        );
    }

    // 更新字段验证结果
    final newResults =
        Map<String, RuleValidationResult>.from(_state.fieldResults);
    newResults[fieldName] = result;

    // 检查所有字段是否有效
    final isValid = newResults.values.every((result) => result.isValid);

    _state = _state.copyWith(
      fieldResults: newResults,
      isValid: isValid,
    );

    notifyListeners();
  }

  /// 清除字段验证结果
  void clearFieldValidation(String fieldName) {
    final newResults =
        Map<String, RuleValidationResult>.from(_state.fieldResults);
    newResults.remove(fieldName);

    // 检查所有字段是否有效
    final isValid = newResults.values.every((result) => result.isValid);

    _state = _state.copyWith(
      fieldResults: newResults,
      isValid: isValid,
    );

    notifyListeners();
  }

  /// 清除所有验证结果
  void clearAllValidations() {
    _state = RuleValidationState.initial();
    notifyListeners();
  }

  /// 验证整个规则
  void validateRule(Rule rule) {
    validateField('name', rule.name);
    validateField('packageName', rule.packageName);
    validateField('activityName', rule.activityName);
    validateField('tags', rule.tags);
    for (final style in rule.overlayStyles) {
      validateField('overlayStyle', style);
    }
  }

  /// 获取字段验证结果
  RuleValidationResult? getFieldValidation(String fieldName) {
    return _state.fieldResults[fieldName];
  }

  /// 检查字段是否有效
  bool isFieldValid(String fieldName) {
    final result = _state.fieldResults[fieldName];
    return result?.isValid ?? true;
  }

  /// 获取字段错误信息
  String? getFieldError(String fieldName) {
    final result = _state.fieldResults[fieldName];
    return result?.isValid == false ? result?.errorMessage : null;
  }
}
