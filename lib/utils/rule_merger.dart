import '../models/rule.dart';
import '../models/rule_merge_result.dart';

/// 规则合并工具类
class RuleMerger {
  /// 检查两个规则是否冲突
  static RuleMergeResult checkConflict(Rule existingRule, Rule newRule) {
    // 如果包名和活动名不同，则无冲突
    if (existingRule.packageName != newRule.packageName ||
        existingRule.activityName != newRule.activityName) {
      return RuleMergeResult.success(newRule);
    }

    // 检查是否有完全相同的UI Automator代码
    final existingCodes = existingRule.overlayStyles
        .map((style) => style.uiAutomatorCode)
        .toSet();
    final hasConflict = newRule.overlayStyles
        .any((style) => existingCodes.contains(style.uiAutomatorCode));

    // 如果有完全相同的UI Automator代码，则为完全冲突
    if (hasConflict) {
      return RuleMergeResult.conflict(
        errorMessage:
            'Rule "${newRule.name}" conflicts with existing rule "${existingRule.name}"',
      );
    }

    // 如果只是包名和活动名相同，但UI Automator代码不同，则可以合并
    final mergedRule = _mergeRules(existingRule, newRule);
    return RuleMergeResult.mergeable(mergedRule);
  }

  /// 合并两个规则
  static Rule _mergeRules(Rule existingRule, Rule newRule) {
    // 合并悬浮窗样式
    final mergedStyles = [
      ...existingRule.overlayStyles,
      ...newRule.overlayStyles,
    ];

    // 合并标签
    final mergedTags = {...existingRule.tags, ...newRule.tags}.toList();

    // 创建合并后的规则
    return existingRule.copyWith(
      overlayStyles: mergedStyles,
      tags: mergedTags,
      // 保持原有规则的启用状态
      isEnabled: existingRule.isEnabled,
    );
  }

  /// 检查规则列表中的冲突
  static List<RuleMergeResult> checkConflicts(
    List<Rule> existingRules,
    List<Rule> newRules,
  ) {
    final results = <RuleMergeResult>[];

    for (final newRule in newRules) {
      var hasConflict = false;
      for (final existingRule in existingRules) {
        final result = checkConflict(existingRule, newRule);
        if (result.isConflict || result.isMergeable) {
          results.add(result);
          hasConflict = true;
          break;
        }
      }
      if (!hasConflict) {
        results.add(RuleMergeResult.success(newRule));
      }
    }

    return results;
  }
}
