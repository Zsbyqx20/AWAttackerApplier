/// 规则冲突类型
enum RuleConflictType {
  /// 无冲突
  none,

  /// 可合并（包名和活动名相同，但UI Automator代码不同）
  mergeable,

  /// 完全冲突（包名、活动名和UI Automator代码都相同）
  conflict;

  /// 获取冲突类型的描述
  String get description {
    switch (this) {
      case RuleConflictType.none:
        return '无冲突';
      case RuleConflictType.mergeable:
        return '可合并';
      case RuleConflictType.conflict:
        return '完全冲突';
    }
  }
}
