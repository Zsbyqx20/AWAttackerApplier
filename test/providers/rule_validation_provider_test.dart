import 'package:flutter_test/flutter_test.dart';
import 'package:awattackerapplier/providers/rule_validation_provider.dart';
import 'package:awattackerapplier/models/rule.dart';
import 'package:awattackerapplier/models/overlay_style.dart';
import 'package:flutter/material.dart';

void main() {
  group('RuleValidationProvider', () {
    late RuleValidationProvider provider;

    setUp(() {
      provider = RuleValidationProvider();
    });

    test('初始状态应该是有效的且没有验证结果', () {
      expect(provider.state.isValid, isTrue);
      expect(provider.state.fieldResults, isEmpty);
    });

    group('单个字段验证', () {
      test('验证有效的名称', () {
        provider.validateField('name', 'ValidName');

        expect(provider.state.isValid, isTrue);
        expect(provider.isFieldValid('name'), isTrue);
        expect(provider.getFieldError('name'), isNull);
      });

      test('验证无效的名称', () {
        provider.validateField('name', '');

        expect(provider.state.isValid, isFalse);
        expect(provider.isFieldValid('name'), isFalse);
        expect(provider.getFieldError('name'), isNotNull);
      });

      test('验证有效的包名', () {
        provider.validateField('packageName', 'com.example.app');

        expect(provider.state.isValid, isTrue);
        expect(provider.isFieldValid('packageName'), isTrue);
        expect(provider.getFieldError('packageName'), isNull);
      });

      test('验证无效的包名', () {
        provider.validateField('packageName', '');

        expect(provider.state.isValid, isFalse);
        expect(provider.isFieldValid('packageName'), isFalse);
        expect(provider.getFieldError('packageName'), isNotNull);
      });

      test('验证有效的活动名', () {
        provider.validateField('activityName', '.MainActivity');

        expect(provider.state.isValid, isTrue);
        expect(provider.isFieldValid('activityName'), isTrue);
        expect(provider.getFieldError('activityName'), isNull);
      });

      test('验证无效的活动名', () {
        provider.validateField('activityName', 'MainActivity');

        expect(provider.state.isValid, isFalse);
        expect(provider.isFieldValid('activityName'), isFalse);
        expect(provider.getFieldError('activityName'), isNotNull);
      });

      test('验证有效的标签列表', () {
        provider.validateField('tags', <String>['tag1', 'tag2']);

        expect(provider.state.isValid, isTrue);
        expect(provider.isFieldValid('tags'), isTrue);
        expect(provider.getFieldError('tags'), isNull);
      });

      test('验证无效的标签列表', () {
        provider.validateField('tags', <String>['']);

        expect(provider.state.isValid, isFalse);
        expect(provider.isFieldValid('tags'), isFalse);
        expect(provider.getFieldError('tags'), isNotNull);
      });

      test('验证有效的悬浮窗样式', () {
        final style = OverlayStyle(
          x: 0,
          y: 0,
          width: 100,
          height: 50,
          text: 'Test',
          fontSize: 14,
          backgroundColor: Colors.white,
          textColor: Colors.black,
          horizontalAlign: TextAlign.left,
          verticalAlign: TextAlign.center,
          padding: const EdgeInsets.all(8),
          uiAutomatorCode: 'new UiSelector().text("Test")',
        );

        provider.validateField('overlayStyle', style);

        expect(provider.state.isValid, isTrue);
        expect(provider.isFieldValid('overlayStyle'), isTrue);
        expect(provider.getFieldError('overlayStyle'), isNull);
      });

      test('验证无效的悬浮窗样式', () {
        provider.validateField('overlayStyle', null);

        expect(provider.state.isValid, isFalse);
        expect(provider.isFieldValid('overlayStyle'), isFalse);
        expect(provider.getFieldError('overlayStyle'), isNotNull);
      });

      test('验证未知字段', () {
        provider.validateField('unknownField', 'value');

        expect(provider.state.isValid, isFalse);
        expect(provider.isFieldValid('unknownField'), isFalse);
        expect(provider.getFieldError('unknownField'), equals('未知字段'));
      });
    });

    group('验证结果的清除', () {
      setUp(() {
        provider.validateField('name', '');
        provider.validateField('packageName', '');
      });

      test('清除单个字段的验证结果', () {
        expect(provider.state.fieldResults.length, equals(2));

        provider.clearFieldValidation('name');

        expect(provider.state.fieldResults.length, equals(1));
        expect(provider.getFieldValidation('name'), isNull);
        expect(provider.getFieldValidation('packageName'), isNotNull);
      });

      test('清除所有验证结果', () {
        expect(provider.state.fieldResults.length, equals(2));

        provider.clearAllValidations();

        expect(provider.state.fieldResults, isEmpty);
        expect(provider.state.isValid, isTrue);
      });
    });

    group('整个规则的验证', () {
      test('验证有效的规则', () {
        final rule = Rule(
          name: 'ValidName',
          packageName: 'com.example.app',
          activityName: '.MainActivity',
          isEnabled: true,
          overlayStyles: [
            OverlayStyle(
              x: 0,
              y: 0,
              width: 100,
              height: 50,
              text: 'Test',
              fontSize: 14,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              horizontalAlign: TextAlign.left,
              verticalAlign: TextAlign.center,
              padding: const EdgeInsets.all(8),
              uiAutomatorCode: 'new UiSelector().text("Test")',
            ),
          ],
          tags: <String>['tag1', 'tag2'],
        );

        provider.validateRule(rule);

        expect(provider.state.isValid, isTrue);
        expect(provider.isFieldValid('name'), isTrue);
        expect(provider.isFieldValid('packageName'), isTrue);
        expect(provider.isFieldValid('activityName'), isTrue);
        expect(provider.isFieldValid('tags'), isTrue);
        expect(provider.isFieldValid('overlayStyle'), isTrue);
      });

      test('验证无效的规则', () {
        final rule = Rule(
          name: '', // 无效的名称
          packageName: '', // 无效的包名
          activityName: 'MainActivity', // 无效的活动名（没有以点号开头）
          isEnabled: true,
          overlayStyles: [], // 无效的悬浮窗样式列表
          tags: <String>[''], // 无效的标签列表（包含空字符串）
        );

        provider.validateRule(rule);

        expect(provider.state.isValid, isFalse);
        expect(provider.isFieldValid('name'), isFalse);
        expect(provider.isFieldValid('packageName'), isFalse);
        expect(provider.isFieldValid('activityName'), isFalse);
        expect(provider.isFieldValid('tags'), isFalse);
      });
    });

    group('字段验证状态查询', () {
      setUp(() {
        provider.validateField('name', '');
        provider.validateField('packageName', 'com.example.app');
      });

      test('获取字段验证结果', () {
        final nameResult = provider.getFieldValidation('name');
        final packageResult = provider.getFieldValidation('packageName');
        final unknownResult = provider.getFieldValidation('unknown');

        expect(nameResult?.isValid, isFalse);
        expect(packageResult?.isValid, isTrue);
        expect(unknownResult, isNull);
      });

      test('检查字段是否有效', () {
        expect(provider.isFieldValid('name'), isFalse);
        expect(provider.isFieldValid('packageName'), isTrue);
        expect(provider.isFieldValid('unknown'), isTrue); // 未验证的字段默认为有效
      });

      test('获取字段错误信息', () {
        expect(provider.getFieldError('name'), isNotNull);
        expect(provider.getFieldError('packageName'), isNull);
        expect(provider.getFieldError('unknown'), isNull);
      });
    });
  });
}
