import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:grpc/grpc.dart';

import '../exceptions/overlay_exception.dart';
import '../generated/window_info.pbgrpc.dart';
import '../models/overlay_style.dart';
import '../models/rule.dart';
import '../models/window_event.dart';
import '../services/accessibility_service.dart';
import '../services/grpc_service.dart';
import '../services/overlay_service.dart';
import 'connection_provider_broadcast.dart';
import 'rule_provider.dart';
import '../models/rule_import.dart';

enum ConnectionStatus {
  connected,
  disconnected,
  connecting,
  disconnecting,
}

class CachedOverlayPosition {
  final String overlayId;
  final OverlayStyle style;

  CachedOverlayPosition({
    required this.overlayId,
    required this.style,
  });

  bool matchesPosition(OverlayStyle style) {
    return this.style == style;
  }
}

class ConnectionProvider extends ChangeNotifier with BroadcastCommandHandler {
  bool _isServiceRunning = false;
  bool _isStopping = false;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _grpcHost = 'auto';
  int _grpcPort = 50051;
  final RuleProvider _ruleProvider;
  final OverlayService _overlayService;
  final AccessibilityService _accessibilityService;
  final GrpcService _grpcService;
  StreamSubscription<WindowEvent>? _windowEventSubscription;
  final Map<String, CachedOverlayPosition> _overlayPositionCache = {};
  String? _currentDeviceId;
  Timer? _grpcStatusCheckTimer;

  ConnectionProvider(
    this._ruleProvider, {
    OverlayService? overlayService,
    AccessibilityService? accessibilityService,
    GrpcService? grpcService,
  })  : _overlayService = overlayService ?? OverlayService(),
        _accessibilityService = accessibilityService ?? AccessibilityService(),
        _grpcService = grpcService ?? GrpcService() {
    debugPrint('🏗️ 创建ConnectionProvider');
    // 监听AccessibilityService的变化
    _accessibilityService.addListener(_handleAccessibilityServiceChange);
    // 初始化广播命令处理器
    initializeBroadcastHandler();
    // 设置当前设备ID为本机
    _currentDeviceId = 'local';
  }

  // 状态获取器
  bool get isServiceRunning => _isServiceRunning;
  ConnectionStatus get status => _status;
  String? get currentDeviceId => _currentDeviceId;

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
      _setStatus(ConnectionStatus.connecting);

      // 确保初始化完成
      await _initialize();

      // 检查悬浮窗权限
      if (!await _overlayService.checkPermission()) {
        debugPrint('🔒 请求悬浮窗权限...');
        final granted = await _overlayService.requestPermission();
        if (!granted) {
          debugPrint('❌ 悬浮窗权限被拒绝');
          _setStatus(ConnectionStatus.disconnected);
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

      // 连接gRPC服务，使用配置的主机和端口
      try {
        await _grpcService.connect(_grpcHost, _grpcPort);
        debugPrint('✅ 已连接gRPC服务');
      } catch (e) {
        debugPrint('❌ gRPC服务连接失败: $e');
        // 停止已启动的服务
        _isServiceRunning = false;
        await _accessibilityService.stopDetection();
        await _overlayService.stop();
        _setStatus(ConnectionStatus.disconnected);
        notifyListeners();
        return false;
      }

      _isServiceRunning = true;
      _setStatus(ConnectionStatus.connected);
      _startGrpcStatusMonitor();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🌐 启动服务错误: $e');
      _isServiceRunning = false;
      await _accessibilityService.stopDetection();
      await _overlayService.stop();
      _setStatus(ConnectionStatus.disconnected);
      notifyListeners();
      return false;
    }
  }

  void _startGrpcStatusMonitor() {
    _grpcStatusCheckTimer?.cancel();
    _grpcStatusCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isServiceRunning) {
        timer.cancel();
        return;
      }

      final isConnected = _grpcService.isConnected;
      if (!isConnected && _status == ConnectionStatus.connected) {
        debugPrint('⚠️ 检测到gRPC连接断开，更新状态');
        _isServiceRunning = false; // 确保服务状态也更新
        _setStatus(ConnectionStatus.disconnected);
        // 停止服务
        _stopServices();
      } else if (isConnected && _status == ConnectionStatus.disconnected) {
        debugPrint('✅ 检测到gRPC重新连接，更新状态');
        _isServiceRunning = true;
        _setStatus(ConnectionStatus.connected);
      }
    });
  }

  // 抽取停止服务的逻辑为单独的方法
  Future<void> _stopServices() async {
    try {
      await _accessibilityService.stopDetection();
      await _overlayService.stop();
    } catch (e) {
      debugPrint('❌ 停止服务时发生错误: $e');
    }
  }

  // 停止服务
  Future<void> stop() async {
    try {
      _isStopping = true;
      _setStatus(ConnectionStatus.disconnecting);

      // 停止gRPC状态监听
      _grpcStatusCheckTimer?.cancel();
      _grpcStatusCheckTimer = null;

      // 先移除监听器，避免重复触发
      _accessibilityService.removeListener(_handleAccessibilityServiceChange);

      // 断开gRPC连接
      await _grpcService.disconnect();
      debugPrint('✅ 已断开gRPC连接');

      await _stopServices();
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
    debugPrint(
        '📊 当前服务状态: running=$_isServiceRunning, status=$_status, deviceId=$_currentDeviceId');

    if (!_isServiceRunning && event.type != WindowEventType.serviceConnected) {
      debugPrint('🚫 服务未运行，忽略窗口事件');
      return;
    }

    debugPrint('🔄 处理窗口事件: ${event.type}');

    switch (event.type) {
      case WindowEventType.serviceConnected:
        if (event.isFirstConnect) {
          debugPrint('🔌 服务首次连接，执行初始化');
          _initializeService();
        } else {
          debugPrint('🔌 服务重新连接，准备重建悬浮窗');
          // 检查服务状态
          if (_isServiceRunning && _status == ConnectionStatus.connected) {
            debugPrint('🔄 服务状态正常，开始重建悬浮窗');
            _rebuildOverlaysFromCache();
          } else {
            debugPrint('⚠️ 服务状态异常，跳过重建悬浮窗');
            // 可能需要重新初始化服务
            _initializeService();
          }
        }
        break;
      case WindowEventType.windowEvent:
        // 当收到窗口事件时，通过gRPC获取当前窗口信息
        debugPrint('🔍 准备通过gRPC获取窗口信息');
        _handleWindowStateChange();
        break;
    }
  }

  Future<void> _handleWindowStateChange() async {
    debugPrint('🔄 开始处理窗口状态变化');
    debugPrint('📊 gRPC服务状态: connected=${_grpcService.isConnected}');

    if (_currentDeviceId == null) {
      debugPrint('❌ 未设置设备ID，无法获取窗口信息');
      return;
    }

    try {
      // 获取当前窗口信息
      final response =
          await _grpcService.getCurrentWindowInfo(_currentDeviceId!);

      // 检查是否是服务停止消息
      if (response.type == ResponseType.SERVER_STOP) {
        debugPrint('📢 收到服务器停止消息，准备停止服务');
        await stop();
        return;
      }

      if (!response.success) {
        debugPrint('❌ 获取窗口信息失败: ${response.errorMessage}');
        return;
      }

      debugPrint('🪟 收到窗口信息: ${response.packageName}/${response.activityName}');

      // 获取匹配的规则
      final matchedRules = _ruleProvider.rules.where((rule) {
        return rule.packageName == response.packageName &&
            rule.activityName == response.activityName &&
            rule.isEnabled;
      }).toList();

      debugPrint('📋 规则匹配结果: 找到${matchedRules.length}个规则');

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
    } catch (e) {
      debugPrint('❌ 获取窗口信息时发生错误: $e');
      if (e is GrpcError) {
        // 检查是否是连接相关错误
        if (e.code == StatusCode.unavailable ||
            e.code == StatusCode.unknown ||
            e.message?.contains('Connection') == true ||
            e.message?.contains('terminated') == true) {
          debugPrint('⚠️ gRPC连接已断开，准备停止服务');
          await stop();
        }
      }
    }
  }

  Future<void> _sendBatchQuickSearch(List<Rule> matchedRules) async {
    try {
      debugPrint('📤 准备批量查找元素...');
      if (matchedRules.isEmpty) {
        debugPrint('❌ 没有找到需要查询的规则');
        return;
      }

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

      // 批量查找元素
      final elements = await _accessibilityService.findElements(styles);

      // 处理查找结果
      for (var i = 0; i < elements.length; i++) {
        final result = elements[i];
        final style = styles[i];
        final overlayId = 'overlay_$i';

        if (!result.success) {
          // 只在悬浮窗存在于缓存中时才尝试移除
          if (_overlayPositionCache.containsKey(overlayId)) {
            debugPrint('❌ 元素搜索失败，移除悬浮窗: $overlayId');
            popOverlayCache(overlayId);
            await _overlayService.removeOverlay(overlayId);
          }
          continue;
        }

        if (result.coordinates != null && result.size != null) {
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

          // 检查缓存
          final cachedPosition = _overlayPositionCache[overlayId];
          if (cachedPosition != null &&
              cachedPosition.matchesPosition(overlayStyle)) {
            debugPrint('📍 悬浮窗位置未变化，跳过更新: $overlayId');
            continue;
          }

          final overlayResult = await _overlayService.createOverlay(
            overlayId,
            overlayStyle,
          );

          if (overlayResult.success) {
            // 更新缓存
            _overlayPositionCache[overlayId] = CachedOverlayPosition(
              overlayId: overlayId,
              style: overlayStyle,
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
    _grpcStatusCheckTimer?.cancel();
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
  Future<void> handleStartService() async {
    debugPrint('🔄 通过广播启动服务...');
    // 通知UI更新状态
    _setStatus(ConnectionStatus.connecting);
    notifyListeners();

    try {
      final connected = await checkAndConnect();
      if (!connected) {
        debugPrint('❌ 服务启动失败');
        _setStatus(ConnectionStatus.disconnected);
        notifyListeners();
        throw Exception('Failed to connect to service');
      }
    } catch (e) {
      debugPrint('❌ 服务启动错误: $e');
      _setStatus(ConnectionStatus.disconnected);
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> handleStopService() async {
    debugPrint('🔄 通过广播停止服务...');
    // 通知UI更新状态
    _setStatus(ConnectionStatus.disconnecting);
    notifyListeners();

    try {
      await stop();
    } catch (e) {
      debugPrint('❌ 服务停止错误: $e');
      rethrow;
    } finally {
      _setStatus(ConnectionStatus.disconnected);
      notifyListeners();
    }
  }

  @override
  Future<void> handleSetGrpcConfig(String host, int port) async {
    debugPrint('🔄 通过广播设置gRPC配置: host=$host, port=$port');

    if (_isServiceRunning) {
      debugPrint('❌ 服务正在运行，无法更改gRPC配置');
      throw Exception('Cannot change gRPC config while service is running');
    }

    try {
      await setGrpcConfig(host, port);
      debugPrint('✅ gRPC配置更新成功');
      // 通知UI更新
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 更新gRPC配置失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> handleClearRules() async {
    debugPrint('🔄 通过广播清空规则...');

    if (_isServiceRunning) {
      debugPrint('❌ 服务正在运行，无法清空规则');
      throw Exception('Cannot clear rules while service is running');
    }

    try {
      await _ruleProvider.clearRules();
      debugPrint('✅ 规则清空成功');
      // 通知UI更新
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 清空规则失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> handleImportRules(String rulesJson) async {
    debugPrint('🔄 通过广播导入规则...');

    if (_isServiceRunning) {
      debugPrint('❌ 服务正在运行，无法导入规则');
      throw Exception('Cannot import rules while service is running');
    }

    try {
      // 解析规则
      final ruleImport = RuleImport.fromJson(rulesJson);
      final rules = ruleImport.rules;

      if (rules.isEmpty) {
        debugPrint('❌ 没有找到可导入的规则');
        throw Exception('No rules to import');
      }

      // 导入规则
      final results = await _ruleProvider.importRules(rules);

      // 统计导入结果
      final successCount = results.where((r) => r.isSuccess).length;
      final mergeableCount = results.where((r) => r.isMergeable).length;
      final conflictCount = results.where((r) => r.isConflict).length;

      // 生成导入报告
      final report = StringBuffer();
      report.writeln('导入完成:');
      if (successCount > 0) {
        report.writeln('✅ $successCount 个规则导入成功');
      }
      if (mergeableCount > 0) {
        report.writeln('🔄 $mergeableCount 个规则已合并');
      }
      if (conflictCount > 0) {
        report.writeln('❌ $conflictCount 个规则因冲突已跳过:');
        // 添加冲突详情
        results
            .where((r) => r.isConflict)
            .forEach((r) => report.writeln('  - ${r.errorMessage}'));
      }

      debugPrint('✅ 规则导入完成');
      debugPrint(report.toString());

      // 通知UI更新
      notifyListeners();

      // 如果全部失败则抛出异常
      if (successCount == 0 && mergeableCount == 0) {
        throw Exception(report.toString());
      }
    } catch (e) {
      debugPrint('❌ 导入规则失败: $e');
      rethrow;
    }
  }

  Future<void> _initializeService() async {
    debugPrint('🔄 开始初始化服务...');

    // 清理现有状态
    _overlayPositionCache.clear();
    await _overlayService.removeAllOverlays();

    // 重新设置事件订阅
    _setupEventSubscription();

    // 设置服务状态
    _setStatus(ConnectionStatus.connected);
    notifyListeners();

    debugPrint('✅ 服务初始化完成');
  }

  Future<void> _rebuildOverlaysFromCache() async {
    debugPrint('🔄 开始从缓存重建悬浮窗...');

    if (_overlayPositionCache.isEmpty) {
      debugPrint('ℹ️ 没有找到缓存的悬浮窗位置信息');
      return;
    }

    // 遍历缓存的悬浮窗位置信息
    for (final entry in _overlayPositionCache.entries) {
      final overlayId = entry.key;
      final position = entry.value;

      debugPrint('🎯 重建悬浮窗: $overlayId');

      try {
        // 使用缓存的位置信息重新创建悬浮窗
        final overlayStyle = position.style;

        final result = await _overlayService.createOverlay(
          overlayId,
          overlayStyle,
        );

        if (result.success) {
          debugPrint('✅ 悬浮窗重建成功: $overlayId');
        } else {
          debugPrint('❌ 重建悬浮窗失败: $overlayId, 错误: ${result.error}');
          // 从缓存中移除失败的项
          _overlayPositionCache.remove(overlayId);
        }
      } catch (e) {
        debugPrint('❌ 重建悬浮窗失败: $overlayId, 错误: $e');
        // 从缓存中移除失败的项
        _overlayPositionCache.remove(overlayId);
      }
    }

    debugPrint('✅ 悬浮窗重建完成');
  }

  // 获取当前窗口信息
  Future<WindowInfoResponse> getCurrentWindowInfo(String deviceId) {
    return _grpcService.getCurrentWindowInfo(deviceId);
  }

  // 获取无障碍树数据
  Future<Uint8List?> getAccessibilityTree(String deviceId) {
    return _grpcService.getAccessibilityTree(deviceId);
  }

  // 设置当前设备ID
  Future<void> setDeviceId(String deviceId) async {
    if (_currentDeviceId != deviceId) {
      _currentDeviceId = deviceId;
      if (_isServiceRunning) {
        // 如果服务正在运行，需要重新初始化
        await _initializeService();
      }
      notifyListeners();
    }
  }

  // 获取gRPC配置
  String get grpcHost => _grpcHost;
  int get grpcPort => _grpcPort;

  // 设置gRPC配置
  Future<void> setGrpcConfig(String host, int port) async {
    if (_isServiceRunning) {
      throw Exception('Cannot change gRPC config while service is running');
    }
    _grpcHost = host;
    _grpcPort = port;
    notifyListeners();
  }
}
