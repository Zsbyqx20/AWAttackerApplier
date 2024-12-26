import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

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
  Timer? _pingTimer;
  Timer? _reconnectTimer;

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
          // 处理消息
        },
        onError: (error) {
          _setWsStatus(ConnectionStatus.error);
          _scheduleReconnect();
        },
        onDone: () {
          _setWsStatus(ConnectionStatus.disconnected);
          _scheduleReconnect();
        },
      );

      // 启动心跳检测
      _startPingTimer();
    } catch (e) {
      _setWsStatus(ConnectionStatus.error);
      rethrow;
    }
  }

  // 断开 WebSocket 连接
  Future<void> _disconnectWebSocket() async {
    _stopPingTimer();
    _stopReconnectTimer();
    await _channel?.sink.close();
    _channel = null;
  }

  // 启动心跳检测
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _channel?.sink.add('ping');
    });
  }

  // 停止心跳检测
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
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
    _stopPingTimer();
    _stopReconnectTimer();
    _disconnectWebSocket();
    super.dispose();
  }
}
