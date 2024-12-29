import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:awattackerapplier/utils/rule_field_validator.dart';
import 'package:awattackerapplier/models/overlay_style.dart';

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
        expect(result.errorMessage, equals('规则名称不能为空'));
      });

      test('应当拒绝超长的规则名称', () {
        final longName = 'a' * 51;
        final result = RuleFieldValidator.validateName(longName);
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('name'));
        expect(result.errorMessage, equals('规则名称不能超过50个字符'));
      });

      test('应当拒绝null规则名称', () {
        final result = RuleFieldValidator.validateName(null);
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('name'));
        expect(result.errorMessage, equals('规则名称不能为空'));
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
        expect(result.errorMessage, equals('包名不能为空'));
      });

      test('应当拒绝null包名', () {
        final result = RuleFieldValidator.validatePackageName(null);
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('packageName'));
        expect(result.errorMessage, equals('包名不能为空'));
      });
    });

    group('validateActivityName', () {
      test('应当通过有效的活动名', () {
        const validActivityNames = [
          '.MainActivity',
          '.ui.MainActivity',
          '.view.main.MainActivity',
        ];

        for (final activityName in validActivityNames) {
          final result = RuleFieldValidator.validateActivityName(activityName);
          expect(result.isValid, isTrue);
        }
      });

      test('应当拒绝不以点号开头的活动名', () {
        const invalidActivityNames = [
          'MainActivity',
          'ui.MainActivity',
          'view.main.MainActivity',
        ];

        for (final activityName in invalidActivityNames) {
          final result = RuleFieldValidator.validateActivityName(activityName);
          expect(result.isValid, isFalse);
          expect(result.fieldName, equals('activityName'));
          expect(result.errorMessage, equals('字段值无效'));
          expect(result.errorDetails, equals('字段 activityName: 活动名必须以点号(.)开头'));
        }
      });

      test('应当拒绝空活动名', () {
        final result = RuleFieldValidator.validateActivityName('');
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('activityName'));
        expect(result.errorMessage, equals('活动名不能为空'));
      });

      test('应当拒绝null活动名', () {
        final result = RuleFieldValidator.validateActivityName(null);
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('activityName'));
        expect(result.errorMessage, equals('活动名不能为空'));
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
        expect(result.errorMessage, equals('字段值无效'));
        expect(result.errorDetails, equals('字段 tags: 标签不能为空'));
      });

      test('应当拒绝超长标签', () {
        final longTag = 'a' * 51;
        final result = RuleFieldValidator.validateTag(longTag);
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('tags'));
        expect(result.errorMessage, equals('字段值无效'));
        expect(result.errorDetails, equals('字段 tags: 标签长度不能超过50个字符'));
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
          expect(result.errorMessage, equals('字段值无效'));
          expect(result.errorDetails, equals('字段 tags: 标签不能为空'));
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
        expect(result.errorMessage, equals('悬浮窗样式不能为空'));
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
        expect(result.errorMessage, equals('字段值无效'));
        expect(result.errorDetails, equals('字段 text: 文本不能为空'));
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
        expect(result.errorMessage, equals('字段值无效'));
        expect(result.errorDetails, equals('字段 fontSize: 字体大小必须大于0'));
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
        expect(result.errorMessage, equals('字段值无效'));
        expect(result.errorDetails, equals('字段 backgroundColor: 颜色不能完全透明'));
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
        expect(result.errorMessage, equals('字段值无效'));
        expect(result.errorDetails, equals('字段 testColor: 颜色不能完全透明'));
      });

      test('应当拒绝null颜色', () {
        final result = RuleFieldValidator.validateColor(null, 'testColor');
        expect(result.isValid, isFalse);
        expect(result.fieldName, equals('testColor'));
        expect(result.errorMessage, equals('颜色不能为空'));
      });
    });
  });
}
