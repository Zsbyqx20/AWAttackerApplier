import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../models/window_event.dart';
import '../models/rule.dart';
import '../models/overlay_style.dart';
import '../services/overlay_service.dart';
import 'rule_provider.dart';

enum ConnectionStatus {
  connected,
  disconnected,
  connecting,
  error,
}

class ConnectionProvider extends ChangeNotifier {
  String _apiUrl = '';
  String _wsUrl = '';
  bool _isServiceRunning = false;
  ConnectionStatus _apiStatus = ConnectionStatus.disconnected;
  ConnectionStatus _wsStatus = ConnectionStatus.disconnected;
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  final RuleProvider _ruleProvider;
  final OverlayService _overlayService;

  ConnectionProvider(this._ruleProvider) : _overlayService = OverlayService();

  // 状态获取器
  bool get isServiceRunning => _isServiceRunning;
  ConnectionStatus get apiStatus => _apiStatus;
  ConnectionStatus get wsStatus => _wsStatus;

  void _setApiStatus(ConnectionStatus status) {
    if (_apiStatus != status) {
      _apiStatus = status;
      notifyListeners();
    }
  }

  void _setWsStatus(ConnectionStatus status) {
    if (_wsStatus != status) {
      _wsStatus = status;
      notifyListeners();
    }
  }

  // 更新服务器地址
  void updateUrls(String apiUrl, String wsUrl) {
    _apiUrl = apiUrl;
    _wsUrl = wsUrl;
  }

  // 检查并连接服务器
  Future<bool> checkAndConnect() async {
    if (_isServiceRunning) return true;

    // 检查悬浮窗权限
    if (!await _overlayService.checkPermission()) {
      debugPrint('🔒 请求悬浮窗权限...');
      final granted = await _overlayService.requestPermission();
      if (!granted) {
        debugPrint('❌ 悬浮窗权限被拒绝');
        return false;
      }
    }

    _setApiStatus(ConnectionStatus.connecting);
    _setWsStatus(ConnectionStatus.connecting);

    try {
      // 检查 API 服务器
      final response = await http.get(Uri.parse('$_apiUrl/health'));
      if (response.statusCode != 200) {
        _setApiStatus(ConnectionStatus.error);
        _setWsStatus(ConnectionStatus.disconnected);
        return false;
      }
      _setApiStatus(ConnectionStatus.connected);

      // 连接 WebSocket 服务器
      await _connectWebSocket();

      _isServiceRunning = true;
      _overlayService.start(); // 启动悬浮窗服务
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🌐 连接错误: $e');
      _setApiStatus(ConnectionStatus.error);
      _setWsStatus(ConnectionStatus.error);
      return false;
    }
  }

  // 停止服务
  Future<void> stop() async {
    _isServiceRunning = false;
    await _disconnectWebSocket();
    _overlayService.stop(); // 停止悬浮窗服务
    _setApiStatus(ConnectionStatus.disconnected);
    _setWsStatus(ConnectionStatus.disconnected);
    notifyListeners();
  }

  // 连接 WebSocket
  Future<void> _connectWebSocket() async {
    await _disconnectWebSocket();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _setWsStatus(ConnectionStatus.connected);

      // 监听 WebSocket 消息
      _channel?.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'ping') {
              debugPrint('💓 收到服务器ping');
              _channel?.sink.add(jsonEncode({'type': 'pong'}));
            } else {
              _handleMessage(data);
            }
          } catch (e) {
            debugPrint('❌ 解析消息时发生错误: $e');
          }
        },
        onError: (error) {
          debugPrint('⚠️ WebSocket错误: $error');
          _setWsStatus(ConnectionStatus.error);
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('🔌 WebSocket连接已关闭');
          _setWsStatus(ConnectionStatus.disconnected);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('⚠️ WebSocket连接错误: $e');
      _setWsStatus(ConnectionStatus.error);
      rethrow;
    }
  }

  Future<void> _disconnectWebSocket() async {
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_isServiceRunning && _wsStatus != ConnectionStatus.connected) {
        _connectWebSocket();
      }
    });
  }

  void _handleMessage(dynamic message) {
    // 如果服务未运行，不处理任何消息
    if (!_isServiceRunning) {
      return;
    }

    try {
      final String type = message['type'] as String;
      switch (type) {
        case 'WINDOW_STATE_CHANGED':
          _handleWindowStateChanged(message);
          break;
        default:
          debugPrint('❓ 忽略未知消息类型: $type');
      }
    } catch (e) {
      debugPrint('⚠️ 处理消息时发生错误: $e');
    }
  }

  void _handleWindowStateChanged(dynamic message) async {
    // 如果服务未运行，不处理窗口状态变化
    if (!_isServiceRunning) {
      return;
    }

    try {
      final windowEvent = WindowEvent.fromJson(message);
      debugPrint(
          '🪟 收到窗口事件: ${windowEvent.packageName}/${windowEvent.activityName}');

      // 获取匹配的规则
      final matchedRules = _ruleProvider.rules.where((rule) {
        return rule.packageName == windowEvent.packageName &&
            rule.activityName == windowEvent.activityName &&
            rule.isEnabled;
      }).toList();

      if (matchedRules.isEmpty) {
        debugPrint('❌ 没有找到匹配的规则，清理现有悬浮窗');
        await _overlayService.removeAllOverlays();
        return;
      }

      debugPrint('✅ 找到 ${matchedRules.length} 个匹配规则');
      await _sendBatchQuickSearch(matchedRules);
    } catch (e) {
      debugPrint('🪟 处理窗口状态变化时发生错误: $e');
      // 发生错误时也清理悬浮窗
      await _overlayService.removeAllOverlays();
    }
  }

  Future<void> _sendBatchQuickSearch(List<Rule> matchedRules) async {
    // 如果服务未运行，不执行批量查询
    if (!_isServiceRunning) {
      return;
    }

    try {
      debugPrint('📤 准备发送批量查询请求...');

      // 收集所有规则中的UI Automator代码和对应的样式
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

      final response = await http.post(
        Uri.parse('$_apiUrl/batch/quick_search/uiautomator'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uiautomator_codes': uiAutomatorCodes}),
      );

      debugPrint('📥 收到响应: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ 请求失败: ${response.statusCode}');
        return;
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        debugPrint('❌ 响应表明失败: ${data['message']}');
        return;
      }

      final results = data['results'] as List;
      debugPrint('🎯 处理查询结果...');

      // 移除旧的悬浮窗
      await _overlayService.removeAllOverlays();

      // 创建新的悬浮窗
      for (var i = 0; i < results.length; i++) {
        final result = results[i];
        final style = styles[i];

        debugPrint('🎯 元素 ${i + 1}');
        if (result['success'] == true && result['visible'] == true) {
          final coordinates = result['coordinates'];
          final size = result['size'];

          // 计算最终位置和大小
          final finalX = (coordinates['x'] as int) + style.x;
          final finalY = (coordinates['y'] as int) + style.y;
          final finalWidth = (size['width'] as int) + style.width;
          final finalHeight = (size['height'] as int) + style.height;

          debugPrint('- 原始位置: (${coordinates['x']}, ${coordinates['y']})');
          debugPrint('- 原始大小: ${size['width']}x${size['height']}');
          debugPrint('- 偏移量: (${style.x}, ${style.y})');
          debugPrint('- 大小调整: ${style.width}x${style.height}');
          debugPrint('- 最终位置: ($finalX, $finalY)');
          debugPrint('- 最终大小: $finalWidth x $finalHeight');
          final finalStyle = style.copyWith(
            x: finalX,
            y: finalY,
            width: finalWidth,
            height: finalHeight,
          );

          debugPrint('🎯 创建悬浮窗...');
          final overlayResult = await _overlayService.createOverlay(
            'overlay_$i',
            finalStyle,
          );

          if (overlayResult.success) {
            debugPrint('✅ 悬浮窗创建成功');
          } else {
            debugPrint('❌ 悬浮窗创建失败: ${overlayResult.error}');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ 处理批量查询时发生错误: $e');
    }
  }
}
