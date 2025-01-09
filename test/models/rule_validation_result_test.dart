import 'package:flutter_test/flutter_test.dart';

import 'package:awattackerapplier/exceptions/rule_import_exception.dart';
import 'package:awattackerapplier/models/rule_validation_result.dart';

void main() {
  group('RuleValidationResult', () {
    test('使用默认构造函数创建实例', () {
      final result = RuleValidationResult(
        isValid: false,
        fieldName: 'testField',
        errorMessage: '测试错误',
        errorCode: 'TEST_ERROR',
        errorDetails: '详细信息',
      );

      expect(result.isValid, isFalse);
      expect(result.fieldName, equals('testField'));
      expect(result.errorMessage, equals('测试错误'));
      expect(result.errorCode, equals('TEST_ERROR'));
      expect(result.errorDetails, equals('详细信息'));
    });

    test('success 工厂方法创建有效的验证结果', () {
      final result = RuleValidationResult.success();

      expect(result.isValid, isTrue);
      expect(result.fieldName, isNull);
      expect(result.errorMessage, isNull);
      expect(result.errorCode, isNull);
      expect(result.errorDetails, isNull);
    });

    test('fieldError 工厂方法创建字段验证错误', () {
      final result = RuleValidationResult.fieldError(
        'testField',
        '字段错误',
        code: 'FIELD_ERROR',
        details: '错误详情',
      );

      expect(result.isValid, isFalse);
      expect(result.fieldName, equals('testField'));
      expect(result.errorMessage, equals('字段错误'));
      expect(result.errorCode, equals('FIELD_ERROR'));
      expect(result.errorDetails, equals('错误详情'));
    });

    test('fieldError 工厂方法使用默认错误代码', () {
      final result = RuleValidationResult.fieldError('testField', '字段错误');

      expect(result.isValid, isFalse);
      expect(result.fieldName, equals('testField'));
      expect(result.errorMessage, equals('字段错误'));
      expect(result.errorCode, equals('INVALID_FIELD_VALUE'));
      expect(result.errorDetails, isNull);
    });

    group('fromException 工厂方法', () {
      test('从异常创建验证结果 - 包含字段名', () {
        final exception = RuleImportException.invalidFieldValue(
          'email',
          '无效的邮箱格式',
        );

        final result = RuleValidationResult.fromException(exception);

        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('email'));
        expect(result.errorMessage, equals('字段值无效'));
        expect(result.errorCode, equals('INVALID_FIELD_VALUE'));
        expect(result.errorDetails, equals('字段 email: 无效的邮箱格式'));
      });

      test('从异常创建验证结果 - 不包含字段名', () {
        final exception = RuleImportException(
          '一般错误',
          code: 'GENERAL_ERROR',
          details: '错误详情',
        );

        final result = RuleValidationResult.fromException(exception);

        expect(result.isValid, isFalse);
        expect(result.fieldName, isNull);
        expect(result.errorMessage, equals('一般错误'));
        expect(result.errorCode, equals('GENERAL_ERROR'));
        expect(result.errorDetails, equals('错误详情'));
      });
    });

    group('toString 方法', () {
      test('有效结果的字符串表示', () {
        final result = RuleValidationResult.success();
        expect(result.toString(), equals('Valid'));
      });

      test('包含字段名的错误结果字符串表示', () {
        final result = RuleValidationResult.fieldError(
          'testField',
          '字段错误',
          code: 'TEST_ERROR',
          details: '错误详情',
        );
        expect(
          result.toString(),
          equals('Field testField: 字段错误 [错误码: TEST_ERROR]\n详情: 错误详情'),
        );
      });

      test('不包含字段名的错误结果字符串表示', () {
        final result = RuleValidationResult(
          isValid: false,
          errorMessage: '一般错误',
          errorCode: 'GENERAL_ERROR',
        );
        expect(result.toString(), equals('一般错误 [错误码: GENERAL_ERROR]'));
      });

      test('只包含错误消息的结果字符串表示', () {
        final result = RuleValidationResult(
          isValid: false,
          errorMessage: '简单错误',
        );
        expect(result.toString(), equals('简单错误'));
      });
    });
  });
}
