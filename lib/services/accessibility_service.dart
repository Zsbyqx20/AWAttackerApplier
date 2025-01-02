import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/window_event.dart';
import '../models/element_result.dart';

class AccessibilityService extends ChangeNotifier {
  static const _channel =
      MethodChannel('com.mobilellm.awattackapplier/accessibility_service');
  static final AccessibilityService _instance =
      AccessibilityService._internal();

  factory AccessibilityService() => _instance;

  AccessibilityService._internal();

  final _windowEventController = StreamController<WindowEvent>.broadcast();
  Stream<WindowEvent> get windowEvents => _windowEventController.stream;

  bool _isServiceRunning = false;
  bool get isServiceRunning => _isServiceRunning;

  Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethodCall);
    await checkAndRequestPermissions();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onWindowEvent':
        final eventData = jsonDecode(call.arguments as String);
        final event = WindowEvent.fromJson(eventData);
        _windowEventController.add(event);
        break;
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
