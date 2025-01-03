import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/window_event.dart';
import '../models/element_result.dart';

class AccessibilityService extends ChangeNotifier {
  static const _channel =
      MethodChannel('com.mobilellm.awattackapplier/overlay_service');
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  bool _initialized = false;

  factory AccessibilityService() {
    debugPrint('🏭 获取AccessibilityService实例');
    return _instance;
  }

  AccessibilityService._internal() {
    debugPrint('🏗️ 创建AccessibilityService单例');
  }

  final _windowEventController = StreamController<WindowEvent>.broadcast();
  Stream<WindowEvent> get windowEvents => _windowEventController.stream;

  bool _isServiceRunning = false;
  bool get isServiceRunning => _isServiceRunning;

  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('⚠️ AccessibilityService已经初始化过，跳过');
      return;
    }

    debugPrint('🚀 开始初始化AccessibilityService');
    _channel.setMethodCallHandler(_handleMethodCall);
    debugPrint('✅ 设置MethodCallHandler完成');

    // 只检查权限状态，不自动请求
    final hasPermission =
        await _channel.invokeMethod<bool>('checkAccessibilityPermission') ??
            false;
    _isServiceRunning = hasPermission;
    debugPrint('🔒 无障碍服务状态: ${hasPermission ? "已启用" : "未启用"}');

    _initialized = true;
    notifyListeners();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint('🎯 收到方法调用: ${call.method}');
    switch (call.method) {
      case 'onWindowEvent':
        debugPrint('📨 收到窗口事件: ${call.arguments}');
        final eventData = jsonDecode(call.arguments as String);
        final event = WindowEvent.fromJson(eventData);
        _windowEventController.add(event);
        debugPrint('✅ 事件已广播: $event');
        break;
      default:
        debugPrint('❓ 未知的方法调用: ${call.method}');
    }
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

  Future<ElementResult?> findElement(String selectorCode) async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('findElement', {
        'selectorCode': selectorCode,
      });

      return result != null
          ? ElementResult.fromMap(Map<String, dynamic>.from(result))
          : null;
    } catch (e) {
      debugPrint('查找元素时发生错误: $e');
      return null;
    }
  }

  Future<List<ElementResult>> findElements(List<String> selectorCodes) async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('findElements', {
        'selectorCodes': selectorCodes,
      });

      return (result ?? [])
          .map((e) => ElementResult.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('批量查找元素时发生错误: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _windowEventController.close();
    super.dispose();
  }
}
