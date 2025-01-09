import 'package:flutter_test/flutter_test.dart';

import 'package:awattackerapplier/exceptions/tag_activation_exception.dart';

void main() {
  group('TagActivationException', () {
    test('notFound factory creates correct exception', () {
      final exception = TagActivationException.notFound('test_tag');
      expect(exception.message, equals('标签不存在'));
      expect(exception.tag, equals('test_tag'));
      expect(exception.code, equals('TAG_NOT_FOUND'));
      expect(exception.toString(),
          equals('标签不存在 (标签: test_tag) [错误码: TAG_NOT_FOUND]'));
    });

    test('alreadyActive factory creates correct exception', () {
      final exception = TagActivationException.alreadyActive('test_tag');
      expect(exception.message, equals('标签已经激活'));
      expect(exception.tag, equals('test_tag'));
      expect(exception.code, equals('TAG_ALREADY_ACTIVE'));
      expect(exception.toString(),
          equals('标签已经激活 (标签: test_tag) [错误码: TAG_ALREADY_ACTIVE]'));
    });

    test('notActive factory creates correct exception', () {
      final exception = TagActivationException.notActive('test_tag');
      expect(exception.message, equals('标签未激活'));
      expect(exception.tag, equals('test_tag'));
      expect(exception.code, equals('TAG_NOT_ACTIVE'));
      expect(exception.toString(),
          equals('标签未激活 (标签: test_tag) [错误码: TAG_NOT_ACTIVE]'));
    });

    test('storageError factory creates correct exception', () {
      final exception = TagActivationException.storageError();
      expect(exception.message, equals('存储操作失败'));
      expect(exception.tag, isNull);
      expect(exception.code, equals('STORAGE_ERROR'));
      expect(exception.toString(), equals('存储操作失败 [错误码: STORAGE_ERROR]'));
    });

    test('custom constructor creates correct exception', () {
      final exception = TagActivationException('自定义错误');
      expect(exception.message, equals('自定义错误'));
      expect(exception.tag, isNull);
      expect(exception.code, isNull);
      expect(exception.toString(), equals('自定义错误'));
    });
  });
}
