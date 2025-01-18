import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:awattackerapplier/generated/accessibility.pbgrpc.dart';
import 'package:awattackerapplier/generated/window_info.pbgrpc.dart';

/// 模拟gRPC服务端的响应延迟
const mockResponseDelay = Duration(milliseconds: 100);

/// 模拟ClientCall
class MockClientCall<Q, R> extends Mock implements ClientCall<Q, R> {}

/// 模拟WindowInfoServiceClient
class MockWindowInfoServiceClient extends Mock
    implements WindowInfoServiceClient {}

/// 模拟AccessibilityServiceClient
class MockAccessibilityServiceClient extends Mock
    implements AccessibilityServiceClient {
  final _commandController = StreamController<ServerCommand>.broadcast();

  void dispose() {
    if (!_commandController.isClosed) {
      _commandController.close();
    }
  }
}

/// 模拟ClientChannel
class MockClientChannel extends Mock implements ClientChannel {}

/// 创建测试用的ServerCommand
ServerCommand createTestCommand({
  String deviceId = 'test_device',
  ServerCommand_CommandType type =
      ServerCommand_CommandType.GET_ACCESSIBILITY_TREE,
}) {
  return ServerCommand()
    ..deviceId = deviceId
    ..command = type;
}
