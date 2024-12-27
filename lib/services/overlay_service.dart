import 'package:flutter/material.dart';
import '../models/overlay_style.dart';
import '../models/overlay_result.dart';
import '../exceptions/overlay_exception.dart';
import 'interfaces/i_overlay_service.dart';
import 'native_overlay_service.dart';

/// 悬浮窗服务
/// 单例模式实现，管理所有悬浮窗操作
class OverlayService implements IOverlayService {
  static final OverlayService _instance = OverlayService._internal();
  factory OverlayService() => _instance;

  late final IOverlayService _nativeService;
  bool _isServiceRunning = false;

  OverlayService._internal() {
    _nativeService = NativeOverlayService();
  }

  /// 获取服务运行状态
  bool get isServiceRunning => _isServiceRunning;

  /// 启动服务
  void start() {
    _isServiceRunning = true;
  }

  /// 停止服务
  void stop() {
    _isServiceRunning = false;
    removeAllOverlays();
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

    try {
      // 验证样式
      if (!style.isValid()) {
        final error = style.getValidationError();
        return OverlayResult.failure(error ?? '无效的样式配置');
      }

      return await _nativeService.createOverlay(id, style);
    } catch (e) {
      debugPrint('🪟 创建悬浮窗时发生错误: $e');
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

    try {
      // 验证样式
      if (!style.isValid()) {
        final error = style.getValidationError();
        return OverlayResult.failure(error ?? '无效的样式配置');
      }

      return await _nativeService.updateOverlay(id, style);
    } catch (e) {
      debugPrint('🔄 更新悬浮窗时发生错误: $e');
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
      return await _nativeService.removeOverlay(id);
    } catch (e) {
      debugPrint('🗑️ 移除悬浮窗时发生错误: $e');
      return false;
    }
  }

  @override
  Future<void> removeAllOverlays() async {
    if (!_isServiceRunning) {
      debugPrint('🚫 服务未运行，无法移除悬浮窗');
      return;
    }

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
