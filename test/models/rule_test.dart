import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awattackerapplier/models/rule.dart';
import 'package:awattackerapplier/models/overlay_style.dart';

void main() {
  group('Rule', () {
    // 创建一个测试用的 OverlayStyle
    final testStyle = OverlayStyle(
      x: 10,
      y: 20,
      width: 100,
      height: 50,
      text: 'Test Style',
      fontSize: 16,
      backgroundColor: const Color(0xFF2196F3),
      textColor: const Color(0xFFFF0000),
      horizontalAlign: TextAlign.center,
      verticalAlign: TextAlign.center,
      uiAutomatorCode: 'test code',
      padding: const EdgeInsets.all(8),
    );

    test('使用必需参数创建实例', () {
      final rule = Rule(
        name: 'Test Rule',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
        isEnabled: true,
        overlayStyles: [testStyle],
      );

      expect(rule.name, equals('Test Rule'));
      expect(rule.packageName, equals('com.example.app'));
      expect(rule.activityName, equals('.MainActivity'));
      expect(rule.isEnabled, isTrue);
      expect(rule.overlayStyles.length, equals(1));
      expect(rule.overlayStyles.first, equals(testStyle));
      expect(rule.tags, isEmpty);
    });

    test('使用所有参数创建实例', () {
      final rule = Rule(
        name: 'Test Rule',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
        isEnabled: true,
        overlayStyles: [testStyle],
        tags: ['tag1', 'tag2'],
      );

      expect(rule.name, equals('Test Rule'));
      expect(rule.packageName, equals('com.example.app'));
      expect(rule.activityName, equals('.MainActivity'));
      expect(rule.isEnabled, isTrue);
      expect(rule.overlayStyles.length, equals(1));
      expect(rule.overlayStyles.first, equals(testStyle));
      expect(rule.tags, equals(['tag1', 'tag2']));
    });

    test('使用 copyWith 创建更新后的实例', () {
      final original = Rule(
        name: 'Test Rule',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
        isEnabled: true,
        overlayStyles: [testStyle],
        tags: ['tag1', 'tag2'],
      );

      final copied = original.copyWith(
        name: 'Updated Rule',
        isEnabled: false,
        tags: ['tag3'],
      );

      expect(copied.name, equals('Updated Rule'));
      expect(copied.packageName, equals(original.packageName));
      expect(copied.activityName, equals(original.activityName));
      expect(copied.isEnabled, isFalse);
      expect(copied.overlayStyles, equals(original.overlayStyles));
      expect(copied.tags, equals(['tag3']));
    });

    group('相等性和哈希值', () {
      test('内容相同的规则应该相等', () {
        final rule1 = Rule(
          name: 'Test Rule',
          packageName: 'com.example.app',
          activityName: '.MainActivity',
          isEnabled: true,
          overlayStyles: [testStyle],
          tags: ['tag1', 'tag2'],
        );

        final rule2 = Rule(
          name: 'Test Rule',
          packageName: 'com.example.app',
          activityName: '.MainActivity',
          isEnabled: true,
          overlayStyles: [testStyle],
          tags: ['tag1', 'tag2'],
        );

        expect(rule1, equals(rule2));
        expect(rule1.hashCode, equals(rule2.hashCode));
      });

      test('内容不同的规则不应该相等', () {
        final rule1 = Rule(
          name: 'Test Rule 1',
          packageName: 'com.example.app',
          activityName: '.MainActivity',
          isEnabled: true,
          overlayStyles: [testStyle],
        );

        final rule2 = Rule(
          name: 'Test Rule 2',
          packageName: 'com.example.app',
          activityName: '.MainActivity',
          isEnabled: true,
          overlayStyles: [testStyle],
        );

        expect(rule1, isNot(equals(rule2)));
        expect(rule1.hashCode, isNot(equals(rule2.hashCode)));
      });

      test('启用状态不同的规则不应该相等', () {
        final rule1 = Rule(
          name: 'Test Rule',
          packageName: 'com.example.app',
          activityName: '.MainActivity',
          isEnabled: true,
          overlayStyles: [testStyle],
        );

        final rule2 = Rule(
          name: 'Test Rule',
          packageName: 'com.example.app',
          activityName: '.MainActivity',
          isEnabled: false,
          overlayStyles: [testStyle],
        );

        expect(rule1, isNot(equals(rule2)));
        expect(rule1.hashCode, isNot(equals(rule2.hashCode)));
      });

      test('标签顺序不同但内容相同的规则应该相等', () {
        final rule1 = Rule(
          name: 'Test Rule',
          packageName: 'com.example.app',
          activityName: '.MainActivity',
          isEnabled: true,
          overlayStyles: [testStyle],
          tags: ['tag1', 'tag2'],
        );

        final rule2 = Rule(
          name: 'Test Rule',
          packageName: 'com.example.app',
          activityName: '.MainActivity',
          isEnabled: true,
          overlayStyles: [testStyle],
          tags: ['tag2', 'tag1'],
        );

        expect(rule1, equals(rule2));
        expect(rule1.hashCode, equals(rule2.hashCode));
      });
    });

    group('JSON 序列化', () {
      test('toJson 正确转换所有属性', () {
        final rule = Rule(
          name: 'Test Rule',
          packageName: 'com.example.app',
          activityName: '.MainActivity',
          isEnabled: true,
          overlayStyles: [testStyle],
          tags: ['tag1', 'tag2'],
        );

        final json = rule.toJson();

        expect(json['name'], equals('Test Rule'));
        expect(json['packageName'], equals('com.example.app'));
        expect(json['activityName'], equals('.MainActivity'));
        expect(json['isEnabled'], isTrue);
        expect(json['overlayStyles'], isList);
        expect(json['overlayStyles'].length, equals(1));
        expect(json['tags'], equals(['tag1', 'tag2']));

        // 验证 overlayStyle 的序列化
        final styleJson = json['overlayStyles'][0];
        expect(styleJson['text'], equals('Test Style'));
        expect(styleJson['fontSize'], equals(16));
        expect(styleJson['horizontalAlign'], equals('center'));
        expect(styleJson['verticalAlign'], equals('center'));
      });

      test('fromJson 创建包含正确值的实例', () {
        final json = {
          'name': 'Test Rule',
          'packageName': 'com.example.app',
          'activityName': '.MainActivity',
          'isEnabled': true,
          'overlayStyles': [
            {
              'x': 10.0,
              'y': 20.0,
              'width': 100.0,
              'height': 50.0,
              'text': 'Test Style',
              'fontSize': 16.0,
              'backgroundColor': 0xFF2196F3,
              'textColor': 0xFFFF0000,
              'horizontalAlign': 'center',
              'verticalAlign': 'center',
              'uiAutomatorCode': 'test code',
              'padding': {
                'left': 8.0,
                'top': 8.0,
                'right': 8.0,
                'bottom': 8.0,
              },
            }
          ],
          'tags': ['tag1', 'tag2'],
        };

        final rule = Rule.fromJson(json);

        expect(rule.name, equals('Test Rule'));
        expect(rule.packageName, equals('com.example.app'));
        expect(rule.activityName, equals('.MainActivity'));
        expect(rule.isEnabled, isTrue);
        expect(rule.overlayStyles.length, equals(1));
        expect(rule.tags, equals(['tag1', 'tag2']));

        // 验证 overlayStyle 的反序列化
        final style = rule.overlayStyles.first;
        expect(style.text, equals('Test Style'));
        expect(style.fontSize, equals(16));
        expect(style.horizontalAlign, equals(TextAlign.center));
        expect(style.verticalAlign, equals(TextAlign.center));
      });

      test('fromJson 处理缺失的标签', () {
        final json = {
          'name': 'Test Rule',
          'packageName': 'com.example.app',
          'activityName': '.MainActivity',
          'isEnabled': true,
          'overlayStyles': [],
        };

        final rule = Rule.fromJson(json);
        expect(rule.tags, isEmpty);
      });
    });
  });
}
