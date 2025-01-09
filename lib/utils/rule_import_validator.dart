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
        '无效的包名格式',
      );
    }
  }

  /// 验证活动名格式
  static void validateActivityName(String activityName) {
    if (!activityName.startsWith('.')) {
      throw RuleImportException.invalidFieldValue(
        'activityName',
        '活动名必须以点号(.)开头',
      );
    }

    final regex = RegExp(r'^\.[a-zA-Z][a-zA-Z0-9_$.]*$');
    if (!regex.hasMatch(activityName)) {
      throw RuleImportException.invalidFieldValue(
        'activityName',
        '无效的活动名格式',
      );
    }
  }

  /// 验证标签列表
  static void validateTags(List<String> tags) {
    for (final tag in tags) {
      if (tag.isEmpty) {
        throw RuleImportException.invalidFieldValue('tags', '标签不能为空');
      }
      if (tag.length > 50) {
        throw RuleImportException.invalidFieldValue('tags', '标签长度不能超过50个字符');
      }
    }
  }

  /// 验证悬浮窗样式
  static void validateOverlayStyle(OverlayStyle style) {
    // 验证文本
    if (style.text.isEmpty) {
      throw RuleImportException.invalidFieldValue('text', '文本不能为空');
    }

    // 验证字体大小
    if (style.fontSize <= 0) {
      throw RuleImportException.invalidFieldValue('fontSize', '字体大小必须大于0');
    }

    // 验证内边距
    final padding = style.padding;
    if (padding.left < 0 ||
        padding.top < 0 ||
        padding.right < 0 ||
        padding.bottom < 0) {
      throw RuleImportException.invalidFieldValue('padding', '内边距不能为负数');
    }

    // 验证UI Automator代码
    if (style.uiAutomatorCode.isEmpty) {
      throw RuleImportException.invalidFieldValue(
          'uiAutomatorCode', 'UI Automator代码不能为空');
    }

    // 验证背景色
    validateColor(style.backgroundColor, 'backgroundColor');

    // 验证文本色
    validateColor(style.textColor, 'textColor');
  }

  /// 验证颜色值
  static void validateColor(Color color, String fieldName) {
    if (color.a == 0.0) {
      throw RuleImportException.invalidFieldValue(fieldName, '颜色不能完全透明');
    }
  }
}
