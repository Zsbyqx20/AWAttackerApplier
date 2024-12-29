import '../exceptions/rule_import_exception.dart';

/// 规则验证结果
class RuleValidationResult {
  final bool isValid;
  final String? fieldName;
  final String? errorMessage;
  final String? errorCode;
  final dynamic errorDetails;

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
    return RuleValidationResult(
      isValid: false,
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
    dynamic details,
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
      buffer.write(' [错误码: $errorCode]');
    }
    if (errorDetails != null) {
      buffer.write('\n详情: $errorDetails');
    }
    return buffer.toString();
  }
}
