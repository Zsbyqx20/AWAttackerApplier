import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../exceptions/overlay_exception.dart';
import '../models/overlay_result.dart';
import '../models/overlay_style.dart';
import '../utils/overlay_converter.dart';
import 'interfaces/i_overlay_service.dart';

/// 原生悬浮窗服务实现
class NativeOverlayService implements IOverlayService {
  static const _channel =
      MethodChannel('com.mobilellm.awattackerapplier/overlay_service');

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
      debugPrint('📤 正在移除所有悬浮窗...');
      if (_activeOverlayIds.isEmpty) {
        debugPrint('💡 没有活动的悬浮窗需要移除');

        return;
      }

      debugPrint('🔍 当前活动的悬浮窗: ${_activeOverlayIds.join(', ')}');
      final result = await _channel.invokeMethod<bool>('removeAllOverlays');

      if (result == true) {
        debugPrint('✅ 所有悬浮窗已成功移除');
        _activeOverlayIds.clear();
      } else {
        debugPrint('⚠️ 批量移除失败，尝试逐个移除...');
        var hasError = false;
        // 尝试逐个移除
        for (final id in _activeOverlayIds.toList()) {
          try {
            final removed =
                await _channel.invokeMethod<bool>('removeOverlay', {'id': id});
            if (removed == true) {
              _activeOverlayIds.remove(id);
              debugPrint('✅ 成功移除悬浮窗: $id');
            } else {
              hasError = true;
              debugPrint('❌ 移除悬浮窗失败: $id');
            }
          } catch (e) {
            hasError = true;
            debugPrint('❌ 移除悬浮窗时发生错误: $id, $e');
            _activeOverlayIds.remove(id);
          }
        }

        if (hasError) {
          throw OverlayException.removeFailed('部分悬浮窗移除失败');
        }
      }
    } catch (e) {
      debugPrint('❌ 移除所有悬浮窗时发生错误: $e');
      // 即使发生错误也要清空活动列表，但要记录日志
      final ids = _activeOverlayIds.toList();
      _activeOverlayIds.clear();
      debugPrint('⚠️ 强制清空活动悬浮窗列表: ${ids.join(', ')}');
      rethrow; // 向上层抛出错误，让调用者知道实际的执行结果
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
