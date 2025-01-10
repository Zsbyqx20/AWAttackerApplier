import 'package:flutter_test/flutter_test.dart';

import 'package:awattackerapplier/exceptions/rule_import_exception.dart';

void main() {
  group('RuleImportException', () {
    test('invalidFormat factory creates correct exception', () {
      final exception =
          RuleImportException.invalidFormat('Format error details');
      expect(exception.message, equals('Invalid JSON format'));
      expect(exception.code, equals('INVALID_FORMAT'));
      expect(exception.details, equals('Format error details'));
      expect(
          exception.toString(),
          equals(
              'Invalid JSON format [INVALID_FORMAT]\nDetails: Format error details'));
    });

    test('incompatibleVersion factory creates correct exception', () {
      final exception = RuleImportException.incompatibleVersion('1.0.0');
      expect(exception.message, equals('Incompatible version'));
      expect(exception.code, equals('INCOMPATIBLE_VERSION'));
      expect(exception.details, equals('Import file version: 1.0.0'));
      expect(
          exception.toString(),
          equals(
              'Incompatible version [INCOMPATIBLE_VERSION]\nDetails: Import file version: 1.0.0'));
    });

    test('missingField factory creates correct exception', () {
      final exception = RuleImportException.missingField('name');
      expect(exception.message, equals('Missing required field'));
      expect(exception.code, equals('MISSING_FIELD'));
      expect(exception.details, equals('Field name: name'));
      expect(
          exception.toString(),
          equals(
              'Missing required field [MISSING_FIELD]\nDetails: Field name: name'));
    });

    test('invalidFieldType factory creates correct exception', () {
      final exception = RuleImportException.invalidFieldType('age', 'number');
      expect(exception.message, equals('Invalid field type'));
      expect(exception.code, equals('INVALID_FIELD_TYPE'));
      expect(exception.details, equals('Field age should be number type'));
      expect(
          exception.toString(),
          equals(
              'Invalid field type [INVALID_FIELD_TYPE]\nDetails: Field age should be number type'));
    });

    test('invalidFieldValue factory creates correct exception', () {
      final exception =
          RuleImportException.invalidFieldValue('email', 'Invalid format');
      expect(exception.message, equals('Invalid field value'));
      expect(exception.code, equals('INVALID_FIELD_VALUE'));
      expect(exception.details, equals('Field email: Invalid format'));
      expect(
          exception.toString(),
          equals(
              'Invalid field value [INVALID_FIELD_VALUE]\nDetails: Field email: Invalid format'));
    });

    test('emptyFile factory creates correct exception', () {
      final exception = RuleImportException.emptyFile();
      expect(exception.message, equals('Import file is empty'));
      expect(exception.code, equals('EMPTY_FILE'));
      expect(exception.details, isNull);
      expect(exception.toString(), equals('Import file is empty [EMPTY_FILE]'));
    });

    test('noRules factory creates correct exception', () {
      final exception = RuleImportException.noRules();
      expect(
          exception.message, equals('Import file does not contain any rules'));
      expect(exception.code, equals('NO_RULES'));
      expect(exception.details, isNull);
      expect(exception.toString(),
          equals('Import file does not contain any rules [NO_RULES]'));
    });

    test('custom constructor creates correct exception', () {
      final exception = RuleImportException('Custom error',
          code: 'CUSTOM_ERROR', details: 'Detailed information');
      expect(exception.message, equals('Custom error'));
      expect(exception.code, equals('CUSTOM_ERROR'));
      expect(exception.details, equals('Detailed information'));
      expect(exception.toString(),
          equals('Custom error [CUSTOM_ERROR]\nDetails: Detailed information'));
    });

    test('toString without code and details', () {
      final exception = RuleImportException('Simple error');
      expect(exception.message, equals('Simple error'));
      expect(exception.code, isNull);
      expect(exception.details, isNull);
      expect(exception.toString(), equals('Simple error'));
    });

    test('toString with code but no details', () {
      final exception =
          RuleImportException('With code error', code: 'ERROR_CODE');
      expect(exception.message, equals('With code error'));
      expect(exception.code, equals('ERROR_CODE'));
      expect(exception.details, isNull);
      expect(exception.toString(), equals('With code error [ERROR_CODE]'));
    });
  });
}
