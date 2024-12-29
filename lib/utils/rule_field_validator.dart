import 'package:flutter/material.dart';
import '../models/rule_validation_result.dart';
import '../models/overlay_style.dart';
import 'rule_import_validator.dart';
import '../exceptions/rule_import_exception.dart';

/// 规则字段验证器
class RuleFieldValidator {
  /// 验证包名
  static RuleValidationResult validatePackageName(String? packageName) {
    if (packageName == null || packageName.isEmpty) {
      return RuleValidationResult.fieldError('packageName', '包名不能为空');
    }

    try {
      RuleImportValidator.validatePackageName(packageName);
      return RuleValidationResult.success();
    } catch (e) {
      if (e is RuleImportException) {
        return RuleValidationResult.fromException(e);
      }
      return RuleValidationResult.fieldError('packageName', e.toString());
    }
  }

  /// 验证活动名
  static RuleValidationResult validateActivityName(String? activityName) {
    if (activityName == null || activityName.isEmpty) {
      return RuleValidationResult.fieldError('activityName', '活动名不能为空');
    }

    try {
      RuleImportValidator.validateActivityName(activityName);
      return RuleValidationResult.success();
    } catch (e) {
      if (e is RuleImportException) {
        return RuleValidationResult.fromException(e);
      }
      return RuleValidationResult.fieldError('activityName', e.toString());
    }
  }

  /// 验证规则名称
  static RuleValidationResult validateName(String? name) {
    if (name == null || name.isEmpty) {
      return RuleValidationResult.fieldError('name', '规则名称不能为空');
    }
    if (name.length > 50) {
      return RuleValidationResult.fieldError('name', '规则名称不能超过50个字符');
    }
    return RuleValidationResult.success();
  }

  /// 验证标签
  static RuleValidationResult validateTag(String tag) {
    try {
      RuleImportValidator.validateTags([tag]);
      return RuleValidationResult.success();
    } catch (e) {
      if (e is RuleImportException) {
        return RuleValidationResult.fromException(e);
      }
      return RuleValidationResult.fieldError('tag', e.toString());
    }
  }

  /// 验证标签列表
  static RuleValidationResult validateTags(List<String>? tags) {
    if (tags == null) {
      return RuleValidationResult.success();
    }

    try {
      RuleImportValidator.validateTags(tags);
      return RuleValidationResult.success();
    } catch (e) {
      if (e is RuleImportException) {
        return RuleValidationResult.fromException(e);
      }
      return RuleValidationResult.fieldError('tags', e.toString());
    }
  }

  /// 验证悬浮窗样式
  static RuleValidationResult validateOverlayStyle(OverlayStyle? style) {
    if (style == null) {
      return RuleValidationResult.fieldError('overlayStyle', '悬浮窗样式不能为空');
    }

    try {
      RuleImportValidator.validateOverlayStyle(style);
      return RuleValidationResult.success();
    } catch (e) {
      if (e is RuleImportException) {
        return RuleValidationResult.fromException(e);
      }
      return RuleValidationResult.fieldError('overlayStyle', e.toString());
    }
  }

  /// 验证颜色
  static RuleValidationResult validateColor(Color? color, String fieldName) {
    if (color == null) {
      return RuleValidationResult.fieldError(fieldName, '颜色不能为空');
    }

    try {
      RuleImportValidator.validateColor(color, fieldName);
      return RuleValidationResult.success();
    } catch (e) {
      if (e is RuleImportException) {
        return RuleValidationResult.fromException(e);
      }
      return RuleValidationResult.fieldError(fieldName, e.toString());
    }
  }
}
