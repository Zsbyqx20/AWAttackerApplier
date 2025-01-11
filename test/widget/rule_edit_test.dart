import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awattackerapplier/pages/rule/rule_list_page.dart';
import 'package:awattackerapplier/providers/rule_provider.dart';
import 'package:awattackerapplier/providers/rule_validation_provider.dart';
import 'package:awattackerapplier/repositories/rule_repository.dart';
import 'package:awattackerapplier/repositories/storage_repository.dart';
import 'package:awattackerapplier/widgets/color_picker_field.dart';
import 'package:awattackerapplier/widgets/rule_card.dart';
import 'package:awattackerapplier/widgets/tag_chips.dart';
import 'package:awattackerapplier/widgets/text_input_field.dart';

// 全局变量
late AppLocalizations l10n;

Future<void> buildTestApp(
  WidgetTester tester,
  RuleProvider ruleProvider,
  RuleValidationProvider validationProvider, {
  NavigatorObserver? navigator,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RuleProvider>.value(value: ruleProvider),
        ChangeNotifierProvider<RuleValidationProvider>.value(
            value: validationProvider),
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
        navigatorObservers: navigator != null ? [navigator] : [],
        home: const RuleListPage(),
      ),
    ),
  );

  // 获取本地化实例
  l10n = AppLocalizations.of(tester.element(find.byType(RuleListPage)))!;
}

void main() {
  group('Rule Edit Page Tests', () {
    late SharedPreferences prefs;
    late RuleRepository ruleRepository;
    late StorageRepository storageRepository;
    late RuleValidationProvider validationProvider;
    late RuleProvider ruleProvider;

    setUp(() async {
      // 初始化 SharedPreferences
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      // 初始化存储相关组件
      ruleRepository = RuleRepository(prefs);
      storageRepository = StorageRepository();
      await storageRepository.init();

      // 初始化验证提供者
      validationProvider = RuleValidationProvider();

      // 初始化规则提供者
      ruleProvider = RuleProvider(
        ruleRepository,
        storageRepository,
        validationProvider,
      );
    });

    tearDown(() async {
      // 清理测试数据
      try {
        await prefs.clear();
      } catch (e) {
        // 忽略清理错误
      }
    });

    testWidgets('Successfully save new rule', (tester) async {
      // 设置测试窗口大小
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      // 清空规则列表
      await ruleProvider.clearRules();

      // 创建一个导航观察器来捕获返回的规则
      final navigator = NavigatorObserver();

      // 构建测试页面
      await buildTestApp(tester, ruleProvider, validationProvider,
          navigator: navigator);

      // 点击添加按钮
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 点击添加规则按钮
      final addRuleButton =
          find.widgetWithText(FloatingActionButton, l10n.addRule);
      await tester.tap(addRuleButton);
      await tester.pumpAndSettle();

      // 填写规则信息
      // 规则名称
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.ruleName),
        'Test Rule',
      );
      await tester.pumpAndSettle();

      // 包名
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.packageName),
        'com.example.app',
      );
      await tester.pumpAndSettle();

      // 活动名
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.activityName),
        '.MainActivity',
      );
      await tester.pumpAndSettle();

      // 添加标签
      final tagInput = find.byType(TagChipsInput);
      expect(tagInput, findsOneWidget);

      // 找到TagChipsInput中的TextField
      final tagTextField = find.descendant(
        of: tagInput,
        matching: find.byType(TextField),
      );
      expect(tagTextField, findsOneWidget);

      await tester.enterText(tagTextField, 'test_tag');
      await tester.pumpAndSettle();

      // 点击添加按钮
      final addButton = find.descendant(
        of: tagInput,
        matching: find.byIcon(Icons.add),
      );
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // 修改文本
      final textField = find.byWidgetPredicate(
        (widget) => widget is TextInputField && widget.label == l10n.text,
      );
      expect(textField, findsOneWidget, reason: 'Text field should be present');
      await tester.enterText(textField, 'Test Text');
      await tester.pumpAndSettle();

      // 修改UI Automator代码
      final uiAutomatorTextField = find.byWidgetPredicate(
        (widget) =>
            widget is TextInputField && widget.label == l10n.uiAutomatorCode,
      );
      expect(uiAutomatorTextField, findsOneWidget,
          reason: 'UI Automator code field should be present');
      await tester.enterText(
          uiAutomatorTextField, 'new UiSelector().text("Test Text")');
      await tester.pumpAndSettle();

      // 点击保存按钮
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      // 等待页面完全更新
      await tester.pump(const Duration(milliseconds: 300));

      // 打印调试信息
      debugPrint('规则列表长度: ${ruleProvider.rules.length}');
      for (final rule in ruleProvider.rules) {
        debugPrint('规则名称: ${rule.name}');
        debugPrint('包名: ${rule.packageName}');
        debugPrint('活动名: ${rule.activityName}');
        debugPrint('标签: ${rule.tags}');
      }

      // 验证规则列表页面上的显示
      expect(find.text('Test Rule'), findsOneWidget,
          reason: 'Rule name should be visible in list');
      expect(find.text('com.example.app'), findsOneWidget,
          reason: 'Package name should be visible in list');
      expect(find.text('.MainActivity'), findsOneWidget,
          reason: 'Activity name should be visible in list');
      expect(find.text('test_tag'), findsOneWidget,
          reason: 'Tag should be visible in list');

      // 验证规则是否被正确保存
      expect(ruleProvider.rules.length, equals(1),
          reason: 'Rule should be added to provider');
      final savedRule = ruleProvider.rules.first;
      expect(savedRule.name, equals('Test Rule'),
          reason: 'Rule name should match');
      expect(savedRule.packageName, equals('com.example.app'),
          reason: 'Package name should match');
      expect(savedRule.activityName, equals('.MainActivity'),
          reason: 'Activity name should match');
      expect(savedRule.tags, contains('test_tag'),
          reason: 'Tags should contain test_tag');
      expect(savedRule.isEnabled, isFalse,
          reason: 'New rule should be disabled');
      expect(savedRule.overlayStyles.length, equals(1),
          reason: 'Should have one default overlay style');

      // 验证规则是否被正确保存到 SharedPreferences
      final savedRules = await ruleRepository.loadRules();
      expect(savedRules.length, equals(1),
          reason: 'Rule should be saved to SharedPreferences');
      final persistedRule = savedRules.first;
      expect(persistedRule.name, equals('Test Rule'),
          reason: 'Persisted rule name should match');
      expect(persistedRule.overlayStyles.length, equals(1),
          reason: 'Persisted rule should have one style');
    });

    testWidgets('Successfully save rule with multiple overlay styles',
        (tester) async {
      // 设置测试窗口大小
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      // 清空规则列表
      await ruleProvider.clearRules();

      // 创建一个导航观察器来捕获返回的规则
      final navigator = NavigatorObserver();

      // 构建测试页面
      await buildTestApp(tester, ruleProvider, validationProvider,
          navigator: navigator);

      // 点击添加按钮
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 点击添加规则按钮
      final addRuleButton =
          find.widgetWithText(FloatingActionButton, l10n.addRule);
      await tester.tap(addRuleButton);
      await tester.pumpAndSettle();

      // 填写规则信息
      // 规则名称
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.ruleName),
        'Test Rule',
      );
      await tester.pumpAndSettle();

      // 包名
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.packageName),
        'com.example.app',
      );
      await tester.pumpAndSettle();

      // 活动名
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.activityName),
        '.MainActivity',
      );
      await tester.pumpAndSettle();

      // 添加标签
      final tagInput = find.byType(TagChipsInput);
      expect(tagInput, findsOneWidget);

      // 找到TagChipsInput中的TextField
      final tagTextField = find.descendant(
        of: tagInput,
        matching: find.byType(TextField),
      );
      expect(tagTextField, findsOneWidget);

      await tester.enterText(tagTextField, 'test_tag');
      await tester.pumpAndSettle();

      // 点击添加按钮
      final addButton = find.descendant(
        of: tagInput,
        matching: find.byIcon(Icons.add),
      );
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // 添加第一个浮窗样式
      // 修改文本
      final textField = find.byWidgetPredicate(
        (widget) => widget is TextInputField && widget.label == l10n.text,
      );
      expect(textField, findsOneWidget, reason: 'Text field should be present');
      await tester.enterText(textField, 'First Style');
      await tester.pumpAndSettle();

      // 修改UI Automator代码
      final uiAutomatorTextField = find.byWidgetPredicate(
        (widget) =>
            widget is TextInputField && widget.label == l10n.uiAutomatorCode,
      );
      expect(uiAutomatorTextField, findsOneWidget,
          reason: 'UI Automator code field should be present');
      await tester.enterText(
          uiAutomatorTextField, 'new UiSelector().text("First Style")');
      await tester.pumpAndSettle();

      // 添加第二个浮窗样式
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      // 修改第二个浮窗的文本
      final secondTextField = find
          .byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == l10n.text,
          )
          .last;
      await tester.enterText(secondTextField, 'Second Style');
      await tester.pumpAndSettle();

      // 修改第二个浮窗的UI Automator代码
      final secondUiAutomatorTextField = find
          .byWidgetPredicate(
            (widget) =>
                widget is TextInputField &&
                widget.label == l10n.uiAutomatorCode,
          )
          .last;
      await tester.enterText(
          secondUiAutomatorTextField, 'new UiSelector().text("Second Style")');
      await tester.pumpAndSettle();

      // 点击保存按钮
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      // 等待页面完全更新
      await tester.pump(const Duration(milliseconds: 300));

      // 验证规则列表页面上的显示
      expect(find.text('Test Rule'), findsOneWidget,
          reason: 'Rule name should be visible in list');
      expect(find.text('com.example.app'), findsOneWidget,
          reason: 'Package name should be visible in list');
      expect(find.text('.MainActivity'), findsOneWidget,
          reason: 'Activity name should be visible in list');
      expect(find.text('test_tag'), findsOneWidget,
          reason: 'Tag should be visible in list');

      // 验证规则是否被正确保存
      expect(ruleProvider.rules.length, equals(1),
          reason: 'Rule should be added to provider');
      final savedRule = ruleProvider.rules.first;
      expect(savedRule.name, equals('Test Rule'),
          reason: 'Rule name should match');
      expect(savedRule.packageName, equals('com.example.app'),
          reason: 'Package name should match');
      expect(savedRule.activityName, equals('.MainActivity'),
          reason: 'Activity name should match');
      expect(savedRule.tags, contains('test_tag'),
          reason: 'Tags should contain test_tag');
      expect(savedRule.isEnabled, isFalse,
          reason: 'New rule should be disabled');
      expect(savedRule.overlayStyles.length, equals(2),
          reason: 'Should have two overlay styles');

      // 验证规则是否被正确保存到 SharedPreferences
      final savedRules = await ruleRepository.loadRules();
      expect(savedRules.length, equals(1),
          reason: 'Rule should be saved to SharedPreferences');
      final persistedRule = savedRules.first;
      expect(persistedRule.name, equals('Test Rule'),
          reason: 'Persisted rule name should match');
      expect(persistedRule.overlayStyles.length, equals(2),
          reason: 'Persisted rule should have two styles');
    });

    testWidgets('Successfully save rule with style customization',
        (tester) async {
      // 设置测试窗口大小
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      // 清空规则列表
      await ruleProvider.clearRules();

      // 创建一个导航观察器来捕获返回的规则
      final navigator = NavigatorObserver();

      // 构建测试页面
      await buildTestApp(tester, ruleProvider, validationProvider,
          navigator: navigator);

      // 点击添加按钮
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 点击添加规则按钮
      final addRuleButton =
          find.widgetWithText(FloatingActionButton, l10n.addRule);
      await tester.tap(addRuleButton);
      await tester.pumpAndSettle();

      // 填写规则信息
      // 规则名称
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.ruleName),
        'Test Rule',
      );
      await tester.pumpAndSettle();

      // 包名
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.packageName),
        'com.example.app',
      );
      await tester.pumpAndSettle();

      // 活动名
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.activityName),
        '.MainActivity',
      );
      await tester.pumpAndSettle();

      // 添加标签
      final tagInput = find.byType(TagChipsInput);
      expect(tagInput, findsOneWidget);

      // 找到TagChipsInput中的TextField
      final tagTextField = find.descendant(
        of: tagInput,
        matching: find.byType(TextField),
      );
      expect(tagTextField, findsOneWidget);

      await tester.enterText(tagTextField, 'test_tag');
      await tester.pumpAndSettle();

      // 点击添加按钮
      final addButton = find.descendant(
        of: tagInput,
        matching: find.byIcon(Icons.add),
      );
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // 添加浮窗样式
      // 修改文本
      final textField = find.byWidgetPredicate(
        (widget) => widget is TextInputField && widget.label == l10n.text,
      );
      expect(textField, findsOneWidget, reason: 'Text field should be present');
      await tester.enterText(textField, 'Custom Style');
      await tester.pumpAndSettle();

      // 修改UI Automator代码
      final uiAutomatorTextField = find.byWidgetPredicate(
        (widget) =>
            widget is TextInputField && widget.label == l10n.uiAutomatorCode,
      );
      expect(uiAutomatorTextField, findsOneWidget,
          reason: 'UI Automator code field should be present');
      await tester.enterText(
          uiAutomatorTextField, 'new UiSelector().text("Custom Style")');
      await tester.pumpAndSettle();

      // 修改字体大小
      final fontSizeText = find.text('${l10n.fontSize}: 14.0');
      expect(fontSizeText, findsOneWidget,
          reason: 'Font size label should be present');

      final fontSizeSlider = find.byType(Slider);
      expect(fontSizeSlider, findsOneWidget,
          reason: 'Font size slider should be present');

      // 计算需要拖动的距离
      // Slider范围是8-32，divisions是48（每0.5一个小格）
      // 要达到24，需要从8移动 (24-8)/0.5 = 32 个小格
      // 假设每个小格是4个逻辑像素，总距离是 32 * 4 = 128
      await tester.drag(fontSizeSlider, const Offset(128.0, 0.0));
      await tester.pumpAndSettle();

      // 修改背景颜色
      final backgroundColorField = find.byType(ColorPickerField).first;
      expect(backgroundColorField, findsOneWidget,
          reason: 'Background color field should be present');
      await tester.tap(backgroundColorField);
      await tester.pumpAndSettle();

      // 选择颜色
      await tester.tap(find.text(l10n.dialogDefaultConfirm));
      await tester.pumpAndSettle();

      // 修改文本颜色
      final textColorField = find.byType(ColorPickerField).last;
      expect(textColorField, findsOneWidget,
          reason: 'Text color field should be present');
      await tester.tap(textColorField);
      await tester.pumpAndSettle();

      // 选择颜色
      await tester.tap(find.text(l10n.dialogDefaultConfirm));
      await tester.pumpAndSettle();

      // 修改位置和内边距
      // X坐标
      final xField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.labelText == 'x',
      );
      expect(xField, findsOneWidget,
          reason: 'X position field should be present');
      await tester.enterText(xField, '100');
      await tester.pumpAndSettle();

      // Y坐标
      final yField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.labelText == 'y',
      );
      expect(yField, findsOneWidget,
          reason: 'Y position field should be present');
      await tester.enterText(yField, '200');
      await tester.pumpAndSettle();

      // 左内边距
      final leftPaddingField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.labelText == 'L',
      );
      expect(leftPaddingField, findsOneWidget,
          reason: 'Left padding field should be present');
      await tester.enterText(leftPaddingField, '10');
      await tester.pumpAndSettle();

      // 上内边距
      final topPaddingField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.labelText == 'T',
      );
      expect(topPaddingField, findsOneWidget,
          reason: 'Top padding field should be present');
      await tester.enterText(topPaddingField, '10');
      await tester.pumpAndSettle();

      // 右内边距
      final rightPaddingField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.labelText == 'R',
      );
      expect(rightPaddingField, findsOneWidget,
          reason: 'Right padding field should be present');
      await tester.enterText(rightPaddingField, '10');
      await tester.pumpAndSettle();

      // 下内边距
      final bottomPaddingField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.labelText == 'B',
      );
      expect(bottomPaddingField, findsOneWidget,
          reason: 'Bottom padding field should be present');
      await tester.enterText(bottomPaddingField, '10');
      await tester.pumpAndSettle();

      // 点击保存按钮
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      // 等待页面完全更新
      await tester.pump(const Duration(milliseconds: 300));

      // 打印调试信息
      debugPrint('规则列表长度: ${ruleProvider.rules.length}');
      for (final rule in ruleProvider.rules) {
        debugPrint('规则名称: ${rule.name}');
        debugPrint('包名: ${rule.packageName}');
        debugPrint('活动名: ${rule.activityName}');
        debugPrint('标签: ${rule.tags}');
      }

      // 验证规则列表页面上的显示
      expect(find.text('Test Rule'), findsOneWidget,
          reason: 'Rule name should be visible in list');
      expect(find.text('com.example.app'), findsOneWidget,
          reason: 'Package name should be visible in list');
      expect(find.text('.MainActivity'), findsOneWidget,
          reason: 'Activity name should be visible in list');
      expect(find.text('test_tag'), findsOneWidget,
          reason: 'Tag should be visible in list');

      // 验证规则是否被正确保存
      expect(ruleProvider.rules.length, equals(1),
          reason: 'Rule should be added to provider');
      final savedRule = ruleProvider.rules.first;
      expect(savedRule.name, equals('Test Rule'),
          reason: 'Rule name should match');
      expect(savedRule.packageName, equals('com.example.app'),
          reason: 'Package name should match');
      expect(savedRule.activityName, equals('.MainActivity'),
          reason: 'Activity name should match');
      expect(savedRule.tags, contains('test_tag'),
          reason: 'Tags should contain test_tag');
      expect(savedRule.isEnabled, isFalse,
          reason: 'New rule should be disabled');

      // 验证样式是否被正确保存
      expect(savedRule.overlayStyles.length, equals(1),
          reason: 'Should have one overlay style');
      final style = savedRule.overlayStyles.first;
      expect(style.text, equals('Custom Style'),
          reason: 'Style text should match');
      expect(style.uiAutomatorCode,
          equals('new UiSelector().text("Custom Style")'),
          reason: 'UI Automator code should match');
      expect(style.fontSize, equals(24.5), reason: 'Font size should match');
      expect(style.x, equals(100), reason: 'X position should match');
      expect(style.y, equals(200), reason: 'Y position should match');
      expect(style.padding.left, equals(10),
          reason: 'Left padding should match');
      expect(style.padding.top, equals(10), reason: 'Top padding should match');
      expect(style.padding.right, equals(10),
          reason: 'Right padding should match');
      expect(style.padding.bottom, equals(10),
          reason: 'Bottom padding should match');

      // 验证规则是否被正确保存到 SharedPreferences
      final savedRules = await ruleRepository.loadRules();
      expect(savedRules.length, equals(1),
          reason: 'Rule should be saved to SharedPreferences');
      final persistedRule = savedRules.first;
      expect(persistedRule.name, equals('Test Rule'),
          reason: 'Persisted rule name should match');
      expect(persistedRule.overlayStyles.length, equals(1),
          reason: 'Persisted rule should have one style');
      final persistedStyle = persistedRule.overlayStyles.first;
      expect(persistedStyle.fontSize, equals(24.5),
          reason: 'Persisted font size should match');
      expect(persistedStyle.x, equals(100),
          reason: 'Persisted X position should match');
      expect(persistedStyle.y, equals(200),
          reason: 'Persisted Y position should match');
    });

    testWidgets('Rule stats card shows correct numbers', (tester) async {
      // 设置测试窗口大小
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      // 清空规则列表
      await ruleProvider.clearRules();

      // 构建测试页面
      await buildTestApp(tester, ruleProvider, validationProvider);
      await tester.pumpAndSettle();

      // 验证初始状态
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Text &&
            widget.data == '0' &&
            widget.style?.fontSize == 20.0),
        findsNWidgets(3),
        reason: 'Should show 0 for all stats initially',
      );

      // 点击添加按钮
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 点击添加规则按钮
      final addRuleButton =
          find.widgetWithText(FloatingActionButton, l10n.addRule);
      await tester.tap(addRuleButton);
      await tester.pumpAndSettle();

      // 填写基本信息
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.ruleName),
        'Stats Test Rule',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.packageName),
        'com.example.app',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.activityName),
        '.MainActivity',
      );
      await tester.pumpAndSettle();

      // 填写第一个悬浮窗样式的文本和UI Automator代码
      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == l10n.text),
        'First Style',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.uiAutomatorCode),
        'new UiSelector().text("First Style")',
      );
      await tester.pumpAndSettle();

      // 添加第二个悬浮窗样式
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      // 填写第二个悬浮窗样式的文本和UI Automator代码
      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == l10n.text),
        'Second Style',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.uiAutomatorCode),
        'new UiSelector().text("Second Style")',
      );
      await tester.pumpAndSettle();

      // 点击保存按钮
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      // 等待页面完全更新
      await tester.pump(const Duration(milliseconds: 300));

      // 验证规则总数显示为1
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Text &&
            widget.data == '1' &&
            widget.style?.fontSize == 20.0),
        findsOneWidget,
        reason: 'Should show total rule count as 1',
      );

      // 验证启用规则数显示为0（新规则默认禁用）
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Text &&
            widget.data == '0' &&
            widget.style?.fontSize == 20.0),
        findsOneWidget,
        reason: 'Should show enabled rule count as 0',
      );

      // 验证样式总数显示为2
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Text &&
            widget.data == '2' &&
            widget.style?.fontSize == 20.0),
        findsOneWidget,
        reason: 'Should show total style count as 2',
      );

      // 启用规则
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // 验证启用规则数更新为1
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Text &&
            widget.data == '1' &&
            widget.style?.fontSize == 20.0),
        findsNWidgets(2),
        reason: 'Should show both total and enabled rule count as 1',
      );
    });

    testWidgets('Successfully edit existing rule in place', (tester) async {
      // 构建测试页面
      await buildTestApp(tester, ruleProvider, validationProvider);

      // 点击添加按钮
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 点击添加规则按钮
      final addRuleButton =
          find.widgetWithText(FloatingActionButton, l10n.addRule);
      await tester.tap(addRuleButton);
      await tester.pumpAndSettle();

      // 填写规则名称
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.ruleName),
        'Initial Rule',
      );
      await tester.pumpAndSettle();

      // 填写包名
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.packageName),
        'com.example.app',
      );
      await tester.pumpAndSettle();

      // 填写活动名
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.activityName),
        '.MainActivity',
      );
      await tester.pumpAndSettle();

      // 添加标签
      final tagInput = find.byType(TagChipsInput);
      expect(tagInput, findsOneWidget);

      // 找到TagChipsInput中的TextField
      final tagTextField = find.descendant(
        of: tagInput,
        matching: find.byType(TextField),
      );
      expect(tagTextField, findsOneWidget);

      await tester.enterText(tagTextField, 'initial_tag');
      await tester.pumpAndSettle();

      // 点击添加按钮
      final addButton = find.descendant(
        of: tagInput,
        matching: find.byIcon(Icons.add),
      );
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // 修改文本
      final textField = find.byWidgetPredicate(
        (widget) => widget is TextInputField && widget.label == l10n.text,
      );
      expect(textField, findsOneWidget, reason: 'Text field should be present');
      await tester.enterText(textField, 'Initial Text');
      await tester.pumpAndSettle();

      // 修改UI Automator代码
      final uiAutomatorTextField = find.byWidgetPredicate(
        (widget) =>
            widget is TextInputField && widget.label == l10n.uiAutomatorCode,
      );
      expect(uiAutomatorTextField, findsOneWidget,
          reason: 'UI Automator code field should be present');
      await tester.enterText(
          uiAutomatorTextField, 'new UiSelector().text("Initial Text")');
      await tester.pumpAndSettle();

      // 点击保存按钮
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      // 等待页面完全更新
      await tester.pump(const Duration(milliseconds: 500));

      // 验证规则数量为1
      expect(ruleProvider.rules.length, equals(1),
          reason: 'Should have 1 rule after saving');

      // 验证规则卡片显示正确
      expect(find.text('Initial Rule'), findsOneWidget,
          reason: 'Rule name should be visible');
      expect(find.text('initial_tag'), findsOneWidget,
          reason: 'Initial tag should be visible');

      // 保存初始规则的标识信息
      final initialRule = ruleProvider.rules.first;
      expect(initialRule.packageName, equals('com.example.app'),
          reason: 'Initial package name should match');
      expect(initialRule.activityName, equals('.MainActivity'),
          reason: 'Initial activity name should match');

      // 确保规则卡片已显示
      final ruleCard = find.byType(RuleCard);
      expect(ruleCard, findsOneWidget, reason: 'Rule card should be visible');
      await tester.pumpAndSettle();

      // 点击规则卡片进入编辑页面
      await tester.tap(ruleCard);
      await tester.pumpAndSettle();

      // 修改规则名称
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.ruleName),
        'Updated Rule',
      );
      await tester.pumpAndSettle();

      // 验证包名和活动名保持不变
      final packageNameField = find.byWidgetPredicate((widget) =>
          widget is TextInputField && widget.label == l10n.packageName);
      expect(
          find.descendant(
              of: packageNameField, matching: find.text('com.example.app')),
          findsOneWidget,
          reason: 'Package name should remain unchanged');

      final activityNameField = find.byWidgetPredicate((widget) =>
          widget is TextInputField && widget.label == l10n.activityName);
      expect(
          find.descendant(
              of: activityNameField, matching: find.text('.MainActivity')),
          findsOneWidget,
          reason: 'Activity name should remain unchanged');

      // 添加新标签
      final editTagInput = find.byType(TagChipsInput);
      final editTagTextField = find.descendant(
        of: editTagInput,
        matching: find.byType(TextField),
      );
      await tester.enterText(editTagTextField, 'new_tag');
      await tester.pumpAndSettle();

      final editAddButton = find.descendant(
        of: editTagInput,
        matching: find.byIcon(Icons.add),
      );
      await tester.tap(editAddButton);
      await tester.pumpAndSettle();

      // 修改文本
      final editTextField = find.byWidgetPredicate(
        (widget) => widget is TextInputField && widget.label == l10n.text,
      );
      await tester.enterText(editTextField, 'Updated Text');
      await tester.pumpAndSettle();

      // 修改UI Automator代码
      final editUiAutomatorTextField = find.byWidgetPredicate(
        (widget) =>
            widget is TextInputField && widget.label == l10n.uiAutomatorCode,
      );
      await tester.enterText(
          editUiAutomatorTextField, 'new UiSelector().text("Updated Text")');
      await tester.pumpAndSettle();

      // 点击保存按钮
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      // 等待页面完全更新
      await tester.pump(const Duration(milliseconds: 300));

      // 打印调试信息
      debugPrint('规则列表长度: ${ruleProvider.rules.length}');
      for (final rule in ruleProvider.rules) {
        debugPrint('规则名称: ${rule.name}');
        debugPrint('包名: ${rule.packageName}');
        debugPrint('活动名: ${rule.activityName}');
        debugPrint('标签: ${rule.tags}');
      }

      // 验证规则数量仍为1
      expect(ruleProvider.rules.length, equals(1),
          reason: 'Should still have 1 rule after updating');

      // 获取更新后的规则
      final updatedRule = ruleProvider.rules.first;

      // 验证规则属性
      expect(updatedRule.name, equals('Updated Rule'),
          reason: 'Rule name should be updated');
      expect(updatedRule.tags, containsAll(['initial_tag', 'new_tag']),
          reason: 'Rule should have both tags');
      expect(updatedRule.packageName, equals(initialRule.packageName),
          reason: 'Package name should remain unchanged');
      expect(updatedRule.activityName, equals(initialRule.activityName),
          reason: 'Activity name should remain unchanged');
      expect(updatedRule.overlayStyles.length, equals(1),
          reason: 'Should have 1 overlay style');
      expect(updatedRule.overlayStyles[0].text, equals('Updated Text'),
          reason: 'Overlay style text should be updated');
      expect(updatedRule.overlayStyles[0].uiAutomatorCode,
          equals('new UiSelector().text("Updated Text")'),
          reason: 'UI Automator code should be updated');

      // 验证 UI 更新
      expect(find.text('Updated Rule'), findsOneWidget,
          reason: 'Updated rule name should be visible in list');
      expect(find.text('initial_tag'), findsOneWidget,
          reason: 'Initial tag should still be visible in list');
      expect(find.text('new_tag'), findsOneWidget,
          reason: 'New tag should be visible in list');
      expect(find.text('com.example.app'), findsOneWidget,
          reason: 'Package name should be visible in list');
      expect(find.text('.MainActivity'), findsOneWidget,
          reason: 'Activity name should be visible in list');
    });
  });
}
