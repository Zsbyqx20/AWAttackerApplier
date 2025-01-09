import 'dart:convert';
import '../exceptions/rule_import_exception.dart';
import 'rule.dart';
import 'overlay_style.dart';

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

  /// 从JSON字符串解析
  static RuleImport fromJson(String jsonStr) {
    if (jsonStr.isEmpty) {
      throw RuleImportException.emptyFile();
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonStr);
    } catch (e) {
      throw RuleImportException.invalidFormat(e.toString());
    }

    // 验证版本
    final version = json['version'];
    if (version == null) {
      throw RuleImportException.missingField('version');
    }
    if (version is! String) {
      throw RuleImportException.invalidFieldType('version', 'String');
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
          '解析规则失败',
          code: 'RULE_PARSE_ERROR',
          details: '规则索引: $i, 错误: $e',
        );
      }
    }

    return RuleImport(
      version: version,
      rules: rules,
    );
  }

  /// 解析单个规则
  static Rule _parseRule(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.isEmpty) {
      throw RuleImportException.invalidFieldValue('name', '规则名称不能为空');
    }

    final packageName = json['packageName'] as String?;
    if (packageName == null || packageName.isEmpty) {
      throw RuleImportException.invalidFieldValue('packageName', '包名不能为空');
    }

    final activityName = json['activityName'] as String?;
    if (activityName == null || activityName.isEmpty) {
      throw RuleImportException.invalidFieldValue('activityName', '活动名不能为空');
    }

    final isEnabled = json['isEnabled'] as bool? ?? false;
    final tags = (json['tags'] as List?)?.cast<String>() ?? [];

    final styleList = json['overlayStyles'] as List?;
    if (styleList == null || styleList.isEmpty) {
      throw RuleImportException.invalidFieldValue(
          'overlayStyles', '至少需要一个悬浮窗样式');
    }

    final overlayStyles = <OverlayStyle>[];
    final styleErrors = <String>[];

    for (var i = 0; i < styleList.length; i++) {
      try {
        final style = OverlayStyle.fromJson(styleList[i]);
        overlayStyles.add(style);
      } catch (e) {
        final error = e.toString();
        final fieldMatch = RegExp(r'Field (.*?):').firstMatch(error);
        if (fieldMatch != null) {
          final field = fieldMatch.group(1)!;
          final message = error.replaceFirst(RegExp(r'Field .*?: '), '');
          styleErrors.add('样式 ${i + 1} 的 $field 字段: $message');
        } else {
          styleErrors.add('样式 ${i + 1}: $error');
        }
      }
    }

    if (styleErrors.isNotEmpty) {
      throw RuleImportException(
        '解析样式失败',
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
