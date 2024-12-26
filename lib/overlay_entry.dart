import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:convert';
import 'widgets/overlay_window.dart';
import 'models/overlay_style.dart';

@pragma('vm:entry-point')
void overlayMain() async {
  try {
    debugPrint('🚀 悬浮窗入口点被调用');

    // 确保 Flutter 引擎初始化
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('✅ Flutter绑定初始化完成');

    // 设置错误监听
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('❌ Flutter错误: ${details.exception}');
      debugPrint('堆栈: ${details.stack}');
    };

    // 运行应用
    debugPrint('🎯 准备运行悬浮窗应用...');
    runApp(const OverlayEntry());
    debugPrint('✅ 悬浮窗应用启动完成');
  } catch (e, stack) {
    debugPrint('❌ 悬浮窗入口点执行错误: $e');
    debugPrint('错误堆栈: $stack');
  }
}

class OverlayEntry extends StatefulWidget {
  const OverlayEntry({super.key});

  @override
  State<OverlayEntry> createState() => _OverlayEntryState();
}

class _OverlayEntryState extends State<OverlayEntry>
    with WidgetsBindingObserver {
  OverlayStyle _style = OverlayStyle.defaultStyle();
  Offset _position = const Offset(0, 0);

  @override
  void initState() {
    super.initState();
    debugPrint('🔄 OverlayEntry initState');
    WidgetsBinding.instance.addObserver(this);
    // 使用 addPostFrameCallback 确保在第一帧渲染后设置监听器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupDataListener();
    });
  }

  @override
  void dispose() {
    debugPrint('🔄 OverlayEntry dispose');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setupDataListener() {
    debugPrint('🎯 设置数据监听器...');
    FlutterOverlayWindow.overlayListener.listen(
      (event) {
        debugPrint('📥 收到数据更新: $event');
        if (event == null) return;

        try {
          final data = jsonDecode(event);
          if (data['type'] == 'update_style') {
            final newStyle = OverlayStyle.fromJson(data['style']);
            final position = data['position'];
            setState(() {
              _style = newStyle;
              _position = Offset(
                position['x'].toDouble(),
                position['y'].toDouble(),
              );
            });
            debugPrint('✅ 样式已更新: ${newStyle.toJson()}');
            debugPrint('✅ 位置已更新: (${_position.dx}, ${_position.dy})');
          }
        } catch (e) {
          debugPrint('❌ 处理数据更新时出错: $e');
          debugPrint('错误堆栈: ${StackTrace.current}');
        }
      },
      onError: (error) {
        debugPrint('❌ 数据监听器错误: $error');
      },
      cancelOnError: false,
    );
    debugPrint('✅ 数据监听器设置完成');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('⚡ 构建悬浮窗UI');
    debugPrint('当前样式: ${_style.toJson()}');
    debugPrint('当前位置: (${_position.dx}, ${_position.dy})');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned(
              left: _position.dx,
              top: _position.dy,
              child: OverlayWindow(style: _style),
            ),
          ],
        ),
      ),
    );
  }
}
