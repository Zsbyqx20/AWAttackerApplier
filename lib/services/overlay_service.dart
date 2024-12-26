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

  OverlayService._internal() {
    _nativeService = NativeOverlayService();
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
    try {
      return await _nativeService.removeOverlay(id);
    } catch (e) {
      debugPrint('🗑️ 移除悬浮窗时发生错误: $e');
      return false;
    }
  }

  @override
  Future<void> removeAllOverlays() async {
    try {
      await _nativeService.removeAllOverlays();
    } catch (e) {
      debugPrint('🧹 移除所有悬浮窗时发生错误: $e');
    }
  }

  @override
  List<String> getActiveOverlayIds() {
    return _nativeService.getActiveOverlayIds();
  }

  @override
  bool hasOverlay(String id) {
    return _nativeService.hasOverlay(id);
  }
}
