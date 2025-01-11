import 'dart:convert';

import '../exceptions/rule_import_exception.dart';
import '../utils/rule_import_validator.dart';
import 'overlay_style.dart';
import 'rule.dart';

/// 规则导入结果
class RuleImportResult {
  final int totalCount;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  const RuleImportResult({
    required this.totalCount,
    required this.successCount,
    required this.failureCount,
    this.errors = const [],
  });

  bool get hasErrors => failureCount > 0;

  factory RuleImportResult.success(int count) {
    return RuleImportResult(
      totalCount: count,
      successCount: count,
      failureCount: 0,
    );
  }

  factory RuleImportResult.failure(String error) {
    return RuleImportResult(
      totalCount: 1,
      successCount: 0,
      failureCount: 1,
      errors: [error],
    );
  }

  factory RuleImportResult.partial(
      int successCount, int failureCount, List<String> errors) {
    return RuleImportResult(
      totalCount: successCount + failureCount,
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
    );
  }
}

/// 规则导入数据
class RuleImport {
  static const String currentVersion = '1.0';

  final String version;
  final List<Rule> rules;

  const RuleImport({
    required this.version,
    required this.rules,
  });

  factory RuleImport.fromJson(String jsonStr) {
    if (jsonStr.isEmpty) {
      throw RuleImportException.emptyFile();
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw RuleImportException.invalidFormat();
    }

    // 验证版本号
    final version = json['version'] as String?;
    if (version == null) {
      throw RuleImportException.missingField('version');
    }
    if (version != currentVersion) {
      throw RuleImportException.incompatibleVersion(version);
    }

    // 验证规则列表
    final ruleList = json['rules'];
    if (ruleList == null) {
      throw RuleImportException.missingField('rules');
    }
    if (ruleList is! List) {
      throw RuleImportException.invalidFieldType('rules', 'List');
    }
    if (ruleList.isEmpty) {
      throw RuleImportException.noRules();
    }

    // 解析规则
    final rules = <Rule>[];
    for (var i = 0; i < ruleList.length; i++) {
      try {
        final rule = _parseRule(ruleList[i]);
        rules.add(rule);
      } catch (e) {
        throw RuleImportException(
          'Parse rule failed',
          code: 'RULE_PARSE_ERROR',
          details: 'Rule index: $i, Error: $e',
        );
      }
    }

    return RuleImport(
      version: version,
      rules: rules,
    );
  }

  /// 解析单个规则
  static Rule _parseRule(dynamic jsonData) {
    if (jsonData is! Map<String, dynamic>) {
      throw RuleImportException.invalidFieldValue('rule', 'Rule format error');
    }
    final json = jsonData;

    final name = json['name'] as String?;
    if (name == null || name.isEmpty) {
      throw RuleImportException.invalidFieldValue(
          'name', 'Rule name cannot be empty');
    }

    final packageName = json['packageName'] as String?;
    if (packageName == null || packageName.isEmpty) {
      throw RuleImportException.invalidFieldValue(
          'packageName', 'Package name cannot be empty');
    }
    RuleImportValidator.validatePackageName(packageName);

    final activityName = json['activityName'] as String?;
    if (activityName == null || activityName.isEmpty) {
      throw RuleImportException.invalidFieldValue(
          'activityName', 'Activity name cannot be empty');
    }
    RuleImportValidator.validateActivityName(activityName);

    final isEnabled = json['isEnabled'] as bool? ?? false;
    final tags = (json['tags'] as List?)?.cast<String>() ?? [];
    if (tags.isNotEmpty) {
      RuleImportValidator.validateTags(tags);
    }

    final styleList = json['overlayStyles'] as List?;
    if (styleList == null || styleList.isEmpty) {
      throw RuleImportException.invalidFieldValue(
          'overlayStyles', 'At least one overlay style is required');
    }

    final overlayStyles = <OverlayStyle>[];
    final styleErrors = <String>[];

    for (var i = 0; i < styleList.length; i++) {
      try {
        final styleData = styleList[i];
        if (styleData is! Map<String, dynamic>) {
          throw RuleImportException.invalidFieldValue(
              'overlayStyles', 'Style ${i + 1} format error');
        }
        final style = OverlayStyle.fromJson(styleData);
        RuleImportValidator.validateOverlayStyle(style);
        overlayStyles.add(style);
      } catch (e) {
        final error = e.toString();
        final fieldMatch = RegExp(r'Field (.*?):').firstMatch(error);
        if (fieldMatch != null) {
          final field = fieldMatch.group(1)!;
          final message = error.replaceFirst(RegExp(r'Field .*?: '), '');
          styleErrors.add('Style ${i + 1} $field: $message');
        } else {
          styleErrors.add('Style ${i + 1}: $error');
        }
      }
    }

    if (styleErrors.isNotEmpty) {
      throw RuleImportException(
        'Parse overlay styles failed',
        code: 'STYLE_PARSE_ERROR',
        details: styleErrors.join('\n'),
      );
    }

    return Rule(
      name: name,
      packageName: packageName,
      activityName: activityName,
      isEnabled: isEnabled,
      overlayStyles: overlayStyles,
      tags: tags,
    );
  }

  /// 转换为JSON字符串
  String toJson() {
    return jsonEncode({
      'version': version,
      'rules': rules.map((r) => r.toJson()).toList(),
    });
  }
}
