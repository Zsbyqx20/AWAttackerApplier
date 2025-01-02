import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/overlay_style.dart';
import '../models/overlay_result.dart';
import '../exceptions/overlay_exception.dart';
import '../utils/overlay_converter.dart';
import 'interfaces/i_overlay_service.dart';

/// 原生悬浮窗服务实现
class NativeOverlayService implements IOverlayService {
  static const _channel =
      MethodChannel('com.mobilellm.awattackapplier/overlay_service');

  // 存储活动的悬浮窗ID
  final Set<String> _activeOverlayIds = {};

  @override
  Future<bool> checkPermission() async {
    try {
      final result = await _channel.invokeMethod<String>('checkAllPermissions');
      if (result != null) {
        final permissions = jsonDecode(result) as Map<String, dynamic>;
        return permissions['overlay'] == true &&
            permissions['accessibility'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('检查权限时发生错误: $e');
      return false;
    }
  }

  /// 检查悬浮窗权限
  Future<bool> checkOverlayPermission() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('checkOverlayPermission');
      return result ?? false;
    } catch (e) {
      debugPrint('检查悬浮窗权限时发生错误: $e');
      return false;
    }
  }

  /// 检查无障碍服务权限
  Future<bool> checkAccessibilityPermission() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('checkAccessibilityPermission');
      return result ?? false;
    } catch (e) {
      debugPrint('检查无障碍服务权限时发生错误: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      // 先检查并请求悬浮窗权限
      if (!await checkOverlayPermission()) {
        final overlayGranted =
            await _channel.invokeMethod<bool>('requestOverlayPermission');
        if (overlayGranted != true) {
          return false;
        }
      }

      // 再检查并请求无障碍服务权限
      if (!await checkAccessibilityPermission()) {
        await _channel.invokeMethod<bool>('requestAccessibilityPermission');
        // 由于无障碍服务权限需要用户手动开启，这里不等待结果
        return true;
      }

      return true;
    } catch (e) {
      debugPrint('请求权限时发生错误: $e');
      return false;
    }
  }

  @override
  Future<OverlayResult> createOverlay(String id, OverlayStyle style) async {
    try {
      if (!await checkPermission()) {
        final hasOverlay = await checkOverlayPermission();
        final hasAccessibility = await checkAccessibilityPermission();

        if (!hasOverlay) {
          throw OverlayException.permissionDenied();
        }
        if (!hasAccessibility) {
          throw OverlayException.accessibilityPermissionDenied();
        }
      }

      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('createOverlay', {
        'id': id,
        'style': OverlayConverter.styleToNative(style),
      });

      if (result != null && result['success'] == true) {
        _activeOverlayIds.add(id);
        return OverlayResult.success();
      } else {
        final error = result?['error'] as String? ?? '创建悬浮窗失败';
        return OverlayResult.failure(error);
      }
    } catch (e) {
      debugPrint('创建悬浮窗时发生错误: $e');
      if (e is OverlayException) {
        return OverlayResult.failure(e.message);
      }
      return OverlayResult.failure(e.toString());
    }
  }

  @override
  Future<OverlayResult> updateOverlay(String id, OverlayStyle style) async {
    try {
      if (!await checkPermission()) {
        final hasOverlay = await checkOverlayPermission();
        final hasAccessibility = await checkAccessibilityPermission();

        if (!hasOverlay) {
          throw OverlayException.permissionDenied();
        }
        if (!hasAccessibility) {
          throw OverlayException.accessibilityPermissionDenied();
        }
      }

      if (!_activeOverlayIds.contains(id)) {
        return OverlayResult.failure('悬浮窗不存在');
      }

      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('updateOverlay', {
        'id': id,
        'style': OverlayConverter.styleToNative(style),
      });

      if (result != null && result['success'] == true) {
        return OverlayResult.success();
      } else {
        final error = result?['error'] as String? ?? '更新悬浮窗失败';
        return OverlayResult.failure(error);
      }
    } catch (e) {
      debugPrint('更新悬浮窗时发生错误: $e');
      if (e is OverlayException) {
        return OverlayResult.failure(e.message);
      }
      return OverlayResult.failure(e.toString());
    }
  }

  @override
  Future<bool> removeOverlay(String id) async {
    try {
      final result =
          await _channel.invokeMethod<bool>('removeOverlay', {'id': id});
      if (result == true) {
        _activeOverlayIds.remove(id);
      }
      return result ?? false;
    } catch (e) {
      debugPrint('移除悬浮窗时发生错误: $e');
      return false;
    }
  }

  @override
  Future<void> removeAllOverlays() async {
    try {
      await _channel.invokeMethod('removeAllOverlays');
      _activeOverlayIds.clear();
    } catch (e) {
      debugPrint('移除所有悬浮窗时发生错误: $e');
    }
  }

  @override
  List<String> getActiveOverlayIds() {
    return _activeOverlayIds.toList();
  }

  @override
  bool hasOverlay(String id) {
    return _activeOverlayIds.contains(id);
  }
}
