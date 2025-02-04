import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:awattackerapplier/models/overlay_style.dart';
import 'package:awattackerapplier/utils/rule_field_validator.dart';

void main() {
  group('RuleFieldValidator', () {
    group('validateName', () {
      test('应当通过有效的规则名称', () {
        const validNames = [
          '测试规则',
          'Test Rule',
          '规则1',
        ];

        for (final name in validNames) {
          final result = RuleFieldValidator.validateName(name);
          expect(result.isValid, isTrue);
        }
      });

      test('应当拒绝空的规则名称', () {
        final result = RuleFieldValidator.validateName('');
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('name'));
        expect(result.errorMessage, equals('Rule name cannot be empty'));
      });

      test('应当拒绝超长的规则名称', () {
        final longName = 'a' * 51;
        final result = RuleFieldValidator.validateName(longName);
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('name'));
        expect(result.errorMessage,
            equals('Rule name cannot exceed 50 characters'));
      });

      test('应当拒绝null规则名称', () {
        final result = RuleFieldValidator.validateName(null);
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('name'));
        expect(result.errorMessage, equals('Rule name cannot be empty'));
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
          final result = RuleFieldValidator.validatePackageName(packageName);
          expect(result.isValid, isTrue);
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
          final result = RuleFieldValidator.validatePackageName(packageName);
          expect(result.isValid, isFalse);
          expect(result.fieldName, equals('packageName'));
          expect(result.errorCode, equals('INVALID_FIELD_VALUE'));
        }
      });

      test('应当拒绝空包名', () {
        final result = RuleFieldValidator.validatePackageName('');
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('packageName'));
        expect(result.errorMessage, equals('Package name cannot be empty'));
      });

      test('应当拒绝null包名', () {
        final result = RuleFieldValidator.validatePackageName(null);
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('packageName'));
        expect(result.errorMessage, equals('Package name cannot be empty'));
      });
    });

    group('validateActivityName', () {
      test('应当通过有效的活动名', () {
        const validActivityNames = [
          '.MainActivity',
          '.ui.MainActivity',
          '.view.main.MainActivity',
          'MainActivity',
          'com.example.MainActivity',
          'com.example.ui.MainActivity',
        ];

        for (final activityName in validActivityNames) {
          final result = RuleFieldValidator.validateActivityName(activityName);
          expect(result.isValid, isTrue);
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
          final result = RuleFieldValidator.validateActivityName(activityName);
          expect(result.isValid, isFalse);
          expect(result.fieldName, equals('activityName'));
          expect(result.errorMessage, equals('Invalid field value'));
        }
      });

      test('应当拒绝空活动名', () {
        final result = RuleFieldValidator.validateActivityName('');
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('activityName'));
        expect(result.errorMessage, equals('Activity name cannot be empty'));
      });

      test('应当拒绝null活动名', () {
        final result = RuleFieldValidator.validateActivityName(null);
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('activityName'));
        expect(result.errorMessage, equals('Activity name cannot be empty'));
      });
    });

    group('validateTag', () {
      test('应当通过有效的标签', () {
        const validTags = [
          'tag1',
          '测试',
          'development',
        ];

        for (final tag in validTags) {
          final result = RuleFieldValidator.validateTag(tag);
          expect(result.isValid, isTrue);
        }
      });

      test('应当拒绝空标签', () {
        final result = RuleFieldValidator.validateTag('');
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('tags'));
        expect(result.errorMessage, equals('Invalid field value'));
        expect(result.errorDetails, equals('Field tags: Tag cannot be empty'));
      });

      test('应当拒绝超长标签', () {
        final longTag = 'a' * 51;
        final result = RuleFieldValidator.validateTag(longTag);
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('tags'));
        expect(result.errorMessage, equals('Invalid field value'));
        expect(result.errorDetails,
            equals('Field tags: Tag length cannot exceed 50 characters'));
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
          final result = RuleFieldValidator.validateTags(tags);
          expect(result.isValid, isTrue);
        }
      });

      test('应当通过空列表', () {
        final result = RuleFieldValidator.validateTags([]);
        expect(result.isValid, isTrue);
      });

      test('应当通过null标签列表', () {
        final result = RuleFieldValidator.validateTags(null);
        expect(result.isValid, isTrue);
      });

      test('应当拒绝包含空标签的列表', () {
        const invalidTagsList = [
          ['tag1', '', 'tag3'],
          ['', 'tag2'],
          [''],
        ];

        for (final tags in invalidTagsList) {
          final result = RuleFieldValidator.validateTags(tags);
          expect(result.isValid, isFalse);
          expect(result.fieldName, equals('tags'));
          expect(result.errorMessage, equals('Invalid field value'));
          expect(
              result.errorDetails, equals('Field tags: Tag cannot be empty'));
        }
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

        final result = RuleFieldValidator.validateOverlayStyle(validStyle);
        expect(result.isValid, isTrue);
      });

      test('应当拒绝null样式', () {
        final result = RuleFieldValidator.validateOverlayStyle(null);
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('overlayStyle'));
        expect(result.errorMessage, equals('Overlay style cannot be empty'));
      });

      test('应当拒绝空文本', () {
        final invalidStyle = OverlayStyle(
          text: '',
          fontSize: 14,
          backgroundColor: Colors.white,
          textColor: Colors.black,
          uiAutomatorCode: 'new UiSelector().text("测试")',
        );

        final result = RuleFieldValidator.validateOverlayStyle(invalidStyle);
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('text'));
        expect(result.errorMessage, equals('Invalid field value'));
        expect(result.errorDetails, equals('Field text: Text cannot be empty'));
      });

      test('应当拒绝非正字体大小', () {
        final invalidStyle = OverlayStyle(
          text: '测试文本',
          fontSize: 0,
          backgroundColor: Colors.white,
          textColor: Colors.black,
          uiAutomatorCode: 'new UiSelector().text("测试")',
        );

        final result = RuleFieldValidator.validateOverlayStyle(invalidStyle);
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('fontSize'));
        expect(result.errorMessage, equals('Invalid field value'));
        expect(result.errorDetails,
            equals('Field fontSize: Font size must be greater than 0'));
      });

      test('应当拒绝完全透明的颜色', () {
        final transparentStyle = OverlayStyle(
          text: '测试文本',
          fontSize: 14,
          backgroundColor: Colors.transparent,
          textColor: Colors.black,
          uiAutomatorCode: 'new UiSelector().text("测试")',
        );

        final result =
            RuleFieldValidator.validateOverlayStyle(transparentStyle);
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('backgroundColor'));
        expect(result.errorMessage, equals('Invalid field value'));
        expect(result.errorDetails,
            equals('Field backgroundColor: Color cannot be fully transparent'));
      });
    });

    group('validateColor', () {
      test('应当通过不透明的颜色', () {
        const validColors = [
          Colors.black,
          Colors.white,
          Colors.red,
        ];

        for (final color in validColors) {
          final result = RuleFieldValidator.validateColor(color, 'testColor');
          expect(result.isValid, isTrue);
        }
      });

      test('应当拒绝完全透明的颜色', () {
        final result = RuleFieldValidator.validateColor(
          Colors.transparent,
          'testColor',
        );
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('testColor'));
        expect(result.errorMessage, equals('Invalid field value'));
        expect(result.errorDetails,
            equals('Field testColor: Color cannot be fully transparent'));
      });

      test('应当拒绝null颜色', () {
        final result = RuleFieldValidator.validateColor(null, 'testColor');
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('testColor'));
        expect(result.errorMessage, equals('Color cannot be empty'));
      });
    });
  });
}
