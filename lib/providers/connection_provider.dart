import 'dart:async';

import 'package:flutter/foundation.dart';

import '../exceptions/overlay_exception.dart';
import '../models/overlay_style.dart';
import '../models/rule.dart';
import '../models/window_event.dart';
import '../services/accessibility_service.dart';
import '../services/overlay_service.dart';
import 'connection_provider_broadcast.dart';
import 'rule_provider.dart';

enum ConnectionStatus {
  connected,
  disconnected,
}

class CachedOverlayPosition {
  final double x;
  final double y;
  final double width;
  final double height;
  final String overlayId;

  CachedOverlayPosition({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.overlayId,
  });

  bool matchesPosition(
      double newX, double newY, double newWidth, double newHeight) {
    return x == newX && y == newY && width == newWidth && height == newHeight;
  }
}

class ConnectionProvider extends ChangeNotifier with BroadcastCommandHandler {
  bool _isServiceRunning = false;
  bool _isStopping = false;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  final RuleProvider _ruleProvider;
  final OverlayService _overlayService;
  final AccessibilityService _accessibilityService;
  StreamSubscription<WindowEvent>? _windowEventSubscription;
  final Map<String, CachedOverlayPosition> _overlayPositionCache = {};

  ConnectionProvider(
    this._ruleProvider, {
    OverlayService? overlayService,
    AccessibilityService? accessibilityService,
  })  : _overlayService = overlayService ?? OverlayService(),
        _accessibilityService = accessibilityService ?? AccessibilityService() {
    debugPrint('🏗️ 创建ConnectionProvider');
    // 监听AccessibilityService的变化
    _accessibilityService.addListener(_handleAccessibilityServiceChange);
    // 初始化广播命令处理器
    initializeBroadcastHandler();
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

  // 处理AccessibilityService的变化
  void _handleAccessibilityServiceChange() {
    // 如果服务正在停止，不重新订阅
    if (_isStopping) {
      debugPrint('🚫 服务正在停止，不重新订阅事件');
      return;
    }
    debugPrint('📡 AccessibilityService发生变化，重新设置事件订阅');
    _setupEventSubscription();
  }

  // 设置事件订阅
  void _setupEventSubscription() {
    debugPrint('📡 开始设置窗口事件订阅');
    _windowEventSubscription?.cancel(); // 确保之前的订阅被取消
    _windowEventSubscription = _accessibilityService.windowEvents.listen(
      _handleWindowEvent,
      onError: (Object error) {
        debugPrint('❌ 窗口事件流错误: $error');
        _setStatus(ConnectionStatus.disconnected);
      },
      cancelOnError: false,
    );
    debugPrint('✅ 窗口事件订阅设置完成');
  }

  Future<void> _initialize() async {
    debugPrint('🚀 开始初始化ConnectionProvider');

    // 初始化AccessibilityService
    await _accessibilityService.initialize();
    debugPrint('✅ AccessibilityService初始化完成');

    // 设置窗口事件监听
    _setupEventSubscription();
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

      // 开启界面检测
      await _accessibilityService.startDetection();
      debugPrint('✅ 已开启界面检测');

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
      _isStopping = true;

      // 先移除监听器，避免重复触发
      _accessibilityService.removeListener(_handleAccessibilityServiceChange);

      // 先停止界面检测
      await _accessibilityService.stopDetection();
      debugPrint('✅ 已停止界面检测');

      await _overlayService.stop();
      await _accessibilityService.stop(); // 停止AccessibilityService
      _overlayPositionCache.clear(); // 清除位置缓存
      _windowEventSubscription?.cancel(); // 取消事件订阅
      _windowEventSubscription = null;
      _isServiceRunning = false;
      _setStatus(ConnectionStatus.disconnected);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 停止服务错误: $e');
      // 即使出错也要更新状态
      _isServiceRunning = false;
      _setStatus(ConnectionStatus.disconnected);
      notifyListeners();
    } finally {
      _isStopping = false;
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

    // 窗口状态变化事件（已经过哈希值验证）
    if (event.type == 'WINDOW_STATE_CHANGED') {
      _handleWindowStateChanged(event);
    }
    // 内容变化事件（替代原来的用户交互事件）
    else if (event.type == 'CONTENT_CHANGED') {
      _handleContentChanged(event);
    }
  }

  void _handleContentChanged(WindowEvent event) async {
    debugPrint('📄 收到内容变化事件: ${event.packageName}/${event.activityName}');

    // 获取匹配的规则
    final matchedRules = _ruleProvider.rules.where((rule) {
      return rule.packageName == event.packageName &&
          rule.activityName == event.activityName &&
          rule.isEnabled;
    }).toList();

    if (matchedRules.isEmpty) {
      debugPrint('❌ 没有找到匹配的规则，清理现有悬浮窗');
      _overlayPositionCache.clear(); // 清除位置缓存
      await _overlayService.removeAllOverlays();
      await _accessibilityService.updateRuleMatchStatus(false);
      return;
    }

    debugPrint('✅ 找到 ${matchedRules.length} 个匹配规则，开始检查元素');
    await _accessibilityService.updateRuleMatchStatus(true);
    await _sendBatchQuickSearch(matchedRules);
  }

  void _handleWindowStateChanged(WindowEvent event) async {
    debugPrint('🪟 收到窗口状态变化事件: ${event.packageName}/${event.activityName}');

    // 获取匹配的规则
    final matchedRules = _ruleProvider.rules.where((rule) {
      return rule.packageName == event.packageName &&
          rule.activityName == event.activityName &&
          rule.isEnabled;
    }).toList();

    if (matchedRules.isEmpty) {
      debugPrint('❌ 没有找到匹配的规则，清理现有悬浮窗');
      _overlayPositionCache.clear(); // 清除位置缓存
      await _overlayService.removeAllOverlays();
      await _accessibilityService.updateRuleMatchStatus(false);
      return;
    }

    debugPrint('✅ 找到 ${matchedRules.length} 个匹配规则，开始检查元素');
    await _accessibilityService.updateRuleMatchStatus(true);
    await _sendBatchQuickSearch(matchedRules);
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
          final overlayId = 'overlay_$i';
          final newX = result.coordinates!['x']!.toDouble();
          final newY = result.coordinates!['y']!.toDouble();
          final newWidth = result.size!['width']!.toDouble();
          final newHeight = result.size!['height']!.toDouble();

          // 检查坐标是否合法
          if (newX < 0 || newY < 0 || newWidth <= 0 || newHeight <= 0) {
            debugPrint(
                '❌ 元素坐标或尺寸不合法: ($newX, $newY), $newWidth x $newHeight，清理悬浮窗');
            popOverlayCache(overlayId);
            await _overlayService.removeOverlay(overlayId);
            continue;
          }

          // 检查缓存
          final cachedPosition = _overlayPositionCache[overlayId];
          if (cachedPosition != null &&
              cachedPosition.matchesPosition(newX, newY, newWidth, newHeight)) {
            debugPrint('📍 悬浮窗位置未变化，跳过更新: $overlayId');
            continue;
          }

          // 调整坐标和大小，考虑padding的影响
          final adjustedX = newX + style.x;
          final adjustedY = newY + style.y;
          final adjustedWidth = newWidth + style.width;
          final adjustedHeight = newHeight + style.height;

          debugPrint('📐 调整后的坐标和大小:');
          debugPrint('  原始: ($newX, $newY), $newWidth x $newHeight');
          debugPrint(
              '  调整: ($adjustedX, $adjustedY), $adjustedWidth x $adjustedHeight');
          debugPrint('  Padding: ${style.padding}');

          // 创建或更新悬浮窗
          final overlayStyle = style.copyWith(
            x: adjustedX,
            y: adjustedY,
            width: adjustedWidth,
            height: adjustedHeight,
          );

          final overlayResult = await _overlayService.createOverlay(
            overlayId,
            overlayStyle,
          );

          if (overlayResult.success) {
            // 更新缓存
            _overlayPositionCache[overlayId] = CachedOverlayPosition(
              x: newX,
              y: newY,
              width: newWidth,
              height: newHeight,
              overlayId: overlayId,
            );
            debugPrint('✅ 悬浮窗位置已更新并缓存: $overlayId');
          } else {
            debugPrint('❌ 创建悬浮窗失败: ${overlayResult.error}');
            // 清理旧的缓存和悬浮窗
            popOverlayCache(overlayId);
            await _overlayService.removeOverlay(overlayId);
            debugPrint('🧹 已清理旧的悬浮窗和缓存: $overlayId');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ 批量查找元素时发生错误: $e');
      if (e is OverlayException &&
          e.code == OverlayException.permissionDeniedCode) {
        await stop();
      }
    }
  }

  @override
  void dispose() {
    _isStopping = true;
    _windowEventSubscription?.cancel();
    _accessibilityService.removeListener(_handleAccessibilityServiceChange);
    super.dispose();
  }

  /// 移除指定悬浮窗的缓存
  /// 返回被移除的缓存，如果缓存不存在则返回null
  CachedOverlayPosition? popOverlayCache(String overlayId) {
    debugPrint('🗑️ 移除悬浮窗缓存: $overlayId');
    return _overlayPositionCache.remove(overlayId);
  }

  // 实现BroadcastCommandHandler的抽象方法
  @override
  Future<void> handleStartService() => checkAndConnect();

  @override
  Future<void> handleStopService() => stop();
}
