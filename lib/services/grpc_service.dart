import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:grpc/grpc.dart';

import '../generated/accessibility.pbgrpc.dart';
import '../generated/window_info.pbgrpc.dart';
import 'accessibility_service.dart';

class GrpcService {
  static final GrpcService _instance = GrpcService._internal();
  factory GrpcService() => _instance;
  GrpcService._internal();

  ClientChannel? _channel;
  WindowInfoServiceClient? _client;
  AccessibilityServiceClient? _accessibilityClient;
  bool _isConnected = false;
  StreamController<ClientResponse>? _responseController;
  StreamSubscription<ServerCommand>? _commandSubscription;

  bool get isConnected => _isConnected;
  WindowInfoServiceClient? get client => _client;
  AccessibilityServiceClient? get accessibilityClient => _accessibilityClient;

  Future<void> connect(String host, int port) async {
    if (_isConnected) return;

    try {
      final effectiveHost = host == 'auto' ? '10.0.2.2' : host;
      debugPrint('📡 正在连接gRPC服务: $effectiveHost:$port');

      _channel = ClientChannel(
        effectiveHost,
        port: port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
          connectTimeout: Duration(seconds: 5),
          idleTimeout: Duration(seconds: 10),
        ),
      );

      _client = WindowInfoServiceClient(_channel!);
      _accessibilityClient = AccessibilityServiceClient(_channel!);
      debugPrint('✅ gRPC客户端创建成功');

      // 发送测试请求以验证连接
      await _client!.getCurrentWindowInfo(
        WindowInfoRequest()..deviceId = '',
      );
      debugPrint('✅ gRPC连接验证成功');

      // 建立双向流连接
      await _setupBidirectionalStream();
      debugPrint('✅ 双向流连接建立成功');

      _isConnected = true;
    } catch (e) {
      debugPrint('❌ gRPC连接失败: $e');
      _isConnected = false;
      await _channel?.shutdown();
      _channel = null;
      _client = null;
      _accessibilityClient = null;
      rethrow;
    }
  }

  Future<void> _setupBidirectionalStream() async {
    // 创建一个广播流控制器，这样多个监听器不会导致流关闭
    _responseController = StreamController<ClientResponse>.broadcast(
      onListen: () => debugPrint('🎧 响应流开始监听'),
      onCancel: () => debugPrint('🛑 响应流取消监听'),
    );

    try {
      debugPrint('🔄 开始建立双向流连接');

      // 创建一个初始的心跳响应，保持流活跃
      final heartbeatResponse = ClientResponse()
        ..deviceId = 'heartbeat'
        ..success = true;
      _responseController!.add(heartbeatResponse);

      // 设置定期发送心跳
      Timer.periodic(Duration(seconds: 30), (timer) {
        if (_isConnected && !_responseController!.isClosed) {
          _responseController!.add(heartbeatResponse);
          debugPrint('💓 发送心跳');
        } else {
          timer.cancel();
        }
      });

      final stream = _accessibilityClient!
          .streamAccessibility(_responseController!.stream);

      _commandSubscription = stream.listen(
        (command) async {
          debugPrint('📥 收到服务器命令: ${command.command}');
          if (command.command ==
              ServerCommand_CommandType.GET_ACCESSIBILITY_TREE) {
            await _handleGetAccessibilityTree(command.deviceId);
          }
        },
        onError: (Object error) {
          debugPrint('❌ 流错误: $error');
          // 只有在连接仍然活跃时才重连
          if (_isConnected && !_responseController!.isClosed) {
            _reconnectStream();
          }
        },
        onDone: () {
          debugPrint('📡 流连接已关闭');
          // 只有在连接仍然活跃时才重连
          if (_isConnected && !_responseController!.isClosed) {
            _reconnectStream();
          }
        },
      );

      debugPrint('✅ 双向流连接建立成功');
    } catch (e) {
      debugPrint('❌ 建立流连接失败: $e');
      _responseController?.close();
      rethrow;
    }
  }

  Future<void> _handleGetAccessibilityTree(String deviceId) async {
    try {
      debugPrint('🌳 正在获取无障碍树数据，设备ID: $deviceId');

      // Get data from AccessibilityService
      final accessibilityService = AccessibilityService();
      final rawOutput = await accessibilityService.getLatestState();

      if (rawOutput == null) {
        debugPrint('❌ 无法从 AccessibilityService 获取数据: 返回值为 null');
        _responseController?.add(ClientResponse()
          ..deviceId = deviceId
          ..success = false
          ..errorMessage = '无法获取无障碍树数据');
        return;
      }

      debugPrint('✅ 成功获取无障碍树数据: ${rawOutput.length} bytes');

      // Send response through stream
      _responseController?.add(ClientResponse()
        ..deviceId = deviceId
        ..success = true
        ..rawOutput = rawOutput);

      debugPrint('✅ 数据已通过流发送');
    } catch (e) {
      debugPrint('❌ 处理获取无障碍树命令失败: $e');
      _responseController?.add(ClientResponse()
        ..deviceId = deviceId
        ..success = false
        ..errorMessage = e.toString());
    }
  }

  void _reconnectStream() {
    debugPrint('🔄 准备重新建立流连接...');

    // 清理旧的连接
    _commandSubscription?.cancel();
    _responseController?.close();
    _commandSubscription = null;
    _responseController = null;

    // 如果仍然连接着，尝试重新建立流
    if (_isConnected) {
      debugPrint('🔄 开始重新建立流连接');
      Future.delayed(Duration(seconds: 1), () {
        _setupBidirectionalStream();
      });
    } else {
      debugPrint('❌ 连接已断开，不再重新建立流连接');
    }
  }

  Future<void> disconnect() async {
    debugPrint('🔌 开始断开连接');
    _isConnected = false; // 先标记为断开，防止重连

    _commandSubscription?.cancel();
    _responseController?.close();
    _commandSubscription = null;
    _responseController = null;

    await _channel?.shutdown();
    _channel = null;
    _client = null;
    _accessibilityClient = null;

    debugPrint('✅ 连接已完全断开');
  }

  Future<WindowInfoResponse> getCurrentWindowInfo(String deviceId) async {
    if (!_isConnected || _client == null) {
      debugPrint('❌ gRPC未连接，无法获取窗口信息');
      throw GrpcError.unavailable('Not connected to gRPC server');
    }

    try {
      final response = await _client!.getCurrentWindowInfo(
        WindowInfoRequest()..deviceId = deviceId,
      );
      return response;
    } catch (e) {
      debugPrint('❌ getCurrentWindowInfo请求失败: $e');
      if (e is GrpcError) {
        // 如果是连接相关错误，更新连接状态
        if (e.code == StatusCode.unavailable ||
            e.code == StatusCode.unknown ||
            e.message?.contains('Connection') == true) {
          debugPrint('⚠️ 检测到连接错误，标记为未连接');
          _isConnected = false;
        }
        rethrow;
      }
      throw GrpcError.unknown(e.toString());
    }
  }

  // 保留这个方法用于向后兼容
  Future<Uint8List?> getAccessibilityTree(String deviceId) async {
    if (!_isConnected || _accessibilityClient == null) {
      debugPrint('❌ gRPC未连接，无法获取无障碍树');
      return null;
    }

    try {
      debugPrint('🌳 正在获取无障碍树数据，设备ID: $deviceId');

      // Get data from AccessibilityService
      final accessibilityService = AccessibilityService();
      final rawOutput = await accessibilityService.getLatestState();
      if (rawOutput == null) {
        debugPrint('❌ 无法从 AccessibilityService 获取数据: 返回值为 null');
        return null;
      }
      debugPrint('✅ 成功获取无障碍树数据: ${rawOutput.length} bytes');

      // Send data to Rust server
      final updateRequest = UpdateAccessibilityDataRequest()
        ..deviceId = deviceId
        ..rawOutput = rawOutput;

      debugPrint('📤 正在发送数据到 Rust server...');
      final updateResponse =
          await _accessibilityClient!.updateAccessibilityData(updateRequest);

      if (!updateResponse.success) {
        debugPrint('❌ 发送无障碍树数据失败: ${updateResponse.errorMessage}');
        return null;
      }
      debugPrint('✅ 数据发送成功');

      return rawOutput;
    } catch (e) {
      debugPrint('❌ getAccessibilityTree请求失败: $e');
      if (e is GrpcError) {
        if (e.code == StatusCode.unavailable ||
            e.code == StatusCode.unknown ||
            e.message?.contains('Connection') == true) {
          debugPrint('⚠️ 检测到连接错误，标记为未连接');
          _isConnected = false;
        }
        rethrow;
      }
      throw GrpcError.unknown(e.toString());
    }
  }
}
