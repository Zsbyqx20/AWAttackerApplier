import '../exceptions/rule_import_exception.dart';

/// 规则验证结果
class RuleValidationResult {
  final bool isValid;
  final String? fieldName;
  final String? errorMessage;
  final String? errorCode;
  final Object? errorDetails;

  const RuleValidationResult({
    required this.isValid,
    this.fieldName,
    this.errorMessage,
    this.errorCode,
    this.errorDetails,
  });

  /// 创建成功的验证结果
  factory RuleValidationResult.success() {
    return const RuleValidationResult(isValid: true);
  }

  /// 从RuleImportException创建失败的验证结果
  factory RuleValidationResult.fromException(RuleImportException exception) {
    // 从异常详情中提取字段名
    String? fieldName;
    if (exception.details is String) {
      final detailsStr = exception.details as String;
      final match = RegExp(r'Field ([^:]+):').firstMatch(detailsStr);
      if (match != null && match.groupCount >= 1) {
        fieldName = match.group(1);
      }
    }

    return RuleValidationResult(
      isValid: false,
      fieldName: fieldName,
      errorMessage: exception.message,
      errorCode: exception.code,
      errorDetails: exception.details,
    );
  }

  /// 创建字段验证失败的结果
  factory RuleValidationResult.fieldError(
    String fieldName,
    String message, {
    String? code,
    Object? details,
  }) {
    return RuleValidationResult(
      isValid: false,
      fieldName: fieldName,
      errorMessage: message,
      errorCode: code ?? 'INVALID_FIELD_VALUE',
      errorDetails: details,
    );
  }

  @override
  String toString() {
    if (isValid) return 'Valid';

    final buffer = StringBuffer();
    if (fieldName != null) {
      buffer.write('Field $fieldName: ');
    }
    buffer.write(errorMessage);
    if (errorCode != null) {
      buffer.write(' [$errorCode]');
    }
    if (errorDetails != null) {
      buffer.write('\nDetails: $errorDetails');
    }

    return buffer.toString();
  }
}
