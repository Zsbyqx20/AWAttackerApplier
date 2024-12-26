import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/rule_provider.dart';
import 'providers/connection_provider.dart';
import 'repositories/rule_repository.dart';
import 'pages/server_config_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final ruleRepository = RuleRepository(prefs);
  final ruleProvider = RuleProvider(ruleRepository);
  final connectionProvider = ConnectionProvider();
  await ruleProvider.loadRules();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ruleProvider),
        ChangeNotifierProvider.value(value: connectionProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AWAttacker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ServerConfigPage(),
    );
  }
}
