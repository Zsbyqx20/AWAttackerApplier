import 'package:flutter_test/flutter_test.dart';

import 'package:awattackerapplier/exceptions/rule_import_exception.dart';

void main() {
  group('RuleImportException', () {
    test('invalidFormat factory creates correct exception', () {
      final exception = RuleImportException.invalidFormat('格式错误详情');
      expect(exception.message, equals('JSON格式无效'));
      expect(exception.code, equals('INVALID_FORMAT'));
      expect(exception.details, equals('格式错误详情'));
      expect(exception.toString(),
          equals('JSON格式无效 [错误码: INVALID_FORMAT]\n详情: 格式错误详情'));
    });

    test('incompatibleVersion factory creates correct exception', () {
      final exception = RuleImportException.incompatibleVersion('1.0.0');
      expect(exception.message, equals('不兼容的版本'));
      expect(exception.code, equals('INCOMPATIBLE_VERSION'));
      expect(exception.details, equals('导入文件版本: 1.0.0'));
      expect(exception.toString(),
          equals('不兼容的版本 [错误码: INCOMPATIBLE_VERSION]\n详情: 导入文件版本: 1.0.0'));
    });

    test('missingField factory creates correct exception', () {
      final exception = RuleImportException.missingField('name');
      expect(exception.message, equals('缺少必需字段'));
      expect(exception.code, equals('MISSING_FIELD'));
      expect(exception.details, equals('字段名: name'));
      expect(exception.toString(),
          equals('缺少必需字段 [错误码: MISSING_FIELD]\n详情: 字段名: name'));
    });

    test('invalidFieldType factory creates correct exception', () {
      final exception = RuleImportException.invalidFieldType('age', 'number');
      expect(exception.message, equals('字段类型错误'));
      expect(exception.code, equals('INVALID_FIELD_TYPE'));
      expect(exception.details, equals('字段 age 应为 number 类型'));
      expect(exception.toString(),
          equals('字段类型错误 [错误码: INVALID_FIELD_TYPE]\n详情: 字段 age 应为 number 类型'));
    });

    test('invalidFieldValue factory creates correct exception', () {
      final exception = RuleImportException.invalidFieldValue('email', '格式无效');
      expect(exception.message, equals('字段值无效'));
      expect(exception.code, equals('INVALID_FIELD_VALUE'));
      expect(exception.details, equals('字段 email: 格式无效'));
      expect(exception.toString(),
          equals('字段值无效 [错误码: INVALID_FIELD_VALUE]\n详情: 字段 email: 格式无效'));
    });

    test('emptyFile factory creates correct exception', () {
      final exception = RuleImportException.emptyFile();
      expect(exception.message, equals('导入文件为空'));
      expect(exception.code, equals('EMPTY_FILE'));
      expect(exception.details, isNull);
      expect(exception.toString(), equals('导入文件为空 [错误码: EMPTY_FILE]'));
    });

    test('noRules factory creates correct exception', () {
      final exception = RuleImportException.noRules();
      expect(exception.message, equals('导入文件不包含任何规则'));
      expect(exception.code, equals('NO_RULES'));
      expect(exception.details, isNull);
      expect(exception.toString(), equals('导入文件不包含任何规则 [错误码: NO_RULES]'));
    });

    test('custom constructor creates correct exception', () {
      final exception =
          RuleImportException('自定义错误', code: 'CUSTOM_ERROR', details: '详细信息');
      expect(exception.message, equals('自定义错误'));
      expect(exception.code, equals('CUSTOM_ERROR'));
      expect(exception.details, equals('详细信息'));
      expect(
          exception.toString(), equals('自定义错误 [错误码: CUSTOM_ERROR]\n详情: 详细信息'));
    });

    test('toString without code and details', () {
      final exception = RuleImportException('简单错误');
      expect(exception.message, equals('简单错误'));
      expect(exception.code, isNull);
      expect(exception.details, isNull);
      expect(exception.toString(), equals('简单错误'));
    });

    test('toString with code but no details', () {
      final exception = RuleImportException('带代码错误', code: 'ERROR_CODE');
      expect(exception.message, equals('带代码错误'));
      expect(exception.code, equals('ERROR_CODE'));
      expect(exception.details, isNull);
      expect(exception.toString(), equals('带代码错误 [错误码: ERROR_CODE]'));
    });
  });
}
