import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awattackerapplier/l10n/app_localizations.dart';
import 'pages/main_page.dart';
import 'providers/connection_provider.dart';
import 'providers/rule_provider.dart';
import 'providers/rule_validation_provider.dart';
import 'repositories/rule_repository.dart';
import 'repositories/storage_repository.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化存储库
  final prefs = await SharedPreferences.getInstance();
  final ruleRepository = RuleRepository(prefs);
  final storageRepository = StorageRepository();
  await storageRepository.init();

  // 初始化 Provider
  final ruleValidationProvider = RuleValidationProvider();
  final ruleProvider = RuleProvider(
    ruleRepository,
    storageRepository,
    ruleValidationProvider,
  );
  final connectionProvider = ConnectionProvider(ruleProvider);

  // 加载规则
  await ruleProvider.loadRules();

  // 启动后台服务
  await BackgroundService.initializeService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ruleValidationProvider),
        ChangeNotifierProvider.value(value: ruleProvider),
        ChangeNotifierProvider.value(value: connectionProvider),
      ],
      child: const Main(),
    ),
  );
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AWAttackApplier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('zh'), // Chinese
      ],
      home: const MainPage(),
    );
  }
}
