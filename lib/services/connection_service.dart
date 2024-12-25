import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';
import '../models/window_event.dart';
import 'rule_matching_service.dart';

/// 服务器连接状态
enum ConnectionStatus { connected, disconnected, connecting, error }

/// 连接服务类
class ConnectionService {
  // 单例实现
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  String _apiUrl = '';
  String _wsUrl = '';
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _isReconnecting = false;

  // 当前状态
  ConnectionStatus _currentApiStatus = ConnectionStatus.disconnected;
  ConnectionStatus _currentWsStatus = ConnectionStatus.disconnected;

  // 连接状态流
  final _apiStatusController = StreamController<ConnectionStatus>.broadcast();
  final _wsStatusController = StreamController<ConnectionStatus>.broadcast();

  // 窗口事件流
  final _windowEventController = StreamController<WindowEvent>.broadcast();
  Stream<WindowEvent> get windowEvents => _windowEventController.stream;

  Stream<ConnectionStatus> get apiStatus => _apiStatusController.stream;
  Stream<ConnectionStatus> get wsStatus => _wsStatusController.stream;

  // 获取当前状态
  ConnectionStatus get currentApiStatus => _currentApiStatus;
  ConnectionStatus get currentWsStatus => _currentWsStatus;

  bool _isServiceRunning = false;
  bool get isServiceRunning => _isServiceRunning;

  final _serviceStatusController = StreamController<bool>.broadcast();
  Stream<bool> get serviceStatus => _serviceStatusController.stream;

  final RuleMatchingService _ruleMatchingService = RuleMatchingService();

  /// 更新服务器地址
  void updateUrls(String apiUrl, String wsUrl) {
    _apiUrl = apiUrl;
    _wsUrl = wsUrl;
  }

  /// 检查 API 服务器健康状态（用于初始连接）
  Future<bool> checkApiHealth() async {
    try {
      _currentApiStatus = ConnectionStatus.connecting;
      _apiStatusController.add(_currentApiStatus);

      final response = await http
          .get(Uri.parse('$_apiUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isHealthy = data['status'] == 'healthy';
        _currentApiStatus =
            isHealthy ? ConnectionStatus.connected : ConnectionStatus.error;
        _apiStatusController.add(_currentApiStatus);
        return isHealthy;
      }

      _currentApiStatus = ConnectionStatus.error;
      _apiStatusController.add(_currentApiStatus);
      return false;
    } catch (e) {
      _currentApiStatus = ConnectionStatus.error;
      _apiStatusController.add(_currentApiStatus);
      return false;
    }
  }

  /// 连接 WebSocket 服务器
  Future<bool> connectWebSocket() async {
    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
    }

    try {
      _currentWsStatus = ConnectionStatus.connecting;
      _wsStatusController.add(_currentWsStatus);

      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      // 等待连接建立
      bool connected = false;
      final completer = Completer<bool>();

      // 监听消息
      _channel!.stream.listen(
        (message) {
          final data = json.decode(message);
          if (data['type'] == 'ping') {
            _sendPong();
          } else if (data['type'] == 'WINDOW_STATE_CHANGED') {
            final event = WindowEvent.fromJson(data);
            _windowEventController.add(event);
          }
          if (!connected) {
            connected = true;
            completer.complete(true);
          }
        },
        onError: (error) {
          _currentWsStatus = ConnectionStatus.error;
          _wsStatusController.add(_currentWsStatus);
          if (!connected) {
            completer.complete(false);
          }
          _scheduleReconnect();
        },
        onDone: () {
          _currentWsStatus = ConnectionStatus.disconnected;
          _wsStatusController.add(_currentWsStatus);
          if (!connected) {
            completer.complete(false);
          }
          _scheduleReconnect();
        },
      );

      // 等待5秒看是否能成功连接
      final success = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );

      if (success) {
        _currentWsStatus = ConnectionStatus.connected;
        _wsStatusController.add(_currentWsStatus);
        _startPingTimer();
      }

      return success;
    } catch (e) {
      _currentWsStatus = ConnectionStatus.error;
      _wsStatusController.add(_currentWsStatus);
      _scheduleReconnect();
      return false;
    }
  }

  /// 发送 pong 消息
  void _sendPong() {
    if (_channel != null && _wsStatusController.hasListener) {
      try {
        _channel!.sink.add(json.encode({'type': 'pong'}));
      } catch (e) {
        // 发送失败，可能连接已断开
        _scheduleReconnect();
      }
    }
  }

  /// 启动 ping 定时器
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // 只更新API状态，不触发重连
      _checkApiHealthStatus();
    });
  }

  /// 只检查API状态，不触发重连
  Future<void> _checkApiHealthStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$_apiUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isHealthy = data['status'] == 'healthy';
        _currentApiStatus =
            isHealthy ? ConnectionStatus.connected : ConnectionStatus.error;
      } else {
        _currentApiStatus = ConnectionStatus.error;
      }
      _apiStatusController.add(_currentApiStatus);
    } catch (e) {
      _currentApiStatus = ConnectionStatus.error;
      _apiStatusController.add(_currentApiStatus);
    }
  }

  /// 安排重连
  void _scheduleReconnect() {
    if (!_isReconnecting) {
      _isReconnecting = true;
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), () {
        _isReconnecting = false;
        reconnect();
      });
    }
  }

  /// 重新连接服务器
  Future<void> reconnect() async {
    // 只在WebSocket断开时重连WebSocket
    if (_currentWsStatus != ConnectionStatus.connected) {
      await connectWebSocket();
    }
  }

  /// 启动连接
  Future<void> start() async {
    if (kDebugMode) {
      print('ConnectionService: Starting services');
    }
    _isServiceRunning = true;
    _serviceStatusController.add(_isServiceRunning);

    // 启动规则匹配服务
    await _ruleMatchingService.start();

    // 重新连接
    await reconnect();
  }

  /// 停止连接
  Future<void> stop() async {
    if (kDebugMode) {
      print('ConnectionService: Stopping services');
    }
    _isServiceRunning = false;
    _serviceStatusController.add(_isServiceRunning);
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();

    // 停止规则匹配服务
    _ruleMatchingService.stop();

    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
      _channel = null;
    }
    _apiStatusController.add(ConnectionStatus.disconnected);
    _wsStatusController.add(ConnectionStatus.disconnected);
  }

  /// 释放资源
  void dispose() {
    if (kDebugMode) {
      print('ConnectionService: Disposing');
    }
    stop();
    _apiStatusController.close();
    _wsStatusController.close();
    _serviceStatusController.close();
    _windowEventController.close();
  }

  /// 检查并连接服务器
  Future<bool> checkAndConnect() async {
    if (_apiUrl.isEmpty || _wsUrl.isEmpty) {
      return false;
    }

    final apiHealthy = await checkApiHealth();
    if (!apiHealthy) {
      return false;
    }

    final wsConnected = await connectWebSocket();
    if (wsConnected) {
      await start();
    }
    return wsConnected;
  }
}
