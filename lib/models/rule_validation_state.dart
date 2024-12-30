import 'rule_validation_result.dart';

/// 规则验证状态
class RuleValidationState {
  /// 是否有效
  final bool isValid;

  /// 字段验证结果
  final Map<String, RuleValidationResult> fieldResults;

  RuleValidationState({
    required this.isValid,
    required Map<String, RuleValidationResult> fieldResults,
  }) : fieldResults = Map.unmodifiable(fieldResults);

  /// 创建初始状态
  factory RuleValidationState.initial() {
    return RuleValidationState(
      isValid: true,
      fieldResults: const {},
    );
  }

  /// 创建新的状态
  RuleValidationState copyWith({
    bool? isValid,
    Map<String, RuleValidationResult>? fieldResults,
  }) {
    return RuleValidationState(
      isValid: isValid ?? this.isValid,
      fieldResults: fieldResults != null
          ? Map<String, RuleValidationResult>.from(fieldResults)
          : this.fieldResults,
    );
  }
}
