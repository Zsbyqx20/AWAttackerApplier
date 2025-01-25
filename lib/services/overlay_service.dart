import 'package:flutter/material.dart';

import '../exceptions/overlay_exception.dart';
import '../models/overlay_result.dart';
import '../models/overlay_style.dart';
import 'interfaces/i_overlay_service.dart';
import 'native_overlay_service.dart';

/// 悬浮窗服务
/// 单例模式实现，管理所有悬浮窗操作
class OverlayService implements IOverlayService {
  static final OverlayService _instance = OverlayService._internal();
  // ignore: avoid-late-keyword
  late final IOverlayService _nativeService;
  bool _isServiceRunning = false;
  bool get isServiceRunning => _isServiceRunning;
  factory OverlayService() => _instance;

  OverlayService._internal() {
    _nativeService = NativeOverlayService();
  }

  /// 启动服务
  Future<bool> start() async {
    if (_isServiceRunning) {
      debugPrint('🟢 悬浮窗服务已经在运行');

      return true;
    }

    try {
      // 检查权限
      if (!await checkPermission()) {
        debugPrint('🔒 悬浮窗权限未授予，无法启动服务');

        return false;
      }

      // 移除可能存在的旧悬浮窗
      await removeAllOverlays();

      // 设置服务状态
      _isServiceRunning = true;
      debugPrint('✅ 悬浮窗服务启动成功');

      return true;
    } catch (e) {
      debugPrint('❌ 启动悬浮窗服务时发生错误: $e');
      _isServiceRunning = false;

      return false;
    }
  }

  /// 停止服务
  Future<void> stop() async {
    try {
      // 无论服务状态如何，都尝试移除所有悬浮窗
      debugPrint('🧹 尝试清理所有悬浮窗...');
      await _nativeService.removeAllOverlays();

      if (_isServiceRunning) {
        _isServiceRunning = false;
        debugPrint('🛑 悬浮窗服务已停止');
      } else {
        debugPrint('⚪️ 悬浮窗服务未运行');
      }
    } catch (e) {
      debugPrint('❌ 停止悬浮窗服务时发生错误: $e');
      // 即使发生错误也要确保状态更新
      _isServiceRunning = false;
    }
  }

  @override
  Future<bool> checkPermission() async {
    try {
      return await _nativeService.checkPermission();
    } catch (e) {
      debugPrint('🔒 检查悬浮窗权限时发生错误: $e');

      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      return await _nativeService.requestPermission();
    } catch (e) {
      debugPrint('🔐 请求悬浮窗权限时发生错误: $e');

      return false;
    }
  }

  @override
  Future<OverlayResult> createOverlay(String id, OverlayStyle style) async {
    if (!_isServiceRunning) {
      debugPrint('🚫 服务未运行，无法创建悬浮窗');

      return OverlayResult.failure('服务未运行');
    }

    // 检查权限状态
    if (!await checkPermission()) {
      debugPrint('🔒 权限已失效，无法创建悬浮窗');
      _isServiceRunning = false; // 更新服务状态

      return OverlayResult.failure('权限已失效');
    }

    try {
      // 验证样式
      if (!style.isValid()) {
        final error = style.getValidationError();

        return OverlayResult.failure(error ?? '无效的样式配置');
      }

      final result = await _nativeService.createOverlay(id, style);
      if (!result.success) {
        debugPrint('❌ 创建悬浮窗失败: ${result.error}');
      }

      return result;
    } catch (e) {
      debugPrint('🪟 创建悬浮窗时发生错误: $e');
      if (e is OverlayException &&
          e.code == OverlayException.permissionDeniedCode) {
        _isServiceRunning = false; // 权限错误时更新服务状态
      }
      if (e is OverlayException) {
        return OverlayResult.failure(e.message);
      }

      return OverlayResult.failure(e.toString());
    }
  }

  @override
  Future<OverlayResult> updateOverlay(String id, OverlayStyle style) async {
    if (!_isServiceRunning) {
      debugPrint('🚫 服务未运行，无法更新悬浮窗');

      return OverlayResult.failure('服务未运行');
    }

    // 检查权限状态
    if (!await checkPermission()) {
      debugPrint('🔒 权限已失效，无法更新悬浮窗');
      _isServiceRunning = false; // 更新服务状态

      return OverlayResult.failure('权限已失效');
    }

    try {
      // 验证样式
      if (!style.isValid()) {
        final error = style.getValidationError();

        return OverlayResult.failure(error ?? '无效的样式配置');
      }

      // 检查悬浮窗是否存在
      if (!_nativeService.hasOverlay(id)) {
        return OverlayResult.failure('悬浮窗不存在');
      }

      final result = await _nativeService.updateOverlay(id, style);
      if (!result.success) {
        debugPrint('❌ 更新悬浮窗失败: ${result.error}');
      }

      return result;
    } catch (e) {
      debugPrint('🔄 更新悬浮窗时发生错误: $e');
      if (e is OverlayException &&
          e.code == OverlayException.permissionDeniedCode) {
        _isServiceRunning = false; // 权限错误时更新服务状态
      }
      if (e is OverlayException) {
        return OverlayResult.failure(e.message);
      }

      return OverlayResult.failure(e.toString());
    }
  }

  @override
  Future<bool> removeOverlay(String id) async {
    if (!_isServiceRunning) {
      debugPrint('🚫 服务未运行，无法移除悬浮窗');

      return false;
    }

    try {
      // 检查悬浮窗是否存在
      if (!_nativeService.hasOverlay(id)) {
        return true; // 如果悬浮窗不存在，视为移除成功
      }

      final result = await _nativeService.removeOverlay(id);
      if (!result) {
        debugPrint('❌ 移除悬浮窗失败');
      }

      return result;
    } catch (e) {
      debugPrint('🗑️ 移除悬浮窗时发生错误: $e');
      if (e is OverlayException &&
          e.code == OverlayException.permissionDeniedCode) {
        _isServiceRunning = false; // 权限错误时更新服务状态
      }

      return false;
    }
  }

  @override
  Future<void> removeAllOverlays() async {
    // 即使服务未运行也尝试移除所有悬浮窗
    try {
      await _nativeService.removeAllOverlays();
    } catch (e) {
      debugPrint('🧹 移除所有悬浮窗时发生错误: $e');
    }
  }

  @override
  List<String> getActiveOverlayIds() {
    if (!_isServiceRunning) {
      return [];
    }

    return _nativeService.getActiveOverlayIds();
  }

  @override
  bool hasOverlay(String id) {
    if (!_isServiceRunning) {
      return false;
    }

    return _nativeService.hasOverlay(id);
  }
}
