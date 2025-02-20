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
import 'package:awattackerapplier/widgets/style_editor.dart';
import 'package:awattackerapplier/widgets/tag_chip.dart';
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
      expect(savedRule.overlayStyles.first.allow, isNull,
          reason: 'Allow conditions should be null initially');
      expect(savedRule.overlayStyles.first.deny, isNull,
          reason: 'Deny conditions should be null initially');

      // 验证规则是否被正确保存到 SharedPreferences
      final savedRules = await ruleRepository.loadRules();
      expect(savedRules.length, equals(1),
          reason: 'Rule should be saved to SharedPreferences');
      final persistedRule = savedRules.first;
      expect(persistedRule.name, equals('Test Rule'),
          reason: 'Persisted rule name should match');
      expect(persistedRule.overlayStyles.length, equals(1),
          reason: 'Persisted rule should have one style');
      expect(persistedRule.overlayStyles.first.allow, isNull,
          reason: 'Persisted allow conditions should be null');
      expect(persistedRule.overlayStyles.first.deny, isNull,
          reason: 'Persisted deny conditions should be null');
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
      // 找到样式标题旁边的添加按钮
      final addStyleButton = find.descendant(
        of: find.ancestor(
          of: find.text(l10n.overlayStyleTitle),
          matching: find.byType(Row),
        ),
        matching: find.byIcon(Icons.add_circle_outline),
      );
      expect(addStyleButton, findsOneWidget,
          reason: 'Add style button should be present');
      await tester.tap(addStyleButton);
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

      // 验证两个样式的条件列表
      for (final style in savedRule.overlayStyles) {
        expect(style.allow, isNull,
            reason: 'Allow conditions should be null initially');
        expect(style.deny, isNull,
            reason: 'Deny conditions should be null initially');
      }

      // 验证规则是否被正确保存到 SharedPreferences
      final savedRules = await ruleRepository.loadRules();
      expect(savedRules.length, equals(1),
          reason: 'Rule should be saved to SharedPreferences');
      final persistedRule = savedRules.first;
      expect(persistedRule.name, equals('Test Rule'),
          reason: 'Persisted rule name should match');
      expect(persistedRule.overlayStyles.length, equals(2),
          reason: 'Persisted rule should have two styles');
      for (final style in persistedRule.overlayStyles) {
        expect(style.allow, isNull,
            reason: 'Persisted allow conditions should be null');
        expect(style.deny, isNull,
            reason: 'Persisted deny conditions should be null');
      }
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
      expect(style.allow, isNull, reason: 'Allow conditions should be null');
      expect(style.deny, isNull, reason: 'Deny conditions should be null');

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

      // 点击主 FAB 展开菜单
      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pumpAndSettle();

      // 点击添加规则按钮
      final addRuleButton = find.byWidgetPredicate((widget) =>
          widget is FloatingActionButton && widget.heroTag == 'add');
      expect(addRuleButton, findsOneWidget,
          reason: 'Add rule button should be present');
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
      final addStyleButton = find.descendant(
        of: find.ancestor(
          of: find.text(l10n.overlayStyleTitle),
          matching: find.byType(Row),
        ),
        matching: find.byIcon(Icons.add_circle_outline),
      );
      expect(addStyleButton, findsOneWidget,
          reason: 'Add style button should be present');
      await tester.tap(addStyleButton);
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
      await tester.tap(find.widgetWithText(TextButton, l10n.save));
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
      expect(updatedRule.overlayStyles[0].allow, isNull,
          reason: 'Allow conditions should remain null');
      expect(updatedRule.overlayStyles[0].deny, isNull,
          reason: 'Deny conditions should remain null');

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

    testWidgets('Successfully add and remove conditions', (tester) async {
      // 设置足够大的窗口尺寸
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      // 清空规则列表
      await ruleProvider.clearRules();

      // 构建测试页面
      await buildTestApp(tester, ruleProvider, validationProvider);
      await tester.pumpAndSettle();

      // 点击主 FAB 展开菜单
      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pumpAndSettle();

      // 点击添加规则按钮
      final addRuleButton = find.byWidgetPredicate((widget) =>
          widget is FloatingActionButton && widget.heroTag == 'add');
      expect(addRuleButton, findsOneWidget);
      await tester.tap(addRuleButton);
      await tester.pumpAndSettle();

      // 填写基本信息
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.ruleName),
        'Test Rule',
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

      // 填写文本和UI Automator代码
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) => widget is TextInputField && widget.label == l10n.text,
        ),
        'Test Text',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextInputField && widget.label == l10n.uiAutomatorCode,
        ),
        'new UiSelector().text("Test Text")',
      );
      await tester.pumpAndSettle();

      // 滚动到条件列表编辑器
      final scrollable = find.byType(Scrollable);
      await tester.scrollUntilVisible(
        find.text(l10n.allowConditions),
        500.0,
        scrollable: scrollable.first,
      );
      await tester.pumpAndSettle();

      // 找到条件列表编辑器的标题行
      final allowConditionsRow = find.ancestor(
        of: find.text(l10n.allowConditions),
        matching: find.byType(Row),
      );
      expect(allowConditionsRow, findsOneWidget);

      // 在标题行中找到并点击添加按钮
      final addConditionButton = find.descendant(
        of: allowConditionsRow,
        matching: find.byWidgetPredicate((widget) =>
            widget is IconButton && widget.tooltip == 'Add condition'),
      );
      expect(addConditionButton, findsOneWidget);

      await tester.tap(addConditionButton);
      await tester.pumpAndSettle();

      // 输入条件
      final conditionTextField = find.descendant(
        of: find.byType(ConditionListEditor),
        matching: find.byType(TextField),
      );
      expect(conditionTextField, findsOneWidget);
      await tester.enterText(conditionTextField, 'Test Condition');
      await tester.pumpAndSettle();

      // 点击保存按钮
      await tester.tap(find.widgetWithText(TextButton, l10n.save));
      await tester.pumpAndSettle();

      // 等待页面完全更新
      await tester.pump(const Duration(milliseconds: 300));

      // 验证规则是否被正确保存
      final rules = await ruleRepository.loadRules();
      expect(rules.length, equals(1), reason: 'Should have one rule saved');

      final savedRule = rules.first;
      expect(savedRule.name, equals('Test Rule'),
          reason: 'Rule name should match');
      expect(savedRule.packageName, equals('com.example.app'),
          reason: 'Package name should match');
      expect(savedRule.activityName, equals('.MainActivity'),
          reason: 'Activity name should match');
      expect(savedRule.overlayStyles.length, equals(1),
          reason: 'Should have one overlay style');
      expect(savedRule.overlayStyles.first.allow, equals(['Test Condition']),
          reason: 'Allow conditions should match');
    });

    testWidgets('Empty conditions are not saved', (tester) async {
      // 设置测试窗口大小
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      // 清空规则列表
      await ruleProvider.clearRules();

      // 构建测试页面
      await buildTestApp(tester, ruleProvider, validationProvider);

      // 点击主 FAB 展开菜单
      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pumpAndSettle();

      // 点击添加规则按钮
      await tester.tap(find.byWidgetPredicate((widget) =>
          widget is FloatingActionButton && widget.heroTag == 'add'));
      await tester.pumpAndSettle();

      // 填写必要的字段
      await tester.enterText(
          find.widgetWithText(TextInputField, l10n.ruleName), 'Test Rule');
      await tester.enterText(
          find.widgetWithText(TextInputField, l10n.packageName),
          'com.example.app');
      await tester.enterText(
          find.widgetWithText(TextInputField, l10n.activityName),
          '.MainActivity');
      await tester.enterText(
          find.widgetWithText(TextInputField, l10n.text), 'Test Text');
      await tester.enterText(
          find.widgetWithText(TextInputField, l10n.uiAutomatorCode),
          'new UiSelector().text("Test Text")');

      // 点击保存按钮
      await tester.tap(find.widgetWithText(TextButton, l10n.save));
      await tester.pumpAndSettle();

      // 等待页面完全更新
      await tester.pump(const Duration(milliseconds: 300));

      // 验证规则是否被正确保存
      final rules = await ruleRepository.loadRules();
      expect(rules.length, equals(1), reason: 'Should have one rule saved');

      final savedRule = rules.first;
      expect(savedRule.name, equals('Test Rule'),
          reason: 'Rule name should match');
      expect(savedRule.packageName, equals('com.example.app'),
          reason: 'Package name should match');
      expect(savedRule.activityName, equals('.MainActivity'),
          reason: 'Activity name should match');
      expect(savedRule.overlayStyles.length, equals(1),
          reason: 'Should have one overlay style');

      // 验证条件列表
      final style = savedRule.overlayStyles.first;
      expect(style.allow, isNull, reason: 'Allow conditions should be null');
      expect(style.deny, isNull, reason: 'Deny conditions should be null');
    });

    testWidgets('Displays empty state hint text for conditions',
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

      // 点击主 FAB 展开菜单
      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pumpAndSettle();

      // 点击添加规则按钮
      final addRuleButton = find.byWidgetPredicate((widget) =>
          widget is FloatingActionButton && widget.heroTag == 'add');
      expect(addRuleButton, findsOneWidget);
      await tester.tap(addRuleButton);
      await tester.pumpAndSettle();

      // 验证空状态提示文本
      expect(find.text(l10n.emptyConditionListHint), findsNWidgets(2));

      // 验证提示文本的样式
      final hintText = find.text(l10n.emptyConditionListHint).first;
      final textWidget = tester.widget<Text>(hintText);
      expect(textWidget.style?.color, Colors.grey[600]);
      expect(textWidget.textAlign, TextAlign.center);
    });

    testWidgets('Should not save rule multiple times when saving quickly',
        (tester) async {
      // 设置测试窗口大小
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      // 清空规则列表
      await ruleProvider.clearRules();

      // 构建测试页面
      await buildTestApp(tester, ruleProvider, validationProvider);

      // 点击主 FAB 展开菜单
      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pumpAndSettle();

      // 点击添加规则按钮
      final addRuleButton = find.byWidgetPredicate((widget) =>
          widget is FloatingActionButton && widget.heroTag == 'add');
      expect(addRuleButton, findsOneWidget);
      await tester.tap(addRuleButton);
      await tester.pumpAndSettle();

      // 填写规则信息
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.ruleName),
        'Test Rule',
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

      // 添加标签
      final tagInput = find.byType(TagChipsInput);
      expect(tagInput, findsOneWidget);

      final tagTextField = find.descendant(
        of: tagInput,
        matching: find.byType(TextField),
      );
      expect(tagTextField, findsOneWidget);

      await tester.enterText(tagTextField, 'test_tag');
      await tester.pumpAndSettle();

      final addTagButton = find.descendant(
        of: tagInput,
        matching: find.byIcon(Icons.add),
      );
      await tester.tap(addTagButton);
      await tester.pumpAndSettle();

      // 添加悬浮窗样式
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) => widget is TextInputField && widget.label == l10n.text,
        ),
        'Initial Style',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextInputField && widget.label == l10n.uiAutomatorCode,
        ),
        'new UiSelector().text("Initial Style")',
      );
      await tester.pumpAndSettle();

      // 保存初始规则
      final saveButton = find.widgetWithText(TextButton, l10n.save);
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // 等待保存完成
      await tester.pump(const Duration(milliseconds: 500));

      // 验证规则只被保存了一次
      final savedRules = await ruleRepository.loadRules();
      expect(savedRules.length, equals(1),
          reason: 'Rule should only be saved once');

      // 验证规则内容正确
      final savedRule = savedRules.first;
      expect(savedRule.name, equals('Test Rule'),
          reason: 'Rule name should match');
      expect(savedRule.packageName, equals('com.example.app'),
          reason: 'Package name should match');
      expect(savedRule.activityName, equals('.MainActivity'),
          reason: 'Activity name should match');
      expect(savedRule.tags, equals(['test_tag']), reason: 'Tags should match');
      expect(savedRule.overlayStyles.length, equals(1),
          reason: 'Should have one overlay style');
      expect(savedRule.overlayStyles.first.text, equals('Initial Style'),
          reason: 'Style text should match');
      expect(savedRule.overlayStyles.first.uiAutomatorCode,
          equals('new UiSelector().text("Initial Style")'),
          reason: 'UI Automator code should match');
    });

    testWidgets('Should maintain consistent state during rule updates',
        (tester) async {
      // 设置测试窗口大小
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      // 清空规则列表
      await ruleProvider.clearRules();

      // 构建测试页面
      await buildTestApp(tester, ruleProvider, validationProvider);

      // 创建并保存初始规则
      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pumpAndSettle();

      final addRuleButton = find.byWidgetPredicate((widget) =>
          widget is FloatingActionButton && widget.heroTag == 'add');
      await tester.tap(addRuleButton);
      await tester.pumpAndSettle();

      // 填写初始规则信息
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.ruleName),
        'Initial Rule',
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

      // 添加初始标签
      final tagInput = find.byType(TagChipsInput);
      final tagTextField = find.descendant(
        of: tagInput,
        matching: find.byType(TextField),
      );
      await tester.enterText(tagTextField, 'initial_tag');
      await tester.pumpAndSettle();

      final addTagButton = find.descendant(
        of: tagInput,
        matching: find.byIcon(Icons.add),
      );
      await tester.tap(addTagButton);
      await tester.pumpAndSettle();

      // 添加悬浮窗样式
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) => widget is TextInputField && widget.label == l10n.text,
        ),
        'Initial Style',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextInputField && widget.label == l10n.uiAutomatorCode,
        ),
        'new UiSelector().text("Initial Style")',
      );
      await tester.pumpAndSettle();

      // 保存初始规则
      final saveButton = find.widgetWithText(TextButton, l10n.save);
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // 等待保存完成
      await tester.pump(const Duration(milliseconds: 500));

      // 验证初始状态
      expect(ruleProvider.rules.length, equals(1),
          reason: 'Should have one rule initially');
      expect(find.text('Initial Rule'), findsOneWidget,
          reason: 'Initial rule should be visible');
      expect(find.text('initial_tag'), findsOneWidget,
          reason: 'Initial tag should be visible');

      // 记录初始规则的状态
      final initialRule = ruleProvider.rules.first;
      final initialRuleId = initialRule.packageName + initialRule.activityName;

      // 启用规则
      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // 验证规则已启用
      expect(ruleProvider.rules.first.isEnabled, isTrue,
          reason: 'Rule should be enabled');

      // 点击规则卡片进入编辑模式
      await tester.tap(find.byType(RuleCard));
      await tester.pumpAndSettle();

      // 修改规则名称
      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == l10n.ruleName),
        'Updated Rule',
      );
      await tester.pumpAndSettle();

      // 添加新标签
      await tester.enterText(tagTextField, 'new_tag');
      await tester.pumpAndSettle();
      await tester.tap(addTagButton);
      await tester.pumpAndSettle();

      // 保存更新后的规则
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // 验证 UI 状态
      expect(find.text('Updated Rule'), findsOneWidget,
          reason: 'Updated rule name should be visible');
      expect(find.text('initial_tag'), findsOneWidget,
          reason: 'Initial tag should still be visible');
      expect(find.text('new_tag'), findsOneWidget,
          reason: 'New tag should be visible');

      // 验证 Provider 状态
      expect(ruleProvider.rules.length, equals(1),
          reason: 'Should still have only one rule');
      final updatedRule = ruleProvider.rules.first;
      expect(updatedRule.name, equals('Updated Rule'),
          reason: 'Rule name should be updated in provider');
      expect(updatedRule.isEnabled, isTrue,
          reason: 'Rule should remain enabled');
      expect(updatedRule.tags, containsAll(['initial_tag', 'new_tag']),
          reason: 'Rule should have both tags in provider');

      // 验证存储状态
      final savedRules = await ruleRepository.loadRules();
      expect(savedRules.length, equals(1),
          reason: 'Should have one rule in storage');
      final savedRule = savedRules.first;
      expect(savedRule.name, equals('Updated Rule'),
          reason: 'Rule name should be updated in storage');
      expect(savedRule.isEnabled, isTrue,
          reason: 'Rule should remain enabled in storage');
      expect(savedRule.tags, containsAll(['initial_tag', 'new_tag']),
          reason: 'Rule should have both tags in storage');

      // 验证规则标识保持不变
      final updatedRuleId = savedRule.packageName + savedRule.activityName;
      expect(updatedRuleId, equals(initialRuleId),
          reason: 'Rule identifier should remain unchanged');

      // 验证标签状态
      expect(ruleProvider.allTags, containsAll(['initial_tag', 'new_tag']),
          reason: 'Provider should track all tags');

      // 验证激活标签状态
      expect(ruleProvider.activeTags, isEmpty,
          reason: 'No tags should be active initially');

      // 激活一个标签
      await ruleProvider.activateTag('new_tag');
      await tester.pumpAndSettle();

      // 验证标签激活状态
      expect(ruleProvider.activeTags, contains('new_tag'),
          reason: 'Tag should be activated');
      expect(ruleProvider.isTagActive('new_tag'), isTrue,
          reason: 'Tag should be marked as active');

      // 验证规则仍然保持启用状态
      expect(ruleProvider.rules.first.isEnabled, isTrue,
          reason: 'Rule should remain enabled after tag activation');
    });
  });
}
