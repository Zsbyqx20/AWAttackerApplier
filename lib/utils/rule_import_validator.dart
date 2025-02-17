import 'package:flutter/material.dart';

import '../exceptions/rule_import_exception.dart';
import '../models/overlay_style.dart';

/// 规则导入验证工具
class RuleImportValidator {
  /// 验证包名格式
  static void validatePackageName(String packageName) {
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)*$');
    if (!regex.hasMatch(packageName)) {
      throw RuleImportException.invalidFieldValue(
        'packageName',
        'Invalid package name format',
      );
    }
  }

  /// 验证活动名格式
  static void validateActivityName(String activityName) {
    if (activityName.isEmpty) {
      throw RuleImportException.invalidFieldValue(
        'activityName',
        'Activity name cannot be empty',
      );
    }

    // 根据是否以点号开头使用不同的正则表达式
    final regex = activityName.startsWith('.')
        ? RegExp(r'^\.[a-zA-Z][a-zA-Z0-9_$.]*$') // 相对活动名格式
        : RegExp(
            r'^[a-zA-Z][a-zA-Z0-9_$.]*(\.[a-zA-Z][a-zA-Z0-9_$.]*)*$'); // 绝对活动名格式

    if (!regex.hasMatch(activityName)) {
      throw RuleImportException.invalidFieldValue(
        'activityName',
        'Invalid activity name format',
      );
    }
  }

  /// 验证标签列表
  static void validateTags(List<String> tags) {
    for (final tag in tags) {
      if (tag.isEmpty) {
        throw RuleImportException.invalidFieldValue(
            'tags', 'Tag cannot be empty');
      }
      if (tag.length > OverlayStyle.maxRuleNameLength) {
        throw RuleImportException.invalidFieldValue('tags',
            'Tag length cannot exceed ${OverlayStyle.maxRuleNameLength} characters');
      }
    }
  }

  /// 验证悬浮窗样式
  static void validateOverlayStyle(OverlayStyle style) {
    // 验证文本
    if (style.text.isEmpty) {
      throw RuleImportException.invalidFieldValue(
          'text', 'Text cannot be empty');
    }

    // 验证字体大小
    if (style.fontSize <= 0) {
      throw RuleImportException.invalidFieldValue(
          'fontSize', 'Font size must be greater than 0');
    }

    // 验证内边距
    final padding = style.padding;
    if (padding.left < 0 ||
        padding.top < 0 ||
        padding.right < 0 ||
        padding.bottom < 0) {
      throw RuleImportException.invalidFieldValue(
          'padding', 'Padding cannot be negative');
    }

    // 验证UI Automator代码
    if (style.uiAutomatorCode.isEmpty) {
      throw RuleImportException.invalidFieldValue(
          'uiAutomatorCode', 'UI Automator code cannot be empty');
    }

    // 验证背景色
    validateColor(style.backgroundColor, 'backgroundColor');

    // 验证文本色
    validateColor(style.textColor, 'textColor');

    // 验证允许条件
    final allow = style.allow;
    if (allow != null) {
      for (final condition in allow) {
        if (condition.isEmpty) {
          throw RuleImportException.invalidFieldValue(
              'allow', 'Allow condition cannot be empty');
        }
      }
    }

    // 验证拒绝条件
    final deny = style.deny;
    if (deny != null) {
      for (final condition in deny) {
        if (condition.isEmpty) {
          throw RuleImportException.invalidFieldValue(
              'deny', 'Deny condition cannot be empty');
        }
      }
    }
  }

  /// 验证颜色值
  static void validateColor(Color color, String fieldName) {
    if (color.a == 0.0) {
      throw RuleImportException.invalidFieldValue(
          fieldName, 'Color cannot be fully transparent');
    }
  }
}
