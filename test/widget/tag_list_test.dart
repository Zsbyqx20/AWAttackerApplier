import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:awattackerapplier/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awattackerapplier/models/rule.dart';
import 'package:awattackerapplier/models/rule_import.dart';
import 'package:awattackerapplier/pages/tag/tag_list_page.dart';
import 'package:awattackerapplier/providers/rule_provider.dart';
import 'package:awattackerapplier/providers/rule_validation_provider.dart';
import 'package:awattackerapplier/repositories/rule_repository.dart';
import 'package:awattackerapplier/repositories/storage_repository.dart';
import 'package:awattackerapplier/widgets/tag_stats_card.dart';

void main() {
  late RuleProvider ruleProvider;
  late String testRuleJson;
  late SharedPreferences prefs;
  late RuleRepository ruleRepository;
  late StorageRepository storageRepository;
  late RuleValidationProvider validationProvider;

  setUpAll(() async {
    testRuleJson = await File('test/fixtures/test_rule.json').readAsString();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storageRepository = StorageRepository();
    await storageRepository.init();
    ruleRepository = RuleRepository(prefs);
    validationProvider = RuleValidationProvider();
  });

  setUp(() {
    ruleProvider = RuleProvider(
      ruleRepository,
      storageRepository,
      validationProvider,
    );
  });

  group('Tag List Page Tests', () {
    late Rule testRule;

    setUp(() async {
      // 从 fixture 加载测试规则
      final file = File('test/fixtures/test_rule.json');
      final jsonStr = await file.readAsString();
      final ruleImport = RuleImport.fromJson(jsonStr);
      testRule = ruleImport.rules.first;
    });

    tearDown(() async {
      // 清理测试数据
      try {
        await prefs.clear();
      } catch (e) {
        // 忽略清理错误
      }
    });

    Future<void> buildTestApp(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RuleProvider>.value(value: ruleProvider),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('zh'),
            ],
            locale: const Locale('en'),
            home: const TagListPage(),
          ),
        ),
      );
    }

    testWidgets('Tag list page shows correct initial state', (tester) async {
      // 构建页面
      await buildTestApp(tester);
      await tester.pumpAndSettle();

      // 验证统计卡片显示正确的初始值
      expect(find.byType(TagStatsCard), findsOneWidget);
      expect(find.text('0'), findsNWidgets(3)); // 总标签数、使用标签的规则数、激活的标签数都应该是0
    });

    testWidgets('Tag list updates when rules are added', (tester) async {
      // 构建页面
      await buildTestApp(tester);

      // 添加测试规则
      await ruleProvider.addRule(testRule);
      await tester.pumpAndSettle();

      // 验证标签统计
      expect(find.text('1'), findsNWidgets(2)); // 总标签数和使用标签的规则数
      expect(find.text('0'), findsOneWidget); // 激活的标签数

      // 验证标签列表项
      expect(find.text('test_tag'), findsOneWidget);
    });

    testWidgets('Tag activation works correctly', (tester) async {
      // 构建页面
      await buildTestApp(tester);

      // 添加测试规则
      await ruleProvider.addRule(testRule);
      await tester.pumpAndSettle();

      // 找到并点击开关
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // 验证确认对话框
      final l10n =
          AppLocalizations.of(tester.element(find.byType(TagListPage)))!;
      expect(find.text(l10n.activateTag), findsOneWidget);

      // 确认激活
      await tester.tap(find.text(l10n.activate));
      await tester.pumpAndSettle();

      // 验证标签已激活
      expect(ruleProvider.activeTags, contains('test_tag'));
      expect(find.text('1'), findsNWidgets(3)); // 总标签数、使用标签的规则数、激活的标签数都应该是1
    });

    testWidgets('Tag deletion works correctly', (tester) async {
      // 构建页面
      await buildTestApp(tester);

      // 添加测试规则
      await ruleProvider.addRule(testRule);
      await tester.pumpAndSettle();

      // 滑动删除标签
      await tester.drag(find.text('test_tag'), const Offset(-800.0, 0.0));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));

      // 获取本地化实例
      final l10n =
          AppLocalizations.of(tester.element(find.byType(TagListPage)))!;

      // 验证删除对话框显示
      expect(find.text(l10n.deleteTag), findsOneWidget,
          reason: 'Delete tag dialog title should be visible');
      expect(find.text(l10n.delete), findsOneWidget,
          reason: 'Delete button should be visible');

      // 点击删除按钮
      await tester.tap(find.text(l10n.delete));
      await tester.pumpAndSettle();

      // 验证标签已删除
      expect(find.text('test_tag'), findsNothing);
      expect(find.text('0'), findsNWidgets(3)); // 总标签数、使用标签的规则数、激活的标签数都应该是0
    });

    testWidgets('Tag deletion can be cancelled', (tester) async {
      // 构建页面
      await buildTestApp(tester);

      // 添加测试规则
      await ruleProvider.addRule(testRule);
      await tester.pumpAndSettle();

      // 滑动删除标签
      await tester.drag(find.text('test_tag'), const Offset(-800.0, 0.0));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));

      // 获取本地化实例
      final l10n =
          AppLocalizations.of(tester.element(find.byType(TagListPage)))!;

      // 验证删除对话框显示
      expect(find.text(l10n.deleteTag), findsOneWidget,
          reason: 'Delete tag dialog title should be visible');
      expect(find.text(l10n.dialogDefaultCancel), findsOneWidget,
          reason: 'Cancel button should be visible');

      // 点击取消按钮
      await tester.tap(find.text(l10n.dialogDefaultCancel));
      await tester.pumpAndSettle();

      // 验证标签未被删除
      expect(find.text('test_tag'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2)); // 总标签数和使用标签的规则数
      expect(find.text('0'), findsOneWidget); // 激活的标签数
    });

    testWidgets('Tag list updates when rules are edited', (tester) async {
      // 构建页面
      await buildTestApp(tester);

      // 添加测试规则
      await ruleProvider.addRule(testRule);
      await tester.pumpAndSettle();

      // 验证初始标签
      expect(find.text('test_tag'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2)); // 总标签数和使用标签的规则数
      expect(find.text('0'), findsOneWidget); // 激活的标签数

      // 更新规则，修改标签
      final updatedRule = testRule.copyWith(
        tags: ['new_tag'],
      );
      await ruleProvider.updateRule(updatedRule);
      await tester.pumpAndSettle();

      // 验证标签已更新
      expect(find.text('test_tag'), findsNothing);
      expect(find.text('new_tag'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2)); // 总标签数和使用标签的规则数
      expect(find.text('0'), findsOneWidget); // 激活的标签数
    });

    testWidgets('Tag list shows correct rule count', (tester) async {
      // 构建页面
      await buildTestApp(tester);

      // 添加第一个规则
      await ruleProvider.addRule(testRule);

      // 添加第二个规则，使用相同的标签和一个新标签
      final rule2 = testRule.copyWith(
        name: 'Test Rule 2',
        packageName: 'com.example.app2',
        activityName: '.MainActivity2',
        tags: ['test_tag', 'unique_tag'],
      );
      await ruleProvider.addRule(rule2);
      await tester.pumpAndSettle();

      // 验证标签统计
      final tagStatsCard = find.byType(TagStatsCard);
      expect(tagStatsCard, findsOneWidget);

      // 在 TagStatsCard 中查找统计数字
      final totalTagsText = find
          .descendant(
            of: tagStatsCard,
            matching: find.text('2'),
          )
          .first;
      expect(totalTagsText, findsOneWidget);

      expect(find.text('0'), findsOneWidget); // 激活的标签数

      // 验证共享标签的规则计数
      final l10n =
          AppLocalizations.of(tester.element(find.byType(TagListPage)))!;
      expect(
          find.text(l10n.usedInRules(2)), findsOneWidget); // test_tag 被2个规则使用
      expect(
          find.text(l10n.usedInRules(1)), findsOneWidget); // unique_tag 被1个规则使用
    });

    testWidgets('Tag chip in RuleCard updates when tag is activated',
        (tester) async {
      // 构建页面
      await buildTestApp(tester);
      await tester.pumpAndSettle();

      // 添加一个带有标签的规则
      final jsonData = jsonDecode(testRuleJson) as Map<String, dynamic>;
      final testRule =
          Rule.fromJson(jsonData['rules'][0] as Map<String, dynamic>);
      await ruleProvider.addRule(testRule);
      await tester.pumpAndSettle();

      // 验证标签初始状态
      expect(find.text('test_tag'), findsOneWidget);
      expect(ruleProvider.activeTags.contains('test_tag'), isFalse);

      // 点击标签项的开关
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // 点击确认按钮
      final l10n =
          AppLocalizations.of(tester.element(find.byType(TagListPage)))!;
      await tester.tap(find.text(l10n.activate));
      await tester.pumpAndSettle();

      // 验证标签已被激活
      expect(ruleProvider.activeTags.contains('test_tag'), isTrue);

      // 验证标签统计更新
      expect(find.text('1', findRichText: true),
          findsNWidgets(3)); // 总标签数、使用标签的规则数和激活的标签数
    });
  });
}
