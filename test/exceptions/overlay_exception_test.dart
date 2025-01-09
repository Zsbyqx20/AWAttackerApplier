import 'package:flutter_test/flutter_test.dart';

import 'package:awattackerapplier/exceptions/overlay_exception.dart';

void main() {
  group('OverlayException', () {
    test('permissionDenied factory creates correct exception', () {
      final exception = OverlayException.permissionDenied('权限被拒绝');
      expect(exception.code, equals(OverlayException.permissionDeniedCode));
      expect(exception.message, equals('悬浮窗权限未授予'));
      expect(exception.details, equals('权限被拒绝'));
      expect(
          exception.toString(),
          equals(
              'OverlayException: [PERMISSION_DENIED] 悬浮窗权限未授予\nDetails: 权限被拒绝'));
    });

    test('overlayNotFound factory creates correct exception', () {
      final exception = OverlayException.overlayNotFound('test_id');
      expect(exception.code, equals(OverlayException.overlayNotFoundCode));
      expect(exception.message, equals('悬浮窗不存在: test_id'));
      expect(exception.details, isNull);
      expect(exception.toString(),
          equals('OverlayException: [OVERLAY_NOT_FOUND] 悬浮窗不存在: test_id'));
    });

    test('createFailed factory creates correct exception', () {
      final exception =
          OverlayException.createFailed('创建失败原因', {'error': 'details'});
      expect(exception.code, equals(OverlayException.createFailedCode));
      expect(exception.message, equals('创建悬浮窗失败: 创建失败原因'));
      expect(exception.details, equals({'error': 'details'}));
      expect(
          exception.toString(),
          equals(
              'OverlayException: [CREATE_FAILED] 创建悬浮窗失败: 创建失败原因\nDetails: {error: details}'));
    });

    test('updateFailed factory creates correct exception', () {
      final exception = OverlayException.updateFailed('更新失败原因');
      expect(exception.code, equals(OverlayException.updateFailedCode));
      expect(exception.message, equals('更新悬浮窗失败: 更新失败原因'));
      expect(exception.details, isNull);
      expect(exception.toString(),
          equals('OverlayException: [UPDATE_FAILED] 更新悬浮窗失败: 更新失败原因'));
    });

    test('removeFailed factory creates correct exception', () {
      final exception = OverlayException.removeFailed('移除失败原因');
      expect(exception.code, equals(OverlayException.removeFailedCode));
      expect(exception.message, equals('移除悬浮窗失败: 移除失败原因'));
      expect(exception.details, isNull);
      expect(exception.toString(),
          equals('OverlayException: [REMOVE_FAILED] 移除悬浮窗失败: 移除失败原因'));
    });

    test('toMap returns correct map with details', () {
      final exception = OverlayException.createFailed('测试', 'details');
      final map = exception.toMap();
      expect(
          map,
          equals({
            'code': OverlayException.createFailedCode,
            'message': '创建悬浮窗失败: 测试',
            'details': 'details'
          }));
    });

    test('toMap returns correct map without details', () {
      final exception = OverlayException.overlayNotFound('test_id');
      final map = exception.toMap();
      expect(
          map,
          equals({
            'code': OverlayException.overlayNotFoundCode,
            'message': '悬浮窗不存在: test_id'
          }));
    });

    test('custom constructor creates correct exception', () {
      final exception = OverlayException('TEST_CODE', '测试消息', '测试详情');
      expect(exception.code, equals('TEST_CODE'));
      expect(exception.message, equals('测试消息'));
      expect(exception.details, equals('测试详情'));
      expect(exception.toString(),
          equals('OverlayException: [TEST_CODE] 测试消息\nDetails: 测试详情'));
    });
  });
}
