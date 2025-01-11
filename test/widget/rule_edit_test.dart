import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awattackerapplier/pages/rule/rule_list_page.dart';
import 'package:awattackerapplier/providers/rule_provider.dart';
import 'package:awattackerapplier/providers/rule_validation_provider.dart';
import 'package:awattackerapplier/repositories/rule_repository.dart';
import 'package:awattackerapplier/repositories/storage_repository.dart';
import 'package:awattackerapplier/widgets/color_picker_field.dart';
import 'package:awattackerapplier/widgets/tag_chips.dart';
import 'package:awattackerapplier/widgets/text_input_field.dart';

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

      // 构建测试页面，从规则列表页面开始
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RuleProvider>.value(value: ruleProvider),
            ChangeNotifierProvider<RuleValidationProvider>.value(
                value: validationProvider),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            navigatorObservers: [navigator],
            home: const RuleListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 点击添加按钮
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 点击添加规则按钮
      final addRuleButton = find.widgetWithText(FloatingActionButton, '添加规则');
      await tester.tap(addRuleButton);
      await tester.pumpAndSettle();

      // 填写规则信息
      // 规则名称
      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '规则名称'),
        'Test Rule',
      );
      await tester.pumpAndSettle();

      // 包名
      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '包名'),
        'com.example.app',
      );
      await tester.pumpAndSettle();

      // 活动名
      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '活动名'),
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
        (widget) => widget is TextInputField && widget.label == '文本',
      );
      expect(textField, findsOneWidget, reason: 'Text field should be present');
      await tester.enterText(textField, 'Default Text');
      await tester.pumpAndSettle();

      // 修改UI Automator代码
      final uiAutomatorTextField = find.byWidgetPredicate(
        (widget) =>
            widget is TextInputField && widget.label == 'UI Automator 代码',
      );
      expect(uiAutomatorTextField, findsOneWidget,
          reason: 'UI Automator code field should be present');
      await tester.enterText(
          uiAutomatorTextField, 'new UiSelector().text("Default Text")');
      await tester.pumpAndSettle();

      // 点击保存按钮
      await tester.tap(find.text('保存'));
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
      expect(ruleProvider.rules.length, 1,
          reason: 'Rule should be added to provider');
      final savedRule = ruleProvider.rules.first;
      expect(savedRule.name, 'Test Rule', reason: 'Rule name should match');
      expect(savedRule.packageName, 'com.example.app',
          reason: 'Package name should match');
      expect(savedRule.activityName, '.MainActivity',
          reason: 'Activity name should match');
      expect(savedRule.tags, contains('test_tag'),
          reason: 'Tags should contain test_tag');
      expect(savedRule.isEnabled, false, reason: 'New rule should be disabled');
      expect(savedRule.overlayStyles.length, 1,
          reason: 'Should have one default overlay style');

      // 验证规则是否被正确保存到 SharedPreferences
      final savedRules = await ruleRepository.loadRules();
      expect(savedRules.length, 1,
          reason: 'Rule should be saved to SharedPreferences');
      final persistedRule = savedRules.first;
      expect(persistedRule.name, 'Test Rule',
          reason: 'Persisted rule name should match');
      expect(persistedRule.overlayStyles.length, 1,
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

      // 构建测试页面，从规则列表页面开始
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RuleProvider>.value(value: ruleProvider),
            ChangeNotifierProvider<RuleValidationProvider>.value(
                value: validationProvider),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            navigatorObservers: [navigator],
            home: const RuleListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 点击添加按钮
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 点击添加规则按钮
      final addRuleButton = find.widgetWithText(FloatingActionButton, '添加规则');
      await tester.tap(addRuleButton);
      await tester.pumpAndSettle();

      // 填写基本信息
      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '规则名称'),
        'Multi Style Rule',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '包名'),
        'com.example.app',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '活动名'),
        '.MainActivity',
      );
      await tester.pumpAndSettle();

      // 填写第一个悬浮窗样式的文本和UI Automator代码
      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '文本'),
        'First Style',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == 'UI Automator 代码'),
        'new UiSelector().text("First Style")',
      );
      await tester.pumpAndSettle();

      // 添加第二个悬浮窗样式
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      // 填写第二个悬浮窗样式的文本和UI Automator代码
      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '文本'),
        'Second Style',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == 'UI Automator 代码'),
        'new UiSelector().text("Second Style")',
      );
      await tester.pumpAndSettle();

      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 等待页面完全更新
      await tester.pump(const Duration(milliseconds: 300));

      // 验证规则列表页面上的显示
      expect(find.text('Multi Style Rule'), findsOneWidget,
          reason: 'Rule name should be visible in list');
      expect(find.text('com.example.app'), findsOneWidget,
          reason: 'Package name should be visible in list');
      expect(find.text('.MainActivity'), findsOneWidget,
          reason: 'Activity name should be visible in list');
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Text &&
              widget.data == '2' &&
              (widget.style?.fontSize ?? 12.0) == 12.0),
          findsOneWidget,
          reason: 'Style count should be visible in list');

      // 验证规则是否被正确保存
      expect(ruleProvider.rules.length, 1);
      final savedRule = ruleProvider.rules.first;
      expect(savedRule.name, 'Multi Style Rule');
      expect(savedRule.overlayStyles.length, 2);
      expect(savedRule.overlayStyles[1].text, 'Second Style');

      // 验证规则是否被正确保存到 SharedPreferences
      final savedRules = await ruleRepository.loadRules();
      expect(savedRules.length, 1,
          reason: 'Rule should be saved to SharedPreferences');
      final persistedRule = savedRules.first;
      expect(persistedRule.name, 'Multi Style Rule',
          reason: 'Persisted rule name should match');
      expect(persistedRule.overlayStyles.length, 2,
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

      // 构建测试页面，从规则列表页面开始
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RuleProvider>.value(value: ruleProvider),
            ChangeNotifierProvider<RuleValidationProvider>.value(
                value: validationProvider),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            navigatorObservers: [navigator],
            home: const RuleListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 点击添加按钮
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 点击添加规则按钮
      final addRuleButton = find.widgetWithText(FloatingActionButton, '添加规则');
      await tester.tap(addRuleButton);
      await tester.pumpAndSettle();

      // 填写基本信息
      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '规则名称'),
        'Style Test Rule',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '包名'),
        'com.example.app',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '活动名'),
        '.MainActivity',
      );
      await tester.pumpAndSettle();

      // 设置位置和大小
      // X 坐标
      final xField = find.widgetWithText(TextField, 'x');
      await tester.enterText(xField, '100');
      await tester.pumpAndSettle();

      // Y 坐标
      final yField = find.widgetWithText(TextField, 'y');
      await tester.enterText(yField, '200');
      await tester.pumpAndSettle();

      // 宽度
      final widthField = find.widgetWithText(TextField, '宽度');
      await tester.enterText(widthField, '300');
      await tester.pumpAndSettle();

      // 高度
      final heightField = find.widgetWithText(TextField, '高度');
      await tester.enterText(heightField, '400');
      await tester.pumpAndSettle();

      // 设置内边距
      // 左边距
      final leftPaddingField = find.widgetWithText(TextField, 'L');
      await tester.enterText(leftPaddingField, '10');
      await tester.pumpAndSettle();

      // 上边距
      final topPaddingField = find.widgetWithText(TextField, 'T');
      await tester.enterText(topPaddingField, '20');
      await tester.pumpAndSettle();

      // 右边距
      final rightPaddingField = find.widgetWithText(TextField, 'R');
      await tester.enterText(rightPaddingField, '30');
      await tester.pumpAndSettle();

      // 下边距
      final bottomPaddingField = find.widgetWithText(TextField, 'B');
      await tester.enterText(bottomPaddingField, '40');
      await tester.pumpAndSettle();

      // 设置对齐方式
      // 水平对齐：右对齐
      final horizontalAlignButton = find.byIcon(Icons.format_align_right);
      await tester.tap(horizontalAlignButton);
      await tester.pumpAndSettle();

      // 验证水平对齐按钮状态
      final horizontalAlignContainer = find
          .ancestor(
            of: horizontalAlignButton,
            matching: find.byType(Container),
          )
          .first;
      expect(
        tester.widget<Container>(horizontalAlignContainer).decoration,
        isA<BoxDecoration>().having(
          (d) => d.color,
          'color',
          isNotNull,
        ),
        reason: 'Right align button should be highlighted',
      );

      // 垂直对齐：底部对齐
      final verticalAlignButton = find.byIcon(Icons.align_vertical_bottom);
      await tester.tap(verticalAlignButton);
      await tester.pumpAndSettle();
      await tester.tap(verticalAlignButton); // 再次点击以确保选中
      await tester.pumpAndSettle();

      // 验证垂直对齐按钮状态
      final verticalAlignContainer = find
          .ancestor(
            of: verticalAlignButton,
            matching: find.byType(Container),
          )
          .first;
      expect(
        tester.widget<Container>(verticalAlignContainer).decoration,
        isA<BoxDecoration>().having(
          (d) => d.color,
          'color',
          isNotNull,
        ),
        reason: 'Bottom align button should be highlighted',
      );

      // 设置颜色
      // 文本颜色
      final textColorPicker = find.byType(ColorPickerField).at(1);
      await tester.ensureVisible(textColorPicker);
      await tester.pumpAndSettle();
      await tester.tap(textColorPicker);
      await tester.pumpAndSettle();

      // 在颜色选择器对话框中输入颜色值
      final textColorInput = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(textColorInput, findsOneWidget,
          reason: 'Color input field should be present');
      await tester.enterText(textColorInput, 'FF0000FF');
      await tester.pumpAndSettle();

      // 点击确定按钮
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      // 背景颜色
      final backgroundColorPicker = find.byType(ColorPickerField).first;
      await tester.ensureVisible(backgroundColorPicker);
      await tester.pumpAndSettle();
      await tester.tap(backgroundColorPicker);
      await tester.pumpAndSettle();

      // 在颜色选择器对话框中输入颜色值
      final backgroundColorInput = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(backgroundColorInput, findsOneWidget,
          reason: 'Color input field should be present');
      await tester.enterText(backgroundColorInput, '80FFFF00');
      await tester.pumpAndSettle();

      // 点击确定按钮
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      // 设置文本和UI Automator代码
      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '文本'),
        'Styled Text',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == 'UI Automator 代码'),
        'new UiSelector().text("Styled Text")',
      );
      await tester.pumpAndSettle();

      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 等待页面完全更新
      await tester.pump(const Duration(milliseconds: 300));

      // 验证规则列表页面上的显示
      expect(find.text('Style Test Rule'), findsOneWidget,
          reason: 'Rule name should be visible in list');
      expect(find.text('com.example.app'), findsOneWidget,
          reason: 'Package name should be visible in list');
      expect(find.text('.MainActivity'), findsOneWidget,
          reason: 'Activity name should be visible in list');

      // 验证规则是否被正确保存
      expect(ruleProvider.rules.length, 1);
      final savedRule = ruleProvider.rules.first;
      expect(savedRule.name, 'Style Test Rule');
      expect(savedRule.overlayStyles.length, 1);

      final savedStyle = savedRule.overlayStyles.first;
      expect(savedStyle.x, 100);
      expect(savedStyle.y, 200);
      expect(savedStyle.width, 300);
      expect(savedStyle.height, 400);
      expect(savedStyle.padding.left, 10);
      expect(savedStyle.padding.top, 20);
      expect(savedStyle.padding.right, 30);
      expect(savedStyle.padding.bottom, 40);
      expect(savedStyle.horizontalAlign, TextAlign.right);
      expect(savedStyle.verticalAlign, TextAlign.end);
      expect(savedStyle.textColor, const Color(0xFF0000FF));
      expect(savedStyle.backgroundColor, const Color(0x80FFFF00));

      // 验证规则是否被正确保存到 SharedPreferences
      final savedRules = await ruleRepository.loadRules();
      expect(savedRules.length, 1,
          reason: 'Rule should be saved to SharedPreferences');
      final persistedRule = savedRules.first;
      expect(persistedRule.name, 'Style Test Rule',
          reason: 'Persisted rule name should match');
      expect(persistedRule.overlayStyles.length, 1,
          reason: 'Persisted rule should have one style');

      final persistedStyle = persistedRule.overlayStyles.first;
      expect(persistedStyle.x, 100,
          reason: 'Persisted x position should match');
      expect(persistedStyle.y, 200,
          reason: 'Persisted y position should match');
      expect(persistedStyle.width, 300, reason: 'Persisted width should match');
      expect(persistedStyle.height, 400,
          reason: 'Persisted height should match');
      expect(persistedStyle.padding.left, 10,
          reason: 'Persisted left padding should match');
      expect(persistedStyle.padding.top, 20,
          reason: 'Persisted top padding should match');
      expect(persistedStyle.padding.right, 30,
          reason: 'Persisted right padding should match');
      expect(persistedStyle.padding.bottom, 40,
          reason: 'Persisted bottom padding should match');
      expect(persistedStyle.horizontalAlign, TextAlign.right,
          reason: 'Persisted horizontal alignment should match');
      expect(persistedStyle.verticalAlign, TextAlign.end,
          reason: 'Persisted vertical alignment should match');
      expect(persistedStyle.textColor, const Color(0xFF0000FF),
          reason: 'Persisted text color should match');
      expect(persistedStyle.backgroundColor, const Color(0x80FFFF00),
          reason: 'Persisted background color should match');
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
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RuleProvider>.value(value: ruleProvider),
            ChangeNotifierProvider<RuleValidationProvider>.value(
                value: validationProvider),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const RuleListPage(),
          ),
        ),
      );
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

      // 添加一个规则
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FloatingActionButton, '添加规则'));
      await tester.pumpAndSettle();

      // 填写基本信息
      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '规则名称'),
        'Stats Test Rule',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '包名'),
        'com.example.app',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '活动名'),
        '.MainActivity',
      );
      await tester.pumpAndSettle();

      // 填写第一个悬浮窗样式的文本和UI Automator代码
      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '文本'),
        'First Style',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == 'UI Automator 代码'),
        'new UiSelector().text("First Style")',
      );
      await tester.pumpAndSettle();

      // 添加第二个悬浮窗样式
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      // 填写第二个悬浮窗样式的文本和UI Automator代码
      await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextInputField && widget.label == '文本'),
        'Second Style',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextInputField && widget.label == 'UI Automator 代码'),
        'new UiSelector().text("Second Style")',
      );
      await tester.pumpAndSettle();

      // 点击保存按钮
      await tester.tap(find.text('保存'));
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
  });
}
