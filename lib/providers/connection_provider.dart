import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../models/window_event.dart';
import '../models/rule.dart';
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

  ConnectionProvider(this._ruleProvider);

  // 状态获取器
  bool get isServiceRunning => _isServiceRunning;
  ConnectionStatus get apiStatus => _apiStatus;
  ConnectionStatus get wsStatus => _wsStatus;

  // 更新服务器地址
  void updateUrls(String apiUrl, String wsUrl) {
    _apiUrl = apiUrl;
    _wsUrl = wsUrl;
  }

  // 检查并连接服务器
  Future<bool> checkAndConnect() async {
    if (_isServiceRunning) return true;

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
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Connection error: $e');
      }
      _setApiStatus(ConnectionStatus.error);
      _setWsStatus(ConnectionStatus.error);
      return false;
    }
  }

  // 停止服务
  Future<void> stop() async {
    _isServiceRunning = false;
    await _disconnectWebSocket();
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
              if (kDebugMode) {
                print('Received ping from server');
              }
              _channel?.sink.add(jsonEncode({'type': 'pong'}));
            } else {
              _handleMessage(data);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing message: $e');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('WebSocket error: $error');
          }
          _setWsStatus(ConnectionStatus.error);
          _scheduleReconnect();
        },
        onDone: () {
          if (kDebugMode) {
            print('WebSocket connection closed');
          }
          _setWsStatus(ConnectionStatus.disconnected);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('WebSocket connection error: $e');
      }
      _setWsStatus(ConnectionStatus.error);
      rethrow;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      // 1. 检查消息类型
      final String type = message['type'] as String;

      // 2. 处理不同类型的消息
      switch (type) {
        case 'WINDOW_STATE_CHANGED':
          _handleWindowStateChanged(message);
          break;
        default:
          if (kDebugMode) {
            print('Ignored message type: $type');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling message: $e');
      }
    }
  }

  void _handleWindowStateChanged(dynamic message) {
    try {
      // 1. 解析消息为WindowEvent对象
      final windowEvent = WindowEvent.fromJson(message);
      if (kDebugMode) {
        print(
            'Received window event: ${windowEvent.packageName}/${windowEvent.activityName}');
      }

      // 2. 获取当前规则列表
      final rules = _ruleProvider.rules;
      if (rules.isEmpty) {
        if (kDebugMode) {
          print('No rules defined');
        }
        return;
      }

      // 3. 匹配规则
      final matchedRules = rules.where((rule) {
        final packageMatches = rule.packageName == windowEvent.packageName;
        final activityMatches = rule.activityName == windowEvent.activityName;
        return packageMatches && activityMatches && rule.isEnabled;
      }).toList();

      // 4. 打印匹配结果
      if (matchedRules.isNotEmpty) {
        if (kDebugMode) {
          print('Found ${matchedRules.length} matching rules:');
          for (final rule in matchedRules) {
            print(
                '- ${rule.name} (${rule.overlayStyles.length} overlay styles)');
          }
        }
        // 5. 发送批量查询请求
        _sendBatchQuickSearch(matchedRules);
      } else {
        if (kDebugMode) {
          print('No matching rules found');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling window state changed: $e');
      }
    }
  }

  // 发送批量UI Automator查询请求
  Future<void> _sendBatchQuickSearch(List<Rule> matchedRules) async {
    try {
      // 收集所有规则中的UI Automator代码
      final List<String> uiAutomatorCodes = [];
      for (final rule in matchedRules) {
        for (final style in rule.overlayStyles) {
          if (style.uiAutomatorCode.isNotEmpty) {
            uiAutomatorCodes.add(style.uiAutomatorCode);
          }
        }
      }

      if (uiAutomatorCodes.isEmpty) {
        if (kDebugMode) {
          print('No UI Automator codes to search');
        }
        return;
      }

      // 构建请求体
      final requestBody = {
        'uiautomator_codes': uiAutomatorCodes,
      };

      // 发送HTTP POST请求
      if (kDebugMode) {
        print(
            'Sending batch quick search request: ${uiAutomatorCodes.length} codes');
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/batch/quick_search/uiautomator'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _handleBatchSearchResponse(responseData);
      } else {
        if (kDebugMode) {
          print('Error: HTTP ${response.statusCode}');
          print('Response: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending batch quick search request: $e');
      }
    }
  }

  void _handleBatchSearchResponse(Map<String, dynamic> responseData) {
    try {
      final bool success = responseData['success'] as bool;
      final String message = responseData['message'] as String;
      final List<dynamic> results = responseData['results'] as List<dynamic>;

      if (kDebugMode) {
        print('\nBatch quick search response:');
        print('Success: $success');
        print('Message: $message');
        print('Results:');
        for (var i = 0; i < results.length; i++) {
          final result = results[i];
          print('\nElement ${i + 1}:');
          print('- Success: ${result['success']}');
          print('- Message: ${result['message']}');
          if (result['success']) {
            final coordinates = result['coordinates'];
            final size = result['size'];
            print('- Position: (${coordinates['x']}, ${coordinates['y']})');
            print('- Size: ${size['width']}x${size['height']}');
            print('- Visible: ${result['visible']}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling batch search response: $e');
      }
    }
  }

  // 断开 WebSocket 连接
  Future<void> _disconnectWebSocket() async {
    _stopReconnectTimer();
    await _channel?.sink.close();
    _channel = null;
  }

  // 安排重连
  void _scheduleReconnect() {
    if (!_isServiceRunning) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_isServiceRunning) {
        _connectWebSocket();
      }
    });
  }

  // 停止重连定时器
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // 更新 API 状态
  void _setApiStatus(ConnectionStatus status) {
    _apiStatus = status;
    notifyListeners();
  }

  // 更新 WebSocket 状态
  void _setWsStatus(ConnectionStatus status) {
    _wsStatus = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopReconnectTimer();
    _disconnectWebSocket();
    super.dispose();
  }
}
