import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:awattackerapplier/exceptions/rule_import_exception.dart';
import 'package:awattackerapplier/models/overlay_style.dart';
import 'package:awattackerapplier/models/rule.dart';
import 'package:awattackerapplier/models/rule_import.dart';

void main() {
  group('RuleImport', () {
    group('RuleImportResult', () {
      test('success 工厂方法应当创建成功的导入结果', () {
        final result = RuleImportResult.success(5);

        expect(result.totalCount, equals(5));
        expect(result.successCount, equals(5));
        expect(result.failureCount, equals(0));
        expect(result.errors, isEmpty);
        expect(result.hasErrors, isFalse);
      });

      test('failure 工厂方法应当创建失败的导入结果', () {
        final result = RuleImportResult.failure('测试错误');

        expect(result.totalCount, equals(1));
        expect(result.successCount, equals(0));
        expect(result.failureCount, equals(1));
        expect(result.errors, equals(['测试错误']));
        expect(result.hasErrors, isTrue);
      });

      test('partial 工厂方法应当创建部分成功的导入结果', () {
        final result = RuleImportResult.partial(3, 2, ['错误1', '错误2']);

        expect(result.totalCount, equals(5));
        expect(result.successCount, equals(3));
        expect(result.failureCount, equals(2));
        expect(result.errors, equals(['错误1', '错误2']));
        expect(result.hasErrors, isTrue);
      });

      test('hasErrors 应当正确反映错误状态', () {
        expect(RuleImportResult.success(1).hasErrors, isFalse);
        expect(RuleImportResult.failure('错误').hasErrors, isTrue);
        expect(RuleImportResult.partial(1, 1, ['错误']).hasErrors, isTrue);
      });
    });

    group('RuleImport 异常处理', () {
      test('fromJson 应当正确处理无效的规则格式 - 缺少必需字段', () {
        final jsonStr = '''
        {
          "version": "1.0",
          "rules": [
            {
              "name": "测试规则",
              "isEnabled": true
            }
          ]
        }
        ''';

        expect(
          () => RuleImport.fromJson(jsonStr),
          throwsA(predicate((e) =>
              e is RuleImportException &&
              e.code == 'RULE_PARSE_ERROR' &&
              e.message == 'Parse rule failed' &&
              (e.details as String).contains('Rule index: 0'))),
        );
      });

      test('fromJson 应当正确处理无效的规则格式 - 无效的包名格式', () {
        final jsonStr = '''
        {
          "version": "1.0",
          "rules": [
            {
              "name": "测试规则",
              "packageName": "invalid-package-name",
              "activityName": ".MainActivity",
              "isEnabled": true,
              "overlayStyles": [
                {
                  "text": "测试文本",
                  "fontSize": 14
                }
              ]
            }
          ]
        }
        ''';

        expect(
          () => RuleImport.fromJson(jsonStr),
          throwsA(predicate((e) =>
              e is RuleImportException &&
              e.code == 'RULE_PARSE_ERROR' &&
              e.message == 'Parse rule failed' &&
              (e.details as String).contains('Rule index: 0'))),
        );
      });

      test('fromJson 应当正确处理无效的样式格式 - 空文本', () {
        final jsonStr = '''
        {
          "version": "1.0",
          "rules": [
            {
              "name": "测试规则",
              "packageName": "com.example.app",
              "activityName": ".MainActivity",
              "isEnabled": true,
              "overlayStyles": [
                {
                  "text": "",
                  "fontSize": 14
                }
              ]
            }
          ]
        }
        ''';

        expect(
          () => RuleImport.fromJson(jsonStr),
          throwsA(predicate((e) =>
              e is RuleImportException &&
              e.code == 'RULE_PARSE_ERROR' &&
              e.message == 'Parse rule failed' &&
              (e.details as String)
                  .contains('Style 1 text: Invalid field value'))),
        );
      });

      test('fromJson 应当正确处理无效的样式格式 - 非正字体大小', () {
        final jsonStr = '''
        {
          "version": "1.0",
          "rules": [
            {
              "name": "测试规则",
              "packageName": "com.example.app",
              "activityName": ".MainActivity",
              "isEnabled": true,
              "overlayStyles": [
                {
                  "text": "测试文本",
                  "fontSize": -1
                }
              ]
            }
          ]
        }
        ''';

        expect(
          () => RuleImport.fromJson(jsonStr),
          throwsA(predicate((e) =>
              e is RuleImportException &&
              e.code == 'RULE_PARSE_ERROR' &&
              e.message == 'Parse rule failed' &&
              (e.details as String)
                  .contains('Style 1 fontSize: Invalid field value'))),
        );
      });

      test('fromJson 应当正确处理无效的JSON格式', () {
        final invalidJsonList = [
          '{version: 1.0}', // 无效的JSON语法
          '{"version": null, "rules": []}', // 无效的版本值
          '{"version": "1.0", "rules": null}', // 无效的规则列表
          '{"version": "1.0", "rules": "not-a-list"}', // 规则列表类型错误
        ];

        for (final jsonStr in invalidJsonList) {
          expect(
            () => RuleImport.fromJson(jsonStr),
            throwsA(predicate((e) => e is RuleImportException)),
            reason: 'Failed to handle invalid JSON: $jsonStr',
          );
        }
      });
    });

    test('fromJson 应当正确解析有效的JSON字符串', () {
      final jsonStr = '''
      {
        "version": "1.0",
        "rules": [
          {
            "name": "测试规则",
            "packageName": "com.example.app",
            "activityName": ".MainActivity",
            "isEnabled": true,
            "overlayStyles": [
              {
                "text": "测试文本",
                "fontSize": 14,
                "backgroundColor": 4294967295,
                "textColor": 4278190080,
                "horizontalAlign": "center",
                "verticalAlign": "center",
                "uiAutomatorCode": "new UiSelector().text(\\"测试\\")",
                "padding": {
                  "left": 8,
                  "top": 8,
                  "right": 8,
                  "bottom": 8
                }
              }
            ],
            "tags": ["测试", "示例"]
          }
        ]
      }
      ''';

      final ruleImport = RuleImport.fromJson(jsonStr);
      expect(ruleImport.version, equals('1.0'));
      expect(ruleImport.rules.length, equals(1));

      final rule = ruleImport.rules.first;
      expect(rule.name, equals('测试规则'));
      expect(rule.packageName, equals('com.example.app'));
      expect(rule.activityName, equals('.MainActivity'));
      expect(rule.isEnabled, isTrue);
      expect(rule.tags, equals(['测试', '示例']));
      expect(rule.overlayStyles.length, equals(1));

      final style = rule.overlayStyles.first;
      expect(style.text, equals('测试文本'));
      expect(style.fontSize, equals(14));
      expect(style.uiAutomatorCode, equals('new UiSelector().text("测试")'));
    });

    test('fromJson 应当拒绝空的JSON字符串', () {
      expect(
        () => RuleImport.fromJson(''),
        throwsA(predicate((e) =>
            e is RuleImportException &&
            e.code == 'EMPTY_FILE' &&
            e.message == 'Import file is empty')),
      );
    });

    test('fromJson 应当拒绝缺少版本号', () {
      const jsonStr = '''
      {
        "rules": []
      }
      ''';

      expect(
        () => RuleImport.fromJson(jsonStr),
        throwsA(predicate((e) =>
            e is RuleImportException &&
            e.code == 'MISSING_FIELD' &&
            e.message == 'Missing required field')),
      );
    });

    test('fromJson 应当拒绝不兼容的版本号', () {
      const jsonStr = '''
      {
        "version": "2.0",
        "rules": []
      }
      ''';

      expect(
        () => RuleImport.fromJson(jsonStr),
        throwsA(predicate((e) =>
            e is RuleImportException &&
            e.code == 'INCOMPATIBLE_VERSION' &&
            e.message == 'Incompatible version')),
      );
    });

    test('fromJson 应当拒绝缺少规则列表', () {
      const jsonStr = '''
      {
        "version": "1.0"
      }
      ''';

      expect(
        () => RuleImport.fromJson(jsonStr),
        throwsA(predicate((e) =>
            e is RuleImportException &&
            e.code == 'MISSING_FIELD' &&
            e.message == 'Missing required field')),
      );
    });

    test('fromJson 应当拒绝空的规则列表', () {
      const jsonStr = '''
      {
        "version": "1.0",
        "rules": []
      }
      ''';

      expect(
        () => RuleImport.fromJson(jsonStr),
        throwsA(predicate((e) =>
            e is RuleImportException &&
            e.code == 'NO_RULES' &&
            e.message == 'Import file does not contain any rules')),
      );
    });

    test('toJson 应当正确序列化规则', () {
      final style = OverlayStyle(
        text: '测试文本',
        fontSize: 14,
        backgroundColor: const Color(0xFFFFFFFF),
        textColor: const Color(0xFF000000),
        uiAutomatorCode: 'new UiSelector().text("测试")',
        padding: const EdgeInsets.all(8),
      );

      final rule = Rule(
        name: '测试规则',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
        isEnabled: true,
        overlayStyles: [style],
        tags: ['测试', '示例'],
      );

      final ruleImport = RuleImport(
        version: RuleImport.currentVersion,
        rules: [rule],
      );

      final jsonStr = ruleImport.toJson();
      final decoded = RuleImport.fromJson(jsonStr);

      expect(decoded.version, equals(ruleImport.version));
      expect(decoded.rules.length, equals(ruleImport.rules.length));

      final decodedRule = decoded.rules.first;
      expect(decodedRule.name, equals(rule.name));
      expect(decodedRule.packageName, equals(rule.packageName));
      expect(decodedRule.activityName, equals(rule.activityName));
      expect(decodedRule.isEnabled, equals(rule.isEnabled));
      expect(decodedRule.tags, equals(rule.tags));
      expect(
          decodedRule.overlayStyles.length, equals(rule.overlayStyles.length));

      final decodedStyle = decodedRule.overlayStyles.first;
      expect(decodedStyle.text, equals(style.text));
      expect(decodedStyle.fontSize, equals(style.fontSize));
      expect(decodedStyle.uiAutomatorCode, equals(style.uiAutomatorCode));
    });
  });
}
