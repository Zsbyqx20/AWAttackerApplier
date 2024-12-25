import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:study_flutter/pages/server_config_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置首选的渲染引擎
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AWAttacker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ServerConfigPage(),
    );
  }
}
