import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/element_result.dart';
import '../models/overlay_style.dart';
import '../models/window_event.dart';

class AccessibilityService extends ChangeNotifier {
  static const _channel =
      MethodChannel('com.mobilellm.awattackerapplier/overlay_service');
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  bool _initialized = false;
  bool _isDetectionEnabled = false;
  bool _isServiceRunning = false;
  bool _isServiceReady = false;
  final int _retryCount = 3;
  final int _initializationTimeout = 5000;
  // ignore: avoid-late-keyword
  late StreamController<WindowEvent> _windowEventController;

  bool get isDetectionEnabled => _isDetectionEnabled;
  Stream<WindowEvent> get windowEvents => _windowEventController.stream;

  bool get isServiceRunning => _isServiceRunning;
  bool get isServiceReady => _isServiceReady;

  factory AccessibilityService() {
    debugPrint('🏭 获取AccessibilityService实例');

    return _instance;
  }

  AccessibilityService._internal() {
    debugPrint('🏗️ 创建AccessibilityService单例');
  }

  @override
  void dispose() {
    _windowEventController.close();
    super.dispose();
  }

  /// 获取最新的无障碍树数据
  Future<Uint8List?> getLatestState() async {
    if (!_isServiceReady) {
      debugPrint('⏳ 等待无障碍服务就绪...');
      final startTime = DateTime.now();
      while (!_isServiceReady) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (DateTime.now().difference(startTime).inMilliseconds >
            _initializationTimeout) {
          debugPrint('❌ 等待无障碍服务就绪超时');

          return null;
        }
      }
    }

    for (var i = 0; i < _retryCount; i++) {
      try {
        final result = await _channel.invokeMethod<Uint8List>('getLatestState');
        if (result != null) {
          debugPrint('✅ 成功获取无障碍树数据: ${result.length} bytes');

          return result;
        }
        debugPrint('❌ 获取无障碍树数据失败: 返回为空，尝试次数: ${i + 1}/$_retryCount');
        if (i < _retryCount - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        debugPrint('❌ 获取无障碍树数据时发生错误: $e，尝试次数: ${i + 1}/$_retryCount');
        if (i < _retryCount - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    return null;
  }

  Future<bool> checkAndRequestPermissions() async {
    try {
      final hasPermission =
          await _channel.invokeMethod<bool>('checkAccessibilityPermission') ??
              false;
      if (!hasPermission) {
        await _channel.invokeMethod<void>('requestAccessibilityPermission');
      }
      _isServiceRunning = hasPermission;
      notifyListeners();

      return hasPermission;
    } catch (e) {
      debugPrint('检查权限时发生错误: $e');
      _isServiceRunning = false;
      notifyListeners();

      return false;
    }
  }

  Future<ElementResult?> findElement(OverlayStyle style) async {
    try {
      final result =
          await _channel.invokeMethod<Map<Object?, Object?>>('findElement', {
        'style': style.toNative(),
      });

      return result != null
          ? ElementResult.fromMap(Map<String, dynamic>.from(result))
          : null;
    } catch (e) {
      debugPrint('查找元素时发生错误: $e');

      return null;
    }
  }

  /// 开启界面检测
  Future<void> startDetection() async {
    try {
      await _channel.invokeMethod('startDetection');
      _isDetectionEnabled = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 开启界面检测失败: $e');
      _isDetectionEnabled = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 停止界面检测
  Future<void> stopDetection() async {
    try {
      await _channel.invokeMethod('stopDetection');
      _isDetectionEnabled = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 停止界面检测失败: $e');
      rethrow;
    }
  }

  /// 停止服务
  Future<void> stop() async {
    debugPrint('🛑 停止AccessibilityService');
    _isServiceRunning = false;
    _initialized = false;
    _isDetectionEnabled = false;

    // 移除方法调用处理器
    _channel.setMethodCallHandler(null);

    // 关闭事件流
    if (_initialized) {
      await _windowEventController.close();
      _windowEventController = StreamController<WindowEvent>.broadcast();
    }

    notifyListeners();
  }

  Future<List<ElementResult>> findElements(List<OverlayStyle> styles) async {
    try {
      final result =
          await _channel.invokeMethod<List<Object?>>('findElements', {
        'styles': styles.map((style) => style.toNative()).toList(),
      });

      return (result ?? [])
          .map(
              (e) => ElementResult.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('批量查找元素时发生错误: $e');

      return [];
    }
  }

  /// 更新规则匹配状态
  Future<void> updateRuleMatchStatus(bool hasMatch) async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('updateRuleMatchStatus', {
        'hasMatch': hasMatch,
      });
      debugPrint('✅ 已更新规则匹配状态: $hasMatch');
    } catch (e) {
      debugPrint('❌ 更新规则匹配状态失败: $e');
    }
  }

  Future<void> initialize() async {
    debugPrint('🚀 开始初始化AccessibilityService');

    // 重新初始化事件流
    if (_initialized) {
      await _windowEventController.close();
    }
    _windowEventController = StreamController<WindowEvent>.broadcast();

    _channel.setMethodCallHandler(_handleMethodCall);
    debugPrint('✅ 设置MethodCallHandler完成');

    // 只检查权限状态，不自动请求
    final hasPermission =
        await _channel.invokeMethod<bool>('checkAccessibilityPermission') ??
            false;
    _isServiceRunning = hasPermission;
    debugPrint('🔒 无障碍服务状态: ${hasPermission ? "已启用" : "未启用"}');

    if (hasPermission) {
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      _isServiceReady = true;
      debugPrint('✅ 无障碍服务已就绪');
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onWindowEvent':
        debugPrint('📨 收到窗口事件: ${call.arguments}');
        final event = WindowEvent.fromJson(call.arguments as String);
        _windowEventController.add(event);
        debugPrint('✅ 事件已广播: $event');
        break;
      default:
        debugPrint('❓ 未知的方法调用: ${call.method}');
    }
  }
}
