class RuleImportException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  RuleImportException(this.message, {this.code, this.details});

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (code != null) buffer.write(' [错误码: $code]');
    if (details != null) buffer.write('\n详情: $details');
    return buffer.toString();
  }

  // 格式错误
  static RuleImportException invalidFormat([String? details]) {
    return RuleImportException(
      'Invalid JSON format',
      code: 'INVALID_FORMAT',
      details: details,
    );
  }

  // 版本不兼容
  static RuleImportException incompatibleVersion(String version) {
    return RuleImportException(
      'Incompatible version',
      code: 'INCOMPATIBLE_VERSION',
      details: 'Import file version: $version',
    );
  }

  // 缺少必需字段
  static RuleImportException missingField(String field) {
    return RuleImportException(
      'Missing required field',
      code: 'MISSING_FIELD',
      details: 'Field name: $field',
    );
  }

  // 字段类型错误
  static RuleImportException invalidFieldType(
      String field, String expectedType) {
    return RuleImportException(
      'Invalid field type',
      code: 'INVALID_FIELD_TYPE',
      details: 'Field $field should be $expectedType type',
    );
  }

  // 字段值无效
  static RuleImportException invalidFieldValue(String field, String reason) {
    return RuleImportException(
      'Invalid field value',
      code: 'INVALID_FIELD_VALUE',
      details: 'Field $field: $reason',
    );
  }

  // 空文件
  static RuleImportException emptyFile() {
    return RuleImportException(
      'Import file is empty',
      code: 'EMPTY_FILE',
    );
  }

  // 无规则
  static RuleImportException noRules() {
    return RuleImportException(
      'Import file does not contain any rules',
      code: 'NO_RULES',
    );
  }
}
