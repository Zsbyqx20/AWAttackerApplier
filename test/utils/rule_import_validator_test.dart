import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:awattackerapplier/exceptions/rule_import_exception.dart';
import 'package:awattackerapplier/models/overlay_style.dart';
import 'package:awattackerapplier/utils/rule_import_validator.dart';

void main() {
  group('RuleImportValidator', () {
    group('validateActivityName', () {
      test('应当通过以点号开头的相对活动名', () {
        const validActivityNames = [
          '.MainActivity',
          '.ui.MainActivity',
          '.view.main.MainActivity',
        ];

        for (final activityName in validActivityNames) {
          expect(
            () => RuleImportValidator.validateActivityName(activityName),
            returnsNormally,
          );
        }
      });

      test('应当通过不以点号开头的绝对活动名', () {
        const validActivityNames = [
          'MainActivity',
          'com.example.MainActivity',
          'com.example.ui.MainActivity',
        ];

        for (final activityName in validActivityNames) {
          expect(
            () => RuleImportValidator.validateActivityName(activityName),
            returnsNormally,
          );
        }
      });

      test('应当拒绝包含无效字符的活动名', () {
        const invalidActivityNames = [
          '.Main-Activity',
          '.ui/MainActivity',
          '.view@main.MainActivity',
          'Main-Activity',
          'com/example/MainActivity',
          'com.example@MainActivity',
        ];

        for (final activityName in invalidActivityNames) {
          expect(
            () => RuleImportValidator.validateActivityName(activityName),
            throwsA(
              predicate((e) =>
                  e is RuleImportException &&
                  e.code == 'INVALID_FIELD_VALUE' &&
                  e.message == 'Invalid field value' &&
                  (e.details as String).startsWith('Field activityName:')),
            ),
          );
        }
      });

      test('应当拒绝空活动名', () {
        expect(
          () => RuleImportValidator.validateActivityName(''),
          throwsA(
            predicate((e) =>
                e is RuleImportException &&
                e.code == 'INVALID_FIELD_VALUE' &&
                e.message == 'Invalid field value' &&
                (e.details as String).startsWith('Field activityName:')),
          ),
        );
      });
    });

    group('validatePackageName', () {
      test('应当通过有效的包名', () {
        const validPackageNames = [
          'com.example.app',
          'org.test.demo.app',
          'io.flutter.demo',
        ];

        for (final packageName in validPackageNames) {
          expect(
            () => RuleImportValidator.validatePackageName(packageName),
            returnsNormally,
          );
        }
      });

      test('应当拒绝无效的包名', () {
        const invalidPackageNames = [
          '.com.example.app',
          'com.example..app',
          'com.example.app.',
          'com.example.app-test',
        ];

        for (final packageName in invalidPackageNames) {
          expect(
            () => RuleImportValidator.validatePackageName(packageName),
            throwsA(predicate((e) =>
                e is RuleImportException &&
                e.code == 'INVALID_FIELD_VALUE' &&
                e.message == 'Invalid field value' &&
                (e.details as String).startsWith('Field packageName:'))),
          );
        }
      });
    });

    group('validateTags', () {
      test('应当通过有效的标签列表', () {
        const validTagsList = [
          ['tag1', 'tag2', 'tag3'],
          ['测试', '开发', '生产'],
          ['a'],
        ];

        for (final tags in validTagsList) {
          expect(
            () => RuleImportValidator.validateTags(tags),
            returnsNormally,
          );
        }
      });

      test('应当拒绝包含空标签', () {
        const invalidTagsList = [
          ['tag1', '', 'tag3'],
          ['', 'tag2'],
          [''],
        ];

        for (final tags in invalidTagsList) {
          expect(
            () => RuleImportValidator.validateTags(tags),
            throwsA(predicate((e) =>
                e is RuleImportException &&
                e.code == 'INVALID_FIELD_VALUE' &&
                e.message == 'Invalid field value' &&
                (e.details as String).startsWith('Field tags:'))),
          );
        }
      });

      test('应当拒绝超长标签', () {
        final longTag = 'a' * 51;
        expect(
          () => RuleImportValidator.validateTags([longTag]),
          throwsA(predicate((e) =>
              e is RuleImportException &&
              e.code == 'INVALID_FIELD_VALUE' &&
              e.message == 'Invalid field value' &&
              (e.details as String).startsWith('Field tags:'))),
        );
      });
    });

    group('validateOverlayStyle', () {
      test('应当通过有效的悬浮窗样式', () {
        final validStyle = OverlayStyle(
          text: '测试文本',
          fontSize: 14,
          backgroundColor: Colors.white,
          textColor: Colors.black,
          uiAutomatorCode: 'new UiSelector().text("测试")',
          padding: const EdgeInsets.all(8),
        );

        expect(
          () => RuleImportValidator.validateOverlayStyle(validStyle),
          returnsNormally,
        );
      });

      test('应当拒绝空文本', () {
        final invalidStyle = OverlayStyle(
          text: '',
          fontSize: 14,
          backgroundColor: Colors.white,
          textColor: Colors.black,
          uiAutomatorCode: 'new UiSelector().text("测试")',
        );

        expect(
          () => RuleImportValidator.validateOverlayStyle(invalidStyle),
          throwsA(predicate((e) =>
              e is RuleImportException &&
              e.code == 'INVALID_FIELD_VALUE' &&
              e.message == 'Invalid field value' &&
              (e.details as String).startsWith('Field text:'))),
        );
      });

      test('应当拒绝非正字体大小', () {
        final invalidStyle = OverlayStyle(
          text: '测试文本',
          fontSize: 0,
          backgroundColor: Colors.white,
          textColor: Colors.black,
          uiAutomatorCode: 'new UiSelector().text("测试")',
        );

        expect(
          () => RuleImportValidator.validateOverlayStyle(invalidStyle),
          throwsA(predicate((e) =>
              e is RuleImportException &&
              e.code == 'INVALID_FIELD_VALUE' &&
              e.message == 'Invalid field value' &&
              (e.details as String).startsWith('Field fontSize:'))),
        );

        final negativeStyle = invalidStyle.copyWith(fontSize: -1);
        expect(
          () => RuleImportValidator.validateOverlayStyle(negativeStyle),
          throwsA(predicate((e) =>
              e is RuleImportException &&
              e.code == 'INVALID_FIELD_VALUE' &&
              e.message == 'Invalid field value' &&
              (e.details as String).startsWith('Field fontSize:'))),
        );
      });

      test('应当拒绝空的UI Automator代码', () {
        final invalidStyle = OverlayStyle(
          text: '测试文本',
          fontSize: 14,
          backgroundColor: Colors.white,
          textColor: Colors.black,
          uiAutomatorCode: '',
        );

        expect(
          () => RuleImportValidator.validateOverlayStyle(invalidStyle),
          throwsA(predicate((e) =>
              e is RuleImportException &&
              e.code == 'INVALID_FIELD_VALUE' &&
              e.message == 'Invalid field value' &&
              (e.details as String).startsWith('Field uiAutomatorCode:'))),
        );
      });

      test('应当拒绝负数内边距', () {
        final invalidStyle = OverlayStyle(
          text: '测试文本',
          fontSize: 14,
          backgroundColor: Colors.white,
          textColor: Colors.black,
          uiAutomatorCode: 'new UiSelector().text("测试")',
          padding: const EdgeInsets.only(left: -1),
        );

        expect(
          () => RuleImportValidator.validateOverlayStyle(invalidStyle),
          throwsA(predicate((e) =>
              e is RuleImportException &&
              e.code == 'INVALID_FIELD_VALUE' &&
              e.message == 'Invalid field value' &&
              (e.details as String).startsWith('Field padding:'))),
        );

        // 测试其他方向的负数内边距
        final styles = [
          invalidStyle.copyWith(padding: const EdgeInsets.only(top: -1)),
          invalidStyle.copyWith(padding: const EdgeInsets.only(right: -1)),
          invalidStyle.copyWith(padding: const EdgeInsets.only(bottom: -1)),
        ];

        for (final style in styles) {
          expect(
            () => RuleImportValidator.validateOverlayStyle(style),
            throwsA(predicate((e) =>
                e is RuleImportException &&
                e.code == 'INVALID_FIELD_VALUE' &&
                e.message == 'Invalid field value' &&
                (e.details as String).startsWith('Field padding:'))),
          );
        }
      });

      test('应当拒绝完全透明的颜色', () {
        // 测试完全透明的背景色
        final transparentBgStyle = OverlayStyle(
          text: '测试文本',
          fontSize: 14,
          backgroundColor: Colors.transparent,
          textColor: Colors.black,
          uiAutomatorCode: 'new UiSelector().text("测试")',
        );

        expect(
          () => RuleImportValidator.validateOverlayStyle(transparentBgStyle),
          throwsA(predicate((e) =>
              e is RuleImportException &&
              e.code == 'INVALID_FIELD_VALUE' &&
              e.message == 'Invalid field value' &&
              (e.details as String).startsWith('Field backgroundColor:'))),
        );

        // 测试完全透明的文本色
        final transparentTextStyle = OverlayStyle(
          text: '测试文本',
          fontSize: 14,
          backgroundColor: Colors.white,
          textColor: Colors.transparent,
          uiAutomatorCode: 'new UiSelector().text("测试")',
        );

        expect(
          () => RuleImportValidator.validateOverlayStyle(transparentTextStyle),
          throwsA(predicate((e) =>
              e is RuleImportException &&
              e.code == 'INVALID_FIELD_VALUE' &&
              e.message == 'Invalid field value' &&
              (e.details as String).startsWith('Field textColor:'))),
        );
      });
    });
  });
}
