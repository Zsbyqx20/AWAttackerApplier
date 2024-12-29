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
      'JSON格式无效',
      code: 'INVALID_FORMAT',
      details: details,
    );
  }

  // 版本不兼容
  static RuleImportException incompatibleVersion(String version) {
    return RuleImportException(
      '不兼容的版本',
      code: 'INCOMPATIBLE_VERSION',
      details: '导入文件版本: $version',
    );
  }

  // 缺少必需字段
  static RuleImportException missingField(String field) {
    return RuleImportException(
      '缺少必需字段',
      code: 'MISSING_FIELD',
      details: '字段名: $field',
    );
  }

  // 字段类型错误
  static RuleImportException invalidFieldType(
      String field, String expectedType) {
    return RuleImportException(
      '字段类型错误',
      code: 'INVALID_FIELD_TYPE',
      details: '字段 $field 应为 $expectedType 类型',
    );
  }

  // 字段值无效
  static RuleImportException invalidFieldValue(String field, String reason) {
    return RuleImportException(
      '字段值无效',
      code: 'INVALID_FIELD_VALUE',
      details: '字段 $field: $reason',
    );
  }

  // 空文件
  static RuleImportException emptyFile() {
    return RuleImportException(
      '导入文件为空',
      code: 'EMPTY_FILE',
    );
  }

  // 无规则
  static RuleImportException noRules() {
    return RuleImportException(
      '导入文件不包含任何规则',
      code: 'NO_RULES',
    );
  }
}
