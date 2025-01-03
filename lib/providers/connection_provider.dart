import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/window_event.dart';
import '../models/rule.dart';
import '../models/overlay_style.dart';
import '../services/overlay_service.dart';
import '../services/accessibility_service.dart';
import '../exceptions/overlay_exception.dart';
import 'rule_provider.dart';

enum ConnectionStatus {
  connected,
  disconnected,
}

class ConnectionProvider extends ChangeNotifier {
  bool _isServiceRunning = false;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  final RuleProvider _ruleProvider;
  late final OverlayService _overlayService;
  late final AccessibilityService _accessibilityService;
  StreamSubscription? _windowEventSubscription;

  ConnectionProvider(this._ruleProvider) {
    debugPrint('🏗️ 创建ConnectionProvider');
    _overlayService = OverlayService();
    _accessibilityService = AccessibilityService();
  }

  // 状态获取器
  bool get isServiceRunning => _isServiceRunning;
  ConnectionStatus get status => _status;

  void _setStatus(ConnectionStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
  }

  Future<void> _initialize() async {
    debugPrint('🚀 开始初始化ConnectionProvider');

    // 初始化AccessibilityService
    await _accessibilityService.initialize();
    debugPrint('✅ AccessibilityService初始化完成');

    // 设置窗口事件监听
    debugPrint('📡 开始设置窗口事件订阅');
    _windowEventSubscription?.cancel(); // 确保之前的订阅被取消
    _windowEventSubscription = _accessibilityService.windowEvents.listen(
      _handleWindowEvent,
      onError: (error) {
        debugPrint('❌ 窗口事件流错误: $error');
        _setStatus(ConnectionStatus.disconnected);
      },
      cancelOnError: false,
    );
    debugPrint('✅ 窗口事件订阅设置完成');
  }

  // 检查并启动服务
  Future<bool> checkAndConnect() async {
    if (_isServiceRunning) return true;

    try {
      // 确保初始化完成
      await _initialize();

      // 检查悬浮窗权限
      if (!await _overlayService.checkPermission()) {
        debugPrint('🔒 请求悬浮窗权限...');
        final granted = await _overlayService.requestPermission();
        if (!granted) {
          debugPrint('❌ 悬浮窗权限被拒绝');
          return false;
        }
      }

      // 启动悬浮窗服务
      final started = await _overlayService.start();
      if (!started) {
        debugPrint('❌ 启动悬浮窗服务失败');
        _setStatus(ConnectionStatus.disconnected);
        return false;
      }

      _isServiceRunning = true;
      _setStatus(ConnectionStatus.connected);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🌐 启动服务错误: $e');
      _setStatus(ConnectionStatus.disconnected);
      return false;
    }
  }

  // 停止服务
  Future<void> stop() async {
    try {
      await _overlayService.stop();
      _isServiceRunning = false;
      _setStatus(ConnectionStatus.disconnected);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 停止服务错误: $e');
      // 即使出错也要更新状态
      _isServiceRunning = false;
      _setStatus(ConnectionStatus.disconnected);
      notifyListeners();
    }
  }

  void _handleWindowEvent(WindowEvent event) {
    debugPrint('📥 ConnectionProvider收到窗口事件: $event');

    // 处理窗口事件
    if (!_isServiceRunning) {
      debugPrint('🚫 服务未运行，忽略窗口事件');
      return;
    }

    debugPrint('🔄 处理窗口事件: ${event.type}');
    if (event.type == 'WINDOW_STATE_CHANGED') {
      _handleWindowStateChanged(event);
    } else if (event.type == 'WINDOW_CONTENT_CHANGED' ||
        event.type == 'VIEW_SCROLLED') {
      _handleContentChanged(event);
    }
  }

  void _handleWindowStateChanged(WindowEvent event) async {
    debugPrint('🪟 收到窗口事件: ${event.packageName}/${event.activityName}');

    // 获取匹配的规则
    final matchedRules = _ruleProvider.rules.where((rule) {
      return rule.packageName == event.packageName &&
          rule.activityName == event.activityName &&
          rule.isEnabled;
    }).toList();

    if (matchedRules.isEmpty) {
      debugPrint('❌ 没有找到匹配的规则，清理现有悬浮窗');
      await _overlayService.removeAllOverlays();
      return;
    }

    debugPrint('✅ 找到 ${matchedRules.length} 个匹配规则');
    await _sendBatchQuickSearch(matchedRules);
  }

  void _handleContentChanged(WindowEvent event) async {
    debugPrint('🔄 收到内容变化事件: ${event.packageName}/${event.activityName}');

    // 内容变化时重新检查元素
    if (event.contentChanged) {
      debugPrint('📝 内容已变化，开始检查规则匹配');
      final matchedRules = _ruleProvider.rules.where((rule) {
        return rule.packageName == event.packageName &&
            rule.activityName == event.activityName &&
            rule.isEnabled;
      }).toList();

      if (matchedRules.isEmpty) {
        debugPrint('❌ 没有找到匹配的规则，清理现有悬浮窗');
        await _overlayService.removeAllOverlays();
        return;
      }

      debugPrint('✅ 找到 ${matchedRules.length} 个匹配规则，开始更新悬浮窗');
      await _sendBatchQuickSearch(matchedRules);
    } else {
      debugPrint('⏭️ 内容未变化，跳过处理');
    }
  }

  Future<void> _sendBatchQuickSearch(List<Rule> matchedRules) async {
    try {
      debugPrint('📤 准备批量查找元素...');

      // 收集所有规则中的UI Automator代码
      final List<String> uiAutomatorCodes = [];
      final List<OverlayStyle> styles = [];
      for (final rule in matchedRules) {
        for (final style in rule.overlayStyles) {
          if (style.uiAutomatorCode.isNotEmpty) {
            uiAutomatorCodes.add(style.uiAutomatorCode);
            styles.add(style);
          }
        }
      }

      if (uiAutomatorCodes.isEmpty) {
        debugPrint('❌ 没有找到需要查询的UI Automator代码');
        return;
      }

      // 批量查找元素
      final elements =
          await _accessibilityService.findElements(uiAutomatorCodes);

      // 处理查找结果
      for (var i = 0; i < elements.length; i++) {
        final result = elements[i];
        final style = styles[i];

        if (result.success &&
            result.coordinates != null &&
            result.size != null) {
          // 创建或更新悬浮窗
          final overlayStyle = style.copyWith(
            x: result.coordinates!['x']!.toDouble(),
            y: result.coordinates!['y']!.toDouble(),
            width: result.size!['width']!.toDouble(),
            height: result.size!['height']!.toDouble(),
          );

          final overlayResult = await _overlayService.createOverlay(
            'overlay_$i',
            overlayStyle,
          );

          if (!overlayResult.success) {
            debugPrint('❌ 创建悬浮窗失败: ${overlayResult.error}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ 批量查找元素时发生错误: $e');
      // 如果是权限错误，停止服务
      if (e is OverlayException &&
          e.code == OverlayException.permissionDeniedCode) {
        await stop();
      }
    }
  }

  @override
  void dispose() {
    _windowEventSubscription?.cancel();
    super.dispose();
  }
}
