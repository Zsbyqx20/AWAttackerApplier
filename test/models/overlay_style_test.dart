import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awattackerapplier/models/overlay_style.dart';
import 'package:awattackerapplier/exceptions/rule_import_exception.dart';

void main() {
  group('OverlayStyle', () {
    // 定义具体的颜色值
    final testBlue = const Color(0xFF2196F3); // Colors.blue 的具体颜色值
    final testRed = const Color(0xFFFF0000); // 纯红色

    test('default constructor creates instance with default values', () {
      final style = OverlayStyle();
      expect(style.x, equals(0));
      expect(style.y, equals(0));
      expect(style.width, equals(0));
      expect(style.height, equals(0));
      expect(style.text, equals(''));
      expect(style.fontSize, equals(14));
      expect(style.backgroundColor, equals(Colors.white));
      expect(style.textColor, equals(Colors.black));
      expect(style.horizontalAlign, equals(TextAlign.left));
      expect(style.verticalAlign, equals(TextAlign.center));
      expect(style.uiAutomatorCode, equals(''));
      expect(style.padding, equals(const EdgeInsets.all(0)));
    });

    test('defaultStyle factory creates instance with default values', () {
      final style = OverlayStyle.defaultStyle();
      expect(style.x, equals(0));
      expect(style.y, equals(0));
      expect(style.width, equals(0));
      expect(style.height, equals(0));
      expect(style.text, equals(''));
      expect(style.fontSize, equals(14));
      expect(style.backgroundColor, equals(Colors.white));
      expect(style.textColor, equals(Colors.black));
      expect(style.horizontalAlign, equals(TextAlign.left));
      expect(style.verticalAlign, equals(TextAlign.center));
      expect(style.uiAutomatorCode, equals(''));
      expect(style.padding, equals(const EdgeInsets.all(0)));
    });

    test('copyWith creates new instance with updated values', () {
      final original = OverlayStyle(
        x: 10,
        y: 20,
        width: 100,
        height: 50,
        text: 'Original',
        fontSize: 16,
        backgroundColor: testBlue,
        textColor: Colors.white,
        horizontalAlign: TextAlign.center,
        verticalAlign: TextAlign.center,
        uiAutomatorCode: 'test code',
        padding: const EdgeInsets.all(8),
      );

      final copied = original.copyWith(
        text: 'Updated',
        fontSize: 18,
        backgroundColor: testRed,
      );

      expect(copied.x, equals(original.x));
      expect(copied.y, equals(original.y));
      expect(copied.width, equals(original.width));
      expect(copied.height, equals(original.height));
      expect(copied.text, equals('Updated'));
      expect(copied.fontSize, equals(18));
      expect(copied.backgroundColor, equals(testRed));
      expect(copied.textColor, equals(original.textColor));
      expect(copied.horizontalAlign, equals(original.horizontalAlign));
      expect(copied.verticalAlign, equals(original.verticalAlign));
      expect(copied.uiAutomatorCode, equals(original.uiAutomatorCode));
      expect(copied.padding, equals(original.padding));
    });

    group('JSON serialization', () {
      test('toJson converts all properties correctly', () {
        final style = OverlayStyle(
          x: 10,
          y: 20,
          width: 100,
          height: 50,
          text: 'Test',
          fontSize: 16,
          backgroundColor: testBlue,
          textColor: testRed,
          horizontalAlign: TextAlign.center,
          verticalAlign: TextAlign.center,
          uiAutomatorCode: 'test code',
          padding: const EdgeInsets.fromLTRB(1, 2, 3, 4),
        );

        final json = style.toJson();

        expect(json['x'], equals(10));
        expect(json['y'], equals(20));
        expect(json['width'], equals(100));
        expect(json['height'], equals(50));
        expect(json['text'], equals('Test'));
        expect(json['fontSize'], equals(16));
        expect(json['horizontalAlign'], equals('center'));
        expect(json['verticalAlign'], equals('center'));
        expect(json['uiAutomatorCode'], equals('test code'));
        expect(
            json['padding'],
            equals({
              'left': 1.0,
              'top': 2.0,
              'right': 3.0,
              'bottom': 4.0,
            }));
        expect(json['backgroundColor'], equals(0xFF2196F3));
        expect(json['textColor'], equals(0xFFFF0000));
      });

      test('fromJson creates instance with correct values', () {
        final json = {
          'x': 10.0,
          'y': 20.0,
          'width': 100.0,
          'height': 50.0,
          'text': 'Test',
          'fontSize': 16.0,
          'backgroundColor': 0xFF2196F3,
          'textColor': 0xFFFF0000,
          'horizontalAlign': 'center',
          'verticalAlign': 'center',
          'uiAutomatorCode': 'test code',
          'padding': {
            'left': 1.0,
            'top': 2.0,
            'right': 3.0,
            'bottom': 4.0,
          },
        };

        final style = OverlayStyle.fromJson(json);

        expect(style.x, equals(10));
        expect(style.y, equals(20));
        expect(style.width, equals(100));
        expect(style.height, equals(50));
        expect(style.text, equals('Test'));
        expect(style.fontSize, equals(16));
        expect(style.backgroundColor, equals(testBlue));
        expect(style.textColor, equals(testRed));
        expect(style.horizontalAlign, equals(TextAlign.center));
        expect(style.verticalAlign, equals(TextAlign.center));
        expect(style.uiAutomatorCode, equals('test code'));
        expect(style.padding, equals(const EdgeInsets.fromLTRB(1, 2, 3, 4)));
      });

      test('fromJson throws exception for missing required fields', () {
        expect(
          () => OverlayStyle.fromJson({}),
          throwsA(isA<RuleImportException>()
              .having((e) => e.code, 'code', equals('MISSING_FIELD'))
              .having((e) => e.message, 'message', equals('缺少必需字段'))),
        );
      });

      test('fromJson handles hex color strings', () {
        final json = {
          'text': 'Test',
          'fontSize': 16.0,
          'backgroundColor': '#FF2196F3',
          'textColor': '#FFFF0000',
        };

        final style = OverlayStyle.fromJson(json);
        expect(style.backgroundColor, equals(testBlue));
        expect(style.textColor, equals(testRed));
      });

      test('fromJson throws exception for invalid color format', () {
        final json = {
          'text': 'Test',
          'fontSize': 16.0,
          'backgroundColor': 'invalid',
        };

        expect(
          () => OverlayStyle.fromJson(json),
          throwsA(isA<RuleImportException>()
              .having((e) => e.code, 'code', equals('INVALID_FIELD_VALUE'))
              .having((e) => e.message, 'message', equals('字段值无效'))),
        );
      });
    });

    group('validation', () {
      test('isValid returns true for valid style', () {
        final style = OverlayStyle(
          width: 100,
          height: 50,
          text: 'Test',
          fontSize: 16,
        );
        expect(style.isValid(), isTrue);
      });

      test('isValid returns false for invalid style', () {
        final style = OverlayStyle(
          width: -1,
          height: 50,
          text: '',
          fontSize: 0,
        );
        expect(style.isValid(), isFalse);
      });

      test('getValidationError returns correct error messages', () {
        final style = OverlayStyle(width: -1);
        expect(style.getValidationError(), equals('宽度不能为负数'));

        final style2 = OverlayStyle(height: -1);
        expect(style2.getValidationError(), equals('高度不能为负数'));

        final style3 = OverlayStyle(fontSize: 0);
        expect(style3.getValidationError(), equals('字体大小必须大于0'));

        final style4 = OverlayStyle(text: '');
        expect(style4.getValidationError(), equals('文本内容不能为空'));

        final validStyle = OverlayStyle(
          width: 100,
          height: 50,
          text: 'Test',
          fontSize: 16,
        );
        expect(validStyle.getValidationError(), isNull);
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        final style1 = OverlayStyle(
          x: 10,
          y: 20,
          width: 100,
          height: 50,
          text: 'Test',
          fontSize: 16,
          backgroundColor: testBlue,
          textColor: testRed,
          horizontalAlign: TextAlign.center,
          verticalAlign: TextAlign.center,
          uiAutomatorCode: 'test code',
          padding: const EdgeInsets.all(8),
        );

        final style2 = OverlayStyle(
          x: 10,
          y: 20,
          width: 100,
          height: 50,
          text: 'Test',
          fontSize: 16,
          backgroundColor: testBlue,
          textColor: testRed,
          horizontalAlign: TextAlign.center,
          verticalAlign: TextAlign.center,
          uiAutomatorCode: 'test code',
          padding: const EdgeInsets.all(8),
        );

        expect(style1, equals(style2));
        expect(style1.hashCode, equals(style2.hashCode));
      });

      test('different instances are not equal', () {
        final style1 = OverlayStyle(text: 'Test 1');
        final style2 = OverlayStyle(text: 'Test 2');

        expect(style1, isNot(equals(style2)));
        expect(style1.hashCode, isNot(equals(style2.hashCode)));
      });
    });
  });
}
