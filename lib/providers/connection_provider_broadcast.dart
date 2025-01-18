import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 表示命令执行结果的类
class CommandResult {
  final bool success;
  final String? error;

  CommandResult({required this.success, this.error});
}

/// 处理广播命令的Mixin
mixin BroadcastCommandHandler on ChangeNotifier {
  static const _channel =
      MethodChannel('com.mobilellm.awattackerapplier/connection');

  /// 初始化广播命令处理器
  void initializeBroadcastHandler() {
    debugPrint('BroadcastCommandHandler: Initializing broadcast handler');
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// 处理来自原生层的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint(
        'BroadcastCommandHandler: Received method call: ${call.method} with arguments: ${call.arguments}');

    if (call.method == 'handleServiceCommand') {
      final command = call.arguments['command'] as String?;
      final result = await _handleCommand(command);
      return {
        'success': result.success,
        'error': result.error,
      };
    }

    throw MissingPluginException();
  }

  /// 处理具体的命令
  Future<CommandResult> _handleCommand(String? command) async {
    debugPrint('BroadcastCommandHandler: Handling command: $command');

    switch (command) {
      case 'START_SERVICE':
        try {
          debugPrint('BroadcastCommandHandler: Starting service');
          await handleStartService();
          debugPrint('BroadcastCommandHandler: Service started successfully');
          return CommandResult(success: true);
        } catch (e) {
          debugPrint('BroadcastCommandHandler: Error starting service: $e');
          return CommandResult(success: false, error: e.toString());
        }
      case 'STOP_SERVICE':
        try {
          debugPrint('BroadcastCommandHandler: Stopping service');
          await handleStopService();
          debugPrint('BroadcastCommandHandler: Service stopped successfully');
          return CommandResult(success: true);
        } catch (e) {
          debugPrint('BroadcastCommandHandler: Error stopping service: $e');
          return CommandResult(success: false, error: e.toString());
        }
      default:
        debugPrint('BroadcastCommandHandler: Unknown command: $command');
        return CommandResult(
            success: false, error: 'Unknown command: $command');
    }
  }

  /// 由具体实现类提供的启动服务方法
  Future<void> handleStartService();

  /// 由具体实现类提供的停止服务方法
  Future<void> handleStopService();

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
  }
}
