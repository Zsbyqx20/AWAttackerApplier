import 'package:flutter_test/flutter_test.dart';

import 'package:awattackerapplier/exceptions/tag_activation_exception.dart';

void main() {
  group('TagActivationException', () {
    test('notFound factory creates correct exception', () {
      final exception = TagActivationException.notFound('test_tag');
      expect(exception.message, equals('Tag not found'));
      expect(exception.tag, equals('test_tag'));
      expect(exception.code, equals('TAG_NOT_FOUND'));
      expect(exception.toString(),
          equals('Tag not found (Tag: test_tag) [TAG_NOT_FOUND]'));
    });

    test('alreadyActive factory creates correct exception', () {
      final exception = TagActivationException.alreadyActive('test_tag');
      expect(exception.message, equals('Tag already active'));
      expect(exception.tag, equals('test_tag'));
      expect(exception.code, equals('TAG_ALREADY_ACTIVE'));
      expect(exception.toString(),
          equals('Tag already active (Tag: test_tag) [TAG_ALREADY_ACTIVE]'));
    });

    test('notActive factory creates correct exception', () {
      final exception = TagActivationException.notActive('test_tag');
      expect(exception.message, equals('Tag not active'));
      expect(exception.tag, equals('test_tag'));
      expect(exception.code, equals('TAG_NOT_ACTIVE'));
      expect(exception.toString(),
          equals('Tag not active (Tag: test_tag) [TAG_NOT_ACTIVE]'));
    });

    test('storageError factory creates correct exception', () {
      final exception = TagActivationException.storageError();
      expect(exception.message, equals('Storage operation failed'));
      expect(exception.tag, isNull);
      expect(exception.code, equals('STORAGE_ERROR'));
      expect(exception.toString(),
          equals('Storage operation failed [STORAGE_ERROR]'));
    });

    test('custom constructor creates correct exception', () {
      final exception = TagActivationException('Custom error');
      expect(exception.message, equals('Custom error'));
      expect(exception.tag, isNull);
      expect(exception.code, isNull);
      expect(exception.toString(), equals('Custom error'));
    });
  });
}
