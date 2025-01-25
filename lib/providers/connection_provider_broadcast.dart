import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 处理广播命令的Mixin
mixin ConnectionProviderBroadcast on ChangeNotifier {
  static const _channel =
      MethodChannel('com.mobilellm.awattackerapplier/connection');

  /// 初始化广播命令处理器
  void initializeBroadcastHandler() {
    debugPrint('BroadcastCommandHandler: Initializing broadcast handler');
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// 处理来自原生层的方法调用
  Future<Map<String, Object?>> _handleMethodCall(MethodCall call) async {
    debugPrint(
        'BroadcastCommandHandler: Received method call: ${call.method} with arguments: ${call.arguments}');

    if (call.method == 'handleServiceCommand') {
      final command = call.arguments['command'] as String?;
      final result = await _handleCommand(command, call);

      return {
        'success': result.success,
        'error': result.error,
      };
    }

    throw MissingPluginException();
  }

  /// 处理具体的命令
  Future<CommandResult> _handleCommand(String? command, MethodCall call) async {
    debugPrint('BroadcastCommandHandler: Handling command: $command');

    switch (command) {
      case 'SET_GRPC_CONFIG':
        try {
          final arguments = call.arguments;
          debugPrint('BroadcastCommandHandler: Raw arguments: $arguments');

          final argumentsMap = Map<String, dynamic>.from(arguments as Map);
          debugPrint(
              'BroadcastCommandHandler: Converted arguments: $argumentsMap');

          final host = argumentsMap['host'] as String;
          final port = argumentsMap['port'] as int;
          debugPrint(
              'BroadcastCommandHandler: Extracted host: $host, port: $port');

          await handleSetGrpcConfig(host, port);

          return CommandResult(success: true);
        } catch (e, stackTrace) {
          debugPrint('BroadcastCommandHandler: Error details: $e');
          debugPrint('BroadcastCommandHandler: Stack trace: $stackTrace');

          return CommandResult(success: false, error: e.toString());
        }
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
      case 'CLEAR_RULES':
        try {
          debugPrint('BroadcastCommandHandler: Clearing rules');
          await handleClearRules();
          debugPrint('BroadcastCommandHandler: Rules cleared successfully');

          return CommandResult(success: true);
        } catch (e) {
          debugPrint('BroadcastCommandHandler: Error clearing rules: $e');

          return CommandResult(success: false, error: e.toString());
        }
      case 'IMPORT_RULES':
        try {
          debugPrint('BroadcastCommandHandler: Importing rules');
          final arguments = call.arguments;
          final argumentsMap = Map<String, dynamic>.from(arguments as Map);
          final rulesJson = argumentsMap['rules_json'] as String;
          await handleImportRules(rulesJson);
          debugPrint('BroadcastCommandHandler: Rules imported successfully');

          return CommandResult(success: true);
        } catch (e) {
          debugPrint('BroadcastCommandHandler: Error importing rules: $e');

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

  /// 处理gRPC配置更新
  Future<void> handleSetGrpcConfig(String host, int port);

  /// 处理清空规则
  Future<void> handleClearRules();

  /// 处理导入规则
  Future<void> handleImportRules(String rulesJson);

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
  }
}

/// 表示命令执行结果的类
class CommandResult {
  final bool success;
  final String? error;

  CommandResult({required this.success, this.error});
}
