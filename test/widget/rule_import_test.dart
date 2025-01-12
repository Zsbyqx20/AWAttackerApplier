import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import 'package:awattackerapplier/widgets/rule_import_preview_dialog.dart';
import 'package:awattackerapplier/widgets/rule_import_result_dialog.dart';

void main() {
  group('Rule import tests', () {
    late SharedPreferences sharedPreferences;
    late RuleRepository ruleRepository;
    late StorageRepository storageRepository;
    late RuleValidationProvider ruleValidationProvider;
    late RuleProvider ruleProvider;
    late String testRuleJson;
    late String testMergeableRuleJson;
    late String testConflictingRuleJson;

    setUp(() async {
      // 初始化 SharedPreferences
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();

      // 初始化存储库和提供者
      storageRepository = StorageRepository();
      await storageRepository.init();
      ruleRepository = RuleRepository(sharedPreferences);
      ruleValidationProvider = RuleValidationProvider();
      ruleProvider = RuleProvider(
        ruleRepository,
        storageRepository,
        ruleValidationProvider,
      );

      // 读取测试数据
      testRuleJson = await File('test/fixtures/test_rule.json').readAsString();
      testMergeableRuleJson =
          await File('test/fixtures/test_mergeable_rule.json').readAsString();
      testConflictingRuleJson =
          await File('test/fixtures/test_conflicting_rule.json').readAsString();
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
            home: const RuleListPage(),
          ),
        ),
      );
    }

    Future<void> tapMainFab(WidgetTester tester) async {
      final mainFab = find.byIcon(Icons.add);
      expect(mainFab, findsOneWidget);
      await tester.tap(mainFab);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    }

    Future<void> tapImportButton(
        WidgetTester tester, String importRulesText) async {
      final importButton = find.ancestor(
        of: find.text(importRulesText),
        matching: find.byType(FloatingActionButton),
        matchRoot: true,
      );
      expect(importButton, findsOneWidget);
      await tester.tap(importButton);
      await tester.pumpAndSettle();
    }

    Future<void> importBaseRule(WidgetTester tester) async {
      // Mock method channel call for base rule
      const channel =
          MethodChannel('com.mobilellm.awattackerapplier/overlay_service');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'openFile') {
          return testRuleJson;
        }
        return null;
      });

      // Get l10n
      final l10n =
          AppLocalizations.of(tester.element(find.byType(RuleListPage)))!;

      // Import base rule
      await tester.pumpAndSettle();
      await tapMainFab(tester);
      await tapImportButton(tester, l10n.importRules);
      await tester.tap(find.text(l10n.ruleImportPreviewDialogImport));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.dialogDefaultConfirm));
      await tester.pumpAndSettle();

      // Verify base rule is imported
      expect(find.text('Test Rule'), findsOneWidget);
      expect(ruleProvider.rules.length, 1);
    }

    testWidgets('Successfully import rules from JSON file',
        (WidgetTester tester) async {
      // Set up test window size
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      // Clear rules list
      await ruleRepository.clearRules();

      // Build test page
      await buildTestApp(tester);

      // Mock method channel call
      const channel =
          MethodChannel('com.mobilellm.awattackerapplier/overlay_service');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'openFile') {
          return testRuleJson;
        }
        return null;
      });

      // Get l10n
      final l10n =
          AppLocalizations.of(tester.element(find.byType(RuleListPage)))!;

      // Wait for UI to settle
      await tester.pumpAndSettle();

      // Find and tap the main FAB
      await tapMainFab(tester);

      // Find and tap import rules button
      await tapImportButton(tester, l10n.importRules);

      // Wait for import preview dialog
      expect(find.byType(RuleImportPreviewDialog), findsOneWidget);

      // Find and tap confirm button
      final confirmButton = find.text(l10n.ruleImportPreviewDialogImport);
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Wait for import result dialog
      expect(find.byType(RuleImportResultDialog), findsOneWidget);
      expect(find.text(l10n.importSuccess), findsOneWidget);

      // Find and tap close button
      final closeButton = find.text(l10n.dialogDefaultConfirm);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify imported rule is displayed
      expect(find.text('Test Rule'), findsOneWidget);
      expect(find.text('com.example.app'), findsOneWidget);
      expect(find.text('.MainActivity'), findsOneWidget);
      expect(find.text('test_tag'), findsOneWidget);

      // Verify rule is saved in provider
      final rules = ruleProvider.rules;
      expect(rules.length, 1);
      expect(rules[0].name, 'Test Rule');
      expect(rules[0].packageName, 'com.example.app');
      expect(rules[0].activityName, '.MainActivity');
      expect(rules[0].tags, ['test_tag']);
      expect(rules[0].overlayStyles.length, 1);
      expect(rules[0].overlayStyles[0].text, 'Test Style');
      expect(rules[0].overlayStyles[0].uiAutomatorCode,
          'new UiSelector().text("Test Style")');

      // Verify rule is saved in SharedPreferences
      final savedRules = await ruleRepository.loadRules();
      expect(savedRules.length, 1);
      expect(savedRules[0].name, 'Test Rule');
      expect(savedRules[0].packageName, 'com.example.app');
      expect(savedRules[0].activityName, '.MainActivity');
      expect(savedRules[0].tags, ['test_tag']);
      expect(savedRules[0].overlayStyles.length, 1);
      expect(savedRules[0].overlayStyles[0].text, 'Test Style');
      expect(savedRules[0].overlayStyles[0].uiAutomatorCode,
          'new UiSelector().text("Test Style")');
    });

    testWidgets('Import mergeable rule', (WidgetTester tester) async {
      // Set up test window size
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      // First import a base rule
      await ruleRepository.clearRules();
      await buildTestApp(tester);
      await importBaseRule(tester);

      // Now try to import mergeable rule
      const channel =
          MethodChannel('com.mobilellm.awattackerapplier/overlay_service');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'openFile') {
          return testMergeableRuleJson;
        }
        return null;
      });

      // Get l10n
      final l10n =
          AppLocalizations.of(tester.element(find.byType(RuleListPage)))!;

      // Import mergeable rule
      await tapMainFab(tester);
      await tapImportButton(tester, l10n.importRules);

      // Verify preview dialog shows correct status
      expect(find.byType(RuleImportPreviewDialog), findsOneWidget);
      expect(find.text('Mergeable Rule'), findsOneWidget);
      expect(find.text(l10n.ruleImportPreviewDialogImportMergeable),
          findsOneWidget);

      // 验证规则在导入前的状态
      expect(ruleProvider.rules.length, 1);
      final beforeRule = ruleProvider.rules[0];
      expect(beforeRule.tags, ['test_tag']);

      // Import the rule
      await tester.tap(find.text(l10n.ruleImportPreviewDialogImport));
      await tester.pumpAndSettle();

      // Verify import result
      expect(find.byType(RuleImportResultDialog), findsOneWidget);
      expect(find.text(l10n.importSuccess), findsOneWidget);
      await tester.tap(find.text(l10n.dialogDefaultConfirm));
      await tester.pumpAndSettle();

      // 验证规则在导入后的状态
      final rules = ruleProvider.rules;
      expect(rules.length, 1); // 仍然是1条规则，因为是合并的
      final mergedRule = rules[0];
      expect(mergedRule.name, 'Test Rule');
      expect(mergedRule.packageName, 'com.example.app');
      expect(mergedRule.activityName, '.MainActivity');
      expect(mergedRule.tags, containsAll(['test_tag', 'test_tag_2']));
      expect(mergedRule.overlayStyles.length, 2);
      expect(
          mergedRule.overlayStyles.any((s) =>
              s.uiAutomatorCode == 'new UiSelector().text("Test Style")'),
          isTrue);
      expect(
          mergedRule.overlayStyles.any(
              (s) => s.uiAutomatorCode == 'new UiSelector().text("New Style")'),
          isTrue);
    });

    testWidgets('Import conflicting rule', (WidgetTester tester) async {
      // Set up test window size
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      // First import a base rule
      await ruleRepository.clearRules();
      await buildTestApp(tester);
      await importBaseRule(tester);

      // Now try to import conflicting rule
      const channel =
          MethodChannel('com.mobilellm.awattackerapplier/overlay_service');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'openFile') {
          return testConflictingRuleJson;
        }
        return null;
      });

      // Get l10n
      final l10n =
          AppLocalizations.of(tester.element(find.byType(RuleListPage)))!;

      // Import conflicting rule
      await tapMainFab(tester);
      await tapImportButton(tester, l10n.importRules);

      // Verify preview dialog shows correct status
      expect(find.byType(RuleImportPreviewDialog), findsOneWidget);
      expect(find.text('Conflicting Rule'), findsOneWidget);
      expect(find.text(l10n.ruleImportPreviewDialogConflict), findsOneWidget);

      // Verify the rule cannot be selected (checkbox should be disabled)
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);
      expect(tester.widget<Checkbox>(checkbox).onChanged, isNull);

      // Try to import anyway
      await tester.tap(find.text(l10n.ruleImportPreviewDialogImport));
      await tester.pumpAndSettle();

      // 冲突的规则不会被导入，所以不会显示导入结果对话框
      expect(find.byType(RuleImportResultDialog), findsNothing);

      // Verify final state (should be unchanged)
      final rules = ruleProvider.rules;
      expect(rules.length, 1);
      final rule = rules[0];
      expect(rule.name, 'Test Rule');
      expect(rule.packageName, 'com.example.app');
      expect(rule.activityName, '.MainActivity');
      expect(rule.tags, ['test_tag']);
      expect(rule.overlayStyles.length, 1);
      expect(rule.overlayStyles[0].text, 'Test Style');
      expect(rule.overlayStyles[0].uiAutomatorCode,
          'new UiSelector().text("Test Style")');
    });
  });
}
