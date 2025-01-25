import 'rule.dart';
import 'rule_conflict_type.dart';

/// 规则合并结果
class RuleMergeResult {
  /// 合并后的规则
  final Rule? mergedRule;

  /// 冲突类型
  final RuleConflictType conflictType;

  /// 错误信息
  final String? errorMessage;

  /// 是否成功
  bool get isSuccess => conflictType == RuleConflictType.none;

  /// 是否可合并
  bool get isMergeable => conflictType == RuleConflictType.mergeable;

  /// 是否冲突
  bool get isConflict => conflictType == RuleConflictType.conflict;

  const RuleMergeResult({
    this.mergedRule,
    required this.conflictType,
    this.errorMessage,
  });

  /// 创建成功的合并结果
  factory RuleMergeResult.success(Rule mergedRule) {
    return RuleMergeResult(
      mergedRule: mergedRule,
      conflictType: RuleConflictType.none,
    );
  }

  /// 创建可合并的结果
  factory RuleMergeResult.mergeable(Rule mergedRule) {
    return RuleMergeResult(
      mergedRule: mergedRule,
      conflictType: RuleConflictType.mergeable,
    );
  }

  /// 创建冲突的结果
  factory RuleMergeResult.conflict({String? errorMessage}) {
    return RuleMergeResult(
      conflictType: RuleConflictType.conflict,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('RuleMergeResult{');
    buffer.write('conflictType: ${conflictType.name}');
    if (mergedRule != null) {
      buffer.write(', mergedRule: $mergedRule');
    }
    if (errorMessage != null) {
      buffer.write(', errorMessage: $errorMessage');
    }
    buffer.write('}');

    return buffer.toString();
  }
}
