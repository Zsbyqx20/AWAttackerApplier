import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:grpc/grpc.dart';

import '../generated/accessibility.pbgrpc.dart';
import '../generated/window_info.pbgrpc.dart';
import 'accessibility_service.dart';

class GrpcService {
  ClientChannel? _channel;
  WindowInfoServiceClient? _client;
  AccessibilityServiceClient? _accessibilityClient;
  bool _isConnected = false;
  StreamController<ClientResponse>? _responseController;
  StreamSubscription<ServerCommand>? _commandSubscription;
  Timer? _heartbeatTimer;
  bool _isReconnecting = false;

  bool get isConnected => _isConnected;
  WindowInfoServiceClient? get client => _client;
  AccessibilityServiceClient? get accessibilityClient => _accessibilityClient;

  @visibleForTesting
  Duration get heartbeatDuration => const Duration(seconds: 30);

  @visibleForTesting
  StreamController<ClientResponse>? get responseController =>
      _responseController;

  @visibleForTesting
  bool get isReconnecting => _isReconnecting;

  GrpcService();

  Future<void> disconnect() async {
    debugPrint('🔌 开始断开连接');
    await _handleConnectionFailure();
    debugPrint('✅ 连接已断开');
  }

  Future<WindowInfoResponse> getCurrentWindowInfo(String deviceId) async {
    if (!_isConnected || _client == null) {
      debugPrint('❌ gRPC未连接，无法获取窗口信息');
      throw GrpcError.unavailable('Not connected to gRPC server');
    }

    final client = _client;
    if (client == null) {
      throw GrpcError.unavailable('Not connected to gRPC server');
    }

    try {
      return await client.getCurrentWindowInfo(
        WindowInfoRequest()..deviceId = deviceId,
      );
    } catch (e, stackTrace) {
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
      Error.throwWithStackTrace(
        GrpcError.unknown(e.toString()),
        stackTrace,
      );
    }
  }

  Future<Uint8List?> getAccessibilityTree(String deviceId) async {
    if (!_isConnected || _accessibilityClient == null) {
      debugPrint('❌ gRPC未连接，无法获取无障碍树');

      return null;
    }

    final client = _accessibilityClient;
    if (client == null) return null;

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
          await client.updateAccessibilityData(updateRequest);

      if (!updateResponse.success) {
        debugPrint('❌ 发送无障碍树数据失败: ${updateResponse.errorMessage}');

        return null;
      }
      debugPrint('✅ 数据发送成功');

      return rawOutput;
    } catch (e, stackTrace) {
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
      Error.throwWithStackTrace(
        GrpcError.unknown(e.toString()),
        stackTrace,
      );
    }
  }

  // 用于测试的工厂方法
  @visibleForTesting
  ClientChannel createChannel(String host, int port) {
    return ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        connectTimeout: Duration(seconds: 5),
        idleTimeout: Duration(seconds: 10),
      ),
    );
  }

  @visibleForTesting
  WindowInfoServiceClient createWindowInfoClient(ClientChannel channel) {
    return WindowInfoServiceClient(channel);
  }

  @visibleForTesting
  AccessibilityServiceClient createAccessibilityClient(ClientChannel channel) {
    return AccessibilityServiceClient(channel);
  }

  Future<void> connect(String host, int port) async {
    if (_isConnected) return;

    try {
      final effectiveHost = host == 'auto' ? '10.0.2.2' : host;
      debugPrint('📡 开始连接gRPC服务: $effectiveHost:$port');

      final channel = createChannel(effectiveHost, port);
      _channel = channel;
      _client = createWindowInfoClient(channel);
      _accessibilityClient = createAccessibilityClient(channel);

      final client = _client;
      if (client == null) {
        throw GrpcError.internal('Failed to create client');
      }

      // 发送测试请求以验证连接，添加超时处理
      try {
        await Future.any<void>([
          client
              .getCurrentWindowInfo(
                WindowInfoRequest()..deviceId = '',
              )
              // ignore: no-empty-block
              .then((_) {}),
          Future<void>.delayed(const Duration(seconds: 3)).then((_) {
            throw GrpcError.deadlineExceeded('Connection timeout');
          }),
        ]);
        debugPrint('✅ gRPC基础连接已建立');
      } catch (e) {
        debugPrint('❌ gRPC连接失败: $e');
        rethrow;
      }

      // 建立双向流连接
      await _setupBidirectionalStream();
      _isConnected = true;
      debugPrint('✅ gRPC服务连接完成');
    } catch (e) {
      await _handleConnectionFailure();
      rethrow;
    }
  }

  /// 处理连接失败的清理工作
  Future<void> _handleConnectionFailure() async {
    _isConnected = false;

    // 先清理资源
    await _safeCleanup();

    // 再关闭和清理channel相关资源
    await _channel?.shutdown();
    _channel = null;
    _client = null;
    _accessibilityClient = null;
  }

  Future<void> _setupBidirectionalStream() async {
    debugPrint('🔄 开始建立双向流连接');

    // 确保在开始前资源是清理的
    await _safeCleanup();

    try {
      final controller = StreamController<ClientResponse>.broadcast();
      _responseController = controller;

      // 创建一个初始的心跳响应
      final heartbeatResponse = ClientResponse()
        ..deviceId = 'heartbeat'
        ..success = true;

      // 设置新的心跳定时器
      _heartbeatTimer = Timer.periodic(heartbeatDuration, (timer) {
        if (!_isConnected) {
          timer.cancel();

          return;
        }

        if (controller.isClosed) {
          timer.cancel();

          return;
        }

        try {
          controller.add(heartbeatResponse);
          debugPrint('💓 发送心跳');
        } catch (e) {
          debugPrint('❌ 心跳发送失败: $e');
          timer.cancel();
        }
      });

      final client = _accessibilityClient;
      if (client == null) {
        throw GrpcError.internal('Accessibility client not initialized');
      }

      final stream = client.streamAccessibility(controller.stream);

      _commandSubscription = stream.listen(
        (command) async {
          debugPrint('📥 收到服务器命令: ${command.command}');
          if (command.command ==
              ServerCommand_CommandType.GET_ACCESSIBILITY_TREE) {
            await _handleGetAccessibilityTree(command.deviceId);
          }
        },
        onError: (Object error) {
          debugPrint('❌ 流连接错误: $error');
          _isConnected = false;
          if (!_isReconnecting) {
            _reconnectStream();
          }
        },
        onDone: () {
          debugPrint('📡 流连接已关闭');
          _isConnected = false;
          if (!_isReconnecting) {
            _reconnectStream();
          }
        },
      );

      debugPrint('✅ 双向流连接已建立');
    } catch (e) {
      debugPrint('❌ 双向流连接失败: $e');
      _isConnected = false;
      await _safeCleanup();
      rethrow;
    }
  }

  Future<void> _reconnectStream() async {
    if (_isReconnecting) {
      debugPrint('🚫 已在重连中');

      return;
    }

    debugPrint('🔄 开始重连...');
    _isReconnecting = true;

    try {
      await _safeCleanup();

      // 验证基础连接是否正常
      try {
        final client = _client;
        if (client == null) {
          debugPrint('❌ 客户端未初始化，需要完全重连');
          await _handleConnectionFailure();

          return;
        }

        await client.getCurrentWindowInfo(WindowInfoRequest()..deviceId = '');
      } catch (e) {
        debugPrint('❌ 基础连接已断开，需要完全重连');
        await _handleConnectionFailure();

        return;
      }

      await Future<void>.delayed(const Duration(seconds: 2));

      try {
        await _setupBidirectionalStream();
        _isConnected = true;
        debugPrint('✅ 重连成功');
      } catch (e) {
        debugPrint('❌ 重连失败: $e');
        await _handleConnectionFailure();
      }
    } catch (e) {
      await _handleConnectionFailure();
    } finally {
      _isReconnecting = false;
    }
  }

  // 安全的清理资源方法
  Future<void> _safeCleanup() async {
    debugPrint('🧹 清理资源...');

    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    await Future<void>.delayed(const Duration(milliseconds: 100));

    await _commandSubscription?.cancel();
    _commandSubscription = null;

    await Future<void>.delayed(const Duration(milliseconds: 100));

    final controller = _responseController;
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
    _responseController = null;

    debugPrint('✅ 资源清理完成');
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
}
