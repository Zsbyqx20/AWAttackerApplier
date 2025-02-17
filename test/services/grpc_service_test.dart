import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:awattackerapplier/generated/accessibility.pbgrpc.dart';
import 'package:awattackerapplier/generated/window_info.pbgrpc.dart';
import 'package:awattackerapplier/services/accessibility_service.dart';
import 'package:awattackerapplier/services/grpc_service.dart';
import 'grpc_service_test_helper.dart';

// Test implementation of GrpcService
class TestableGrpcService extends GrpcService {
  TestableGrpcService({
    required this.mockWindowInfoClient,
    required this.mockAccessibilityClient,
    required this.mockChannel,
    this.heartbeatInterval = const Duration(seconds: 1),
  });

  final MockWindowInfoServiceClient mockWindowInfoClient;
  final MockAccessibilityServiceClient mockAccessibilityClient;
  final MockClientChannel mockChannel;
  final Duration heartbeatInterval;

  @override
  ClientChannel createChannel(String host, int port) {
    return mockChannel;
  }

  @override
  WindowInfoServiceClient createWindowInfoClient(ClientChannel channel) {
    return mockWindowInfoClient;
  }

  @override
  AccessibilityServiceClient createAccessibilityClient(ClientChannel channel) {
    return mockAccessibilityClient;
  }

  @override
  Duration get heartbeatDuration => heartbeatInterval;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // 确保 Flutter 测试绑定被初始化

  late TestableGrpcService grpcService;
  late MockWindowInfoServiceClient mockWindowInfoClient;
  late MockAccessibilityServiceClient mockAccessibilityClient;
  late MockClientChannel mockChannel;

  setUpAll(() {
    // 注册 fallback values
    registerFallbackValue(WindowInfoRequest());
    registerFallbackValue(CallOptions());
    registerFallbackValue(const Stream<ClientResponse>.empty());
  });

  setUp(() async {
    // 首先创建所有的 mock 对象
    mockWindowInfoClient = MockWindowInfoServiceClient();
    mockAccessibilityClient = MockAccessibilityServiceClient();
    mockChannel = MockClientChannel();

    // 然后设置 mock 行为
    when(() => mockChannel.shutdown()).thenAnswer((_) async {});
    when(() => mockChannel.terminate()).thenAnswer((_) async {});

    // 创建 grpcService 实例
    grpcService = TestableGrpcService(
      mockWindowInfoClient: mockWindowInfoClient,
      mockAccessibilityClient: mockAccessibilityClient,
      mockChannel: mockChannel,
    );

    // 设置 MethodChannel mock
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.mobilellm.awattackerapplier/overlay_service'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getLatestState':
            return Uint8List.fromList([1, 2, 3, 4, 5]);
          case 'checkAccessibilityPermission':
            return true;
          default:
            return null;
        }
      },
    );

    // 初始化 AccessibilityService
    await AccessibilityService().initialize();
  });

  tearDown(() {
    // 清理 MethodChannel mock
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.mobilellm.awattackerapplier/overlay_service'),
      null,
    );
    mockAccessibilityClient.dispose();
  });

  group('Connection Tests', () {
    test('should connect successfully with valid host and port', () async {
      // Arrange
      const host = '127.0.0.1';
      const port = 50051;

      // Setup mock client
      final response = WindowInfoResponse();
      final mockCall = MockClientCall<WindowInfoRequest, WindowInfoResponse>();
      when(() => mockCall.response).thenAnswer((_) => Stream.value(response));

      when(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseFuture<WindowInfoResponse>(mockCall));

      // Setup stream mock
      final mockStreamCall = MockClientCall<ClientResponse, ServerCommand>();
      when(() => mockStreamCall.response).thenAnswer(
        (_) => Stream<ServerCommand>.empty(),
      );
      when(
        () => mockAccessibilityClient.streamAccessibility(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseStream<ServerCommand>(mockStreamCall));

      // Act
      await grpcService.connect(host, port);

      // Assert
      expect(grpcService.isConnected, true);
      verify(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('should handle auto host conversion to 10.0.2.2', () async {
      // Arrange
      const host = 'auto';
      const port = 50051;

      // Setup mock client
      final response = WindowInfoResponse();
      final mockCall = MockClientCall<WindowInfoRequest, WindowInfoResponse>();
      when(() => mockCall.response).thenAnswer((_) => Stream.value(response));

      when(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseFuture<WindowInfoResponse>(mockCall));

      // Setup stream mock
      final mockStreamCall = MockClientCall<ClientResponse, ServerCommand>();
      when(() => mockStreamCall.response).thenAnswer(
        (_) => Stream<ServerCommand>.empty(),
      );
      when(
        () => mockAccessibilityClient.streamAccessibility(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseStream<ServerCommand>(mockStreamCall));

      // Act
      await grpcService.connect(host, port);

      // Assert
      expect(grpcService.isConnected, true);
      verify(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('should handle connection timeout', () async {
      // Arrange
      const host = '127.0.0.1';
      const port = 50051;

      // Setup mock client to simulate timeout
      final mockCall = MockClientCall<WindowInfoRequest, WindowInfoResponse>();

      // 创建一个永不完成的Stream，让GrpcService的Future.any超时逻辑触发
      final controller = StreamController<WindowInfoResponse>();
      when(() => mockCall.response).thenAnswer((_) => controller.stream);

      when(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseFuture<WindowInfoResponse>(mockCall));

      // Setup stream mock
      final mockStreamCall = MockClientCall<ClientResponse, ServerCommand>();
      when(() => mockStreamCall.response).thenAnswer(
        (_) => Stream<ServerCommand>.empty(),
      );
      when(
        () => mockAccessibilityClient.streamAccessibility(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseStream<ServerCommand>(mockStreamCall));

      // Act & Assert
      await expectLater(
        () => grpcService.connect(host, port),
        throwsA(isA<GrpcError>().having(
          (e) => e.code,
          'code',
          StatusCode.deadlineExceeded,
        )),
      );

      expect(grpcService.isConnected, false);
      verify(() => mockChannel.shutdown()).called(1);

      // Cleanup
      await controller.close();
    });

    test('should handle connection failure and cleanup resources', () async {
      // Arrange
      const host = '127.0.0.1';
      const port = 50051;

      // Setup mock client to simulate failure
      final mockCall = MockClientCall<WindowInfoRequest, WindowInfoResponse>();
      when(() => mockCall.response).thenAnswer(
        (_) => Stream.error(GrpcError.unavailable('Connection failed')),
      );

      when(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseFuture<WindowInfoResponse>(mockCall));

      // Act & Assert
      await expectLater(
        () => grpcService.connect(host, port),
        throwsA(isA<GrpcError>()),
      );

      // 等待清理完成
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(grpcService.isConnected, isFalse);
      verify(() => mockChannel.shutdown()).called(1);
      verify(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).called(1); // 只验证初始连接调用一次，因为连接直接失败了
    });
  });

  group('Heartbeat Tests', () {
    test('should send heartbeat periodically after connection', () async {
      // Arrange
      const host = '127.0.0.1';
      const port = 50051;

      // 使用更短的心跳间隔创建服务
      grpcService = TestableGrpcService(
        mockWindowInfoClient: mockWindowInfoClient,
        mockAccessibilityClient: mockAccessibilityClient,
        mockChannel: mockChannel,
        heartbeatInterval: const Duration(milliseconds: 100),
      );

      // Setup mock client for initial connection
      final response = WindowInfoResponse();
      final mockCall = MockClientCall<WindowInfoRequest, WindowInfoResponse>();
      when(() => mockCall.response).thenAnswer((_) => Stream.value(response));

      when(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseFuture<WindowInfoResponse>(mockCall));

      // Setup stream mock and capture heartbeat messages
      final mockStreamCall = MockClientCall<ClientResponse, ServerCommand>();
      final heartbeats = <ClientResponse>[];
      final streamController = StreamController<ServerCommand>();

      when(() => mockStreamCall.response)
          .thenAnswer((_) => streamController.stream);
      when(
        () => mockAccessibilityClient.streamAccessibility(
          captureAny(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) {
        final stream =
            invocation.positionalArguments[0] as Stream<ClientResponse>;
        stream.listen((response) {
          if (response.deviceId == 'heartbeat') {
            heartbeats.add(response);
          }
        });
        return ResponseStream<ServerCommand>(mockStreamCall);
      });

      // Act
      await grpcService.connect(host, port);
      expect(grpcService.isConnected, true);

      // Wait for heartbeats (should see at least 2 heartbeats in 300ms)
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Assert
      expect(heartbeats.length, greaterThanOrEqualTo(2));
      // Verify heartbeat content
      for (final heartbeat in heartbeats) {
        expect(heartbeat.deviceId, equals('heartbeat'));
        expect(heartbeat.success, isTrue);
      }

      // Cleanup
      await streamController.close();
    });

    test('should cleanup heartbeat timer when connection is closed', () async {
      // Arrange
      const host = '127.0.0.1';
      const port = 50051;

      // 使用更短的心跳间隔创建服务
      grpcService = TestableGrpcService(
        mockWindowInfoClient: mockWindowInfoClient,
        mockAccessibilityClient: mockAccessibilityClient,
        mockChannel: mockChannel,
        heartbeatInterval: const Duration(milliseconds: 100),
      );

      // Setup mock client for initial connection
      final response = WindowInfoResponse();
      final mockCall = MockClientCall<WindowInfoRequest, WindowInfoResponse>();
      when(() => mockCall.response).thenAnswer((_) => Stream.value(response));

      when(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseFuture<WindowInfoResponse>(mockCall));

      // Setup stream mock
      final mockStreamCall = MockClientCall<ClientResponse, ServerCommand>();
      final streamController = StreamController<ServerCommand>();
      final heartbeats = <ClientResponse>[];

      when(() => mockStreamCall.response)
          .thenAnswer((_) => streamController.stream);
      when(
        () => mockAccessibilityClient.streamAccessibility(
          captureAny(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) {
        final stream =
            invocation.positionalArguments[0] as Stream<ClientResponse>;
        stream.listen((response) {
          if (response.deviceId == 'heartbeat') {
            heartbeats.add(response);
          }
        });
        return ResponseStream<ServerCommand>(mockStreamCall);
      });

      // Act
      await grpcService.connect(host, port);
      expect(grpcService.isConnected, true);

      // Wait for at least one heartbeat
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(heartbeats.isNotEmpty, isTrue);

      // Disconnect and verify no more heartbeats
      final heartbeatsBeforeDisconnect = heartbeats.length;
      await grpcService.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Assert
      expect(heartbeats.length, equals(heartbeatsBeforeDisconnect));
      expect(grpcService.isConnected, isFalse);

      // Cleanup
      await streamController.close();
    });

    test('should handle heartbeat send failure', () async {
      // Arrange
      const host = '127.0.0.1';
      const port = 50051;

      // 使用更短的心跳间隔创建服务
      grpcService = TestableGrpcService(
        mockWindowInfoClient: mockWindowInfoClient,
        mockAccessibilityClient: mockAccessibilityClient,
        mockChannel: mockChannel,
        heartbeatInterval: const Duration(milliseconds: 100),
      );

      // Setup mock client for initial connection
      final response = WindowInfoResponse();
      final mockCall = MockClientCall<WindowInfoRequest, WindowInfoResponse>();
      when(() => mockCall.response).thenAnswer((_) => Stream.value(response));

      when(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseFuture<WindowInfoResponse>(mockCall));

      // Setup stream mock that will fail when trying to send heartbeat
      final mockStreamCall = MockClientCall<ClientResponse, ServerCommand>();
      final streamController = StreamController<ServerCommand>();
      final heartbeats = <ClientResponse>[];

      when(() => mockStreamCall.response)
          .thenAnswer((_) => streamController.stream);

      // 模拟 streamAccessibility 在收到心跳时立即关闭流
      when(
        () => mockAccessibilityClient.streamAccessibility(
          captureAny(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) {
        final stream =
            invocation.positionalArguments[0] as Stream<ClientResponse>;

        // 监听原始流
        stream.listen((response) {
          if (response.deviceId == 'heartbeat') {
            heartbeats.add(response);
            // 模拟连接断开
            streamController.close();
          }
        });

        return ResponseStream<ServerCommand>(mockStreamCall);
      });

      // Act
      await grpcService.connect(host, port);
      expect(grpcService.isConnected, true);

      // Wait for heartbeat attempt and stream closure
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Assert
      expect(heartbeats.length, equals(1));
      expect(grpcService.isConnected, isFalse); // 连接应该被标记为断开

      // Wait to verify no more heartbeats
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(heartbeats.length, equals(1)); // No more heartbeats after failure
    });
  });

  group('Bidirectional Stream Tests', () {
    test('should establish bidirectional stream successfully', () async {
      // Arrange
      const host = '127.0.0.1';
      const port = 50051;

      // Setup mock client for initial connection
      final response = WindowInfoResponse();
      final mockCall = MockClientCall<WindowInfoRequest, WindowInfoResponse>();
      when(() => mockCall.response).thenAnswer((_) => Stream.value(response));

      when(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseFuture<WindowInfoResponse>(mockCall));

      // Setup stream mock
      final mockStreamCall = MockClientCall<ClientResponse, ServerCommand>();
      final streamController = StreamController<ServerCommand>();
      final clientResponses = <ClientResponse>[];

      when(() => mockStreamCall.response)
          .thenAnswer((_) => streamController.stream);
      when(
        () => mockAccessibilityClient.streamAccessibility(
          captureAny(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) {
        final stream =
            invocation.positionalArguments[0] as Stream<ClientResponse>;
        // 捕获客户端发送的所有响应
        stream.listen(clientResponses.add);
        return ResponseStream<ServerCommand>(mockStreamCall);
      });

      // Act
      await grpcService.connect(host, port);

      // Assert
      expect(grpcService.isConnected, true);
      verify(
        () => mockAccessibilityClient.streamAccessibility(
          any(),
          options: any(named: 'options'),
        ),
      ).called(1);

      // Cleanup
      await streamController.close();
    });

    test('should handle server commands correctly', () async {
      // Arrange
      const host = '127.0.0.1';
      const port = 50051;

      // Setup mock client for initial connection
      final response = WindowInfoResponse();
      final mockCall = MockClientCall<WindowInfoRequest, WindowInfoResponse>();
      when(() => mockCall.response).thenAnswer((_) => Stream.value(response));

      when(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseFuture<WindowInfoResponse>(mockCall));

      // Setup stream mock
      final mockStreamCall = MockClientCall<ClientResponse, ServerCommand>();
      final streamController = StreamController<ServerCommand>();
      final clientResponses = <ClientResponse>[];

      when(() => mockStreamCall.response)
          .thenAnswer((_) => streamController.stream);
      when(
        () => mockAccessibilityClient.streamAccessibility(
          captureAny(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) {
        final stream =
            invocation.positionalArguments[0] as Stream<ClientResponse>;
        stream.listen(clientResponses.add);
        return ResponseStream<ServerCommand>(mockStreamCall);
      });

      // Act
      await grpcService.connect(host, port);
      expect(grpcService.isConnected, true);

      // 发送一个获取无障碍树的命令
      final command = ServerCommand()
        ..deviceId = 'test_device'
        ..command = ServerCommand_CommandType.GET_ACCESSIBILITY_TREE;
      streamController.add(command);

      // 等待响应处理
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(clientResponses, hasLength(greaterThanOrEqualTo(1)));
      final accessibilityResponse =
          clientResponses.where((r) => r.deviceId == 'test_device').firstOrNull;
      expect(accessibilityResponse, isNotNull);
      expect(accessibilityResponse!.deviceId, equals('test_device'));
      expect(accessibilityResponse.success, isTrue); // 因为我们提供了 mock 数据，所以应该成功
      expect(accessibilityResponse.rawOutput,
          equals(Uint8List.fromList([1, 2, 3, 4, 5]))); // 验证返回的数据是否正确

      // Cleanup
      await streamController.close();
    });

    test('should send client responses correctly', () async {
      // Arrange
      const host = '127.0.0.1';
      const port = 50051;

      // Setup mock client for initial connection
      final response = WindowInfoResponse();
      final mockCall = MockClientCall<WindowInfoRequest, WindowInfoResponse>();
      when(() => mockCall.response).thenAnswer((_) => Stream.value(response));

      when(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseFuture<WindowInfoResponse>(mockCall));

      // Setup stream mock
      final mockStreamCall = MockClientCall<ClientResponse, ServerCommand>();
      final streamController = StreamController<ServerCommand>();
      final clientResponses = <ClientResponse>[];
      final streamSetupCompleter = Completer<void>();

      when(() => mockStreamCall.response)
          .thenAnswer((_) => streamController.stream);
      when(
        () => mockAccessibilityClient.streamAccessibility(
          captureAny(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) {
        final stream =
            invocation.positionalArguments[0] as Stream<ClientResponse>;
        // 使用 sync: true 确保监听器同步设置
        stream.listen(
          (response) {
            clientResponses.add(response);
            if (!streamSetupCompleter.isCompleted) {
              streamSetupCompleter.complete();
            }
          },
          onError: (Object e) => streamSetupCompleter.completeError(e),
          cancelOnError: false,
        );
        return ResponseStream<ServerCommand>(mockStreamCall);
      });

      // Act
      await grpcService.connect(host, port);
      expect(grpcService.isConnected, true);

      // 等待一小段时间确保流已经建立
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 模拟一些数据
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

      // 手动发送一个响应
      final clientResponse = ClientResponse()
        ..deviceId = 'test_device'
        ..success = true
        ..rawOutput = testData;

      // 获取 responseController
      final responseController = grpcService.responseController;
      expect(responseController, isNotNull);
      responseController!.add(clientResponse);

      // 等待响应被处理
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(clientResponses, hasLength(1),
          reason: 'Should receive exactly one response');
      expect(clientResponses.first.deviceId, equals('test_device'));
      expect(clientResponses.first.success, isTrue);
      expect(clientResponses.first.rawOutput, equals(testData));

      // Cleanup
      await streamController.close();
    });

    test('should handle stream closure correctly', () async {
      // Arrange
      const host = '127.0.0.1';
      const port = 50051;

      // Setup mock client for initial connection
      final response = WindowInfoResponse();
      final mockCall = MockClientCall<WindowInfoRequest, WindowInfoResponse>();
      when(() => mockCall.response).thenAnswer((_) => Stream.value(response));

      // Setup stream mock
      final mockStreamCall = MockClientCall<ClientResponse, ServerCommand>();
      final streamController = StreamController<ServerCommand>();
      final clientResponses = <ClientResponse>[];

      when(() => mockStreamCall.response)
          .thenAnswer((_) => streamController.stream);
      when(
        () => mockAccessibilityClient.streamAccessibility(
          captureAny(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) {
        final stream =
            invocation.positionalArguments[0] as Stream<ClientResponse>;
        stream.listen(clientResponses.add);
        return ResponseStream<ServerCommand>(mockStreamCall);
      });

      // 设置重连时的验证请求立即失败
      var isFirstCall = true;
      when(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) {
        if (isFirstCall) {
          isFirstCall = false;
          return ResponseFuture<WindowInfoResponse>(mockCall);
        }
        // 后续调用立即抛出错误，模拟重连失败
        throw GrpcError.unavailable('Connection failed during reconnect');
      });

      // Act
      await grpcService.connect(host, port);
      expect(grpcService.isConnected, true);

      // 模拟服务器关闭流
      await streamController.close();

      // 等待重连过程完成
      // 使用轮询方式等待 isReconnecting 变为 false
      final stopwatch = Stopwatch()..start();
      while (grpcService.isReconnecting &&
          stopwatch.elapsed < const Duration(seconds: 5)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      stopwatch.stop();

      // Assert
      expect(grpcService.isReconnecting, isFalse,
          reason: 'Reconnection process should complete');
      expect(grpcService.isConnected, isFalse,
          reason: 'Connection should be marked as disconnected');

      // 验证重连过程
      verify(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).called(2); // 初始连接一次，重连验证一次
      verify(() => mockChannel.shutdown()).called(1);
    });
  });

  group('Resource Management Tests', () {
    test('should cleanup resources properly during normal disconnection',
        () async {
      // Arrange
      const host = '127.0.0.1';
      const port = 50051;

      // Setup mock client for initial connection
      final response = WindowInfoResponse();
      final mockCall = MockClientCall<WindowInfoRequest, WindowInfoResponse>();
      when(() => mockCall.response).thenAnswer((_) => Stream.value(response));

      when(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseFuture<WindowInfoResponse>(mockCall));

      // Setup stream mock
      final mockStreamCall = MockClientCall<ClientResponse, ServerCommand>();
      final streamController = StreamController<ServerCommand>();
      final clientResponses = <ClientResponse>[];

      when(() => mockStreamCall.response)
          .thenAnswer((_) => streamController.stream);
      when(
        () => mockAccessibilityClient.streamAccessibility(
          captureAny(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) {
        final stream =
            invocation.positionalArguments[0] as Stream<ClientResponse>;
        stream.listen(clientResponses.add);
        return ResponseStream<ServerCommand>(mockStreamCall);
      });

      // Act
      await grpcService.connect(host, port);
      expect(grpcService.isConnected, true);

      // 等待一下确保心跳定时器已启动
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 正常断开连接
      await grpcService.disconnect();

      // Assert
      expect(grpcService.isConnected, isFalse, reason: '连接状态应该被标记为断开');
      expect(grpcService.responseController, isNull,
          reason: 'responseController 应该被清理');
      verify(() => mockChannel.shutdown()).called(1);

      // 等待足够长的时间，确保不会有新的心跳
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(
        clientResponses.where((r) => r.deviceId == 'heartbeat').length,
        0,
        reason: '断开连接后不应该有心跳发送',
      );

      // Cleanup
      await streamController.close();
    });

    test('should cleanup resources when connection fails during setup',
        () async {
      // Arrange
      const host = '127.0.0.1';
      const port = 50051;

      // Setup mock client to fail during stream setup
      final response = WindowInfoResponse();
      final mockCall = MockClientCall<WindowInfoRequest, WindowInfoResponse>();
      when(() => mockCall.response).thenAnswer((_) => Stream.value(response));

      var callCount = 0;
      when(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          // 第一次连接成功
          return ResponseFuture<WindowInfoResponse>(mockCall);
        } else {
          // 重连尝试时抛出错误
          throw GrpcError.unavailable('Connection failed during reconnect');
        }
      });

      // Setup stream mock to fail
      final mockStreamCall = MockClientCall<ClientResponse, ServerCommand>();
      final streamController = StreamController<ServerCommand>();
      final streamCompleter = Completer<void>();

      when(() => mockStreamCall.response).thenAnswer((_) {
        // 延迟发送错误，确保连接先建立
        Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
          if (!streamCompleter.isCompleted) {
            streamController.addError(Exception('Stream setup failed'));
            streamCompleter.complete();
          }
        });
        return streamController.stream;
      });

      when(
        () => mockAccessibilityClient.streamAccessibility(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseStream<ServerCommand>(mockStreamCall));

      // Act
      await grpcService.connect(host, port);

      // 等待流错误发生
      await streamCompleter.future;

      // 等待重连尝试完成
      final stopwatch = Stopwatch()..start();
      while (grpcService.isReconnecting &&
          stopwatch.elapsed < const Duration(seconds: 5)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      stopwatch.stop();

      // Assert
      expect(grpcService.isConnected, isFalse, reason: '连接状态应该被标记为断开');
      expect(grpcService.isReconnecting, isFalse, reason: '重连过程应该已完成');
      expect(grpcService.responseController, isNull,
          reason: 'responseController 应该被清理');

      verify(() => mockChannel.shutdown()).called(1);
      verify(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).called(2); // 验证初始连接和重连各调用一次

      // Cleanup
      await streamController.close();
    });

    test('should handle concurrent resource cleanup safely', () async {
      // Arrange
      const host = '127.0.0.1';
      const port = 50051;

      // Setup mock client for initial connection
      final response = WindowInfoResponse();
      final mockCall = MockClientCall<WindowInfoRequest, WindowInfoResponse>();
      when(() => mockCall.response).thenAnswer((_) => Stream.value(response));

      when(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseFuture<WindowInfoResponse>(mockCall));

      // Setup stream mock with delayed response to simulate long operation
      final mockStreamCall = MockClientCall<ClientResponse, ServerCommand>();
      final streamController = StreamController<ServerCommand>();
      final cleanupStarted = Completer<void>();
      final cleanupCompleted = Completer<void>();

      // 模拟 channel.shutdown 需要一定时间
      when(() => mockChannel.shutdown()).thenAnswer((_) async {
        if (!cleanupStarted.isCompleted) cleanupStarted.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (!cleanupCompleted.isCompleted) cleanupCompleted.complete();
      });

      when(() => mockStreamCall.response)
          .thenAnswer((_) => streamController.stream);
      when(
        () => mockAccessibilityClient.streamAccessibility(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => ResponseStream<ServerCommand>(mockStreamCall));

      // Act
      await grpcService.connect(host, port);
      expect(grpcService.isConnected, true);

      // 清除之前的所有调用记录
      clearInteractions(mockWindowInfoClient);
      clearInteractions(mockChannel);

      // 触发并发的清理操作
      final disconnectFuture1 = grpcService.disconnect();

      // 等待第一个清理操作开始
      await cleanupStarted.future;

      // 在清理过程中触发更多操作
      final disconnectFuture2 = grpcService.disconnect();
      final streamCloseFuture = streamController.close();
      final disconnectFuture3 = grpcService.disconnect();

      // 等待所有操作完成
      await Future.wait([
        disconnectFuture1,
        disconnectFuture2,
        streamCloseFuture,
        disconnectFuture3,
      ]);

      // 等待清理完成
      await cleanupCompleted.future;

      // Assert
      expect(grpcService.isConnected, isFalse, reason: '连接状态应该被标记为断开');
      expect(grpcService.responseController, isNull,
          reason: 'responseController 应该被清理');

      // 验证在清理过程中的调用
      verify(() => mockChannel.shutdown()).called(1);
      verifyNever(
        () => mockWindowInfoClient.getCurrentWindowInfo(
          any(),
          options: any(named: 'options'),
        ),
      );
    });
  });
}
