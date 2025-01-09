import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:awattackerapplier/models/overlay_style.dart';
import 'package:awattackerapplier/utils/overlay_converter.dart';

void main() {
  group('OverlayConverter', () {
    late OverlayStyle testStyle;
    final testBlue = const Color(0xFF2196F3);
    final testRed = const Color(0xFFF44336);

    setUp(() {
      testStyle = OverlayStyle(
        x: 100.0,
        y: 200.0,
        width: 300.0,
        height: 400.0,
        text: '测试文本',
        fontSize: 16.0,
        backgroundColor: testBlue,
        textColor: testRed,
        horizontalAlign: TextAlign.center,
        verticalAlign: TextAlign.center,
        padding: const EdgeInsets.fromLTRB(10, 20, 30, 40),
      );
    });

    test('styleToNative 转换基本属性', () {
      final nativeMap = OverlayConverter.styleToNative(testStyle);

      expect(nativeMap['x'], equals(100.0));
      expect(nativeMap['y'], equals(200.0));
      expect(nativeMap['width'], equals(300.0));
      expect(nativeMap['height'], equals(400.0));
      expect(nativeMap['text'], equals('测试文本'));
      expect(nativeMap['fontSize'], equals(16.0));
    });

    test('styleToNative 转换颜色', () {
      final nativeMap = OverlayConverter.styleToNative(testStyle);

      expect(nativeMap['backgroundColor'], equals(0xFF2196F3));
      expect(nativeMap['textColor'], equals(0xFFF44336));
    });

    test('styleToNative 转换文本对齐', () {
      final nativeMap = OverlayConverter.styleToNative(testStyle);

      // TextAlign.center 应该转换为 1
      expect(nativeMap['horizontalAlign'], equals(1));
      expect(nativeMap['verticalAlign'], equals(1));

      // 测试其他对齐方式
      final leftStyle = testStyle.copyWith(horizontalAlign: TextAlign.left);
      final rightStyle = testStyle.copyWith(horizontalAlign: TextAlign.right);

      expect(OverlayConverter.styleToNative(leftStyle)['horizontalAlign'],
          equals(0));
      expect(OverlayConverter.styleToNative(rightStyle)['horizontalAlign'],
          equals(2));
    });

    test('styleToNative 转换边距', () {
      final nativeMap = OverlayConverter.styleToNative(testStyle);
      final padding = nativeMap['padding'] as Map<String, dynamic>;

      expect(padding['left'], equals(10.0));
      expect(padding['top'], equals(20.0));
      expect(padding['right'], equals(30.0));
      expect(padding['bottom'], equals(40.0));
    });

    test('styleFromNative 转换基本属性', () {
      final nativeMap = {
        'x': 100.0,
        'y': 200.0,
        'width': 300.0,
        'height': 400.0,
        'text': '测试文本',
        'fontSize': 16.0,
        'backgroundColor': 0xFF2196F3,
        'textColor': 0xFFF44336,
        'horizontalAlign': 1,
        'verticalAlign': 1,
        'padding': {
          'left': 10.0,
          'top': 20.0,
          'right': 30.0,
          'bottom': 40.0,
        },
      };

      final style = OverlayConverter.styleFromNative(nativeMap);

      expect(style.x, equals(100.0));
      expect(style.y, equals(200.0));
      expect(style.width, equals(300.0));
      expect(style.height, equals(400.0));
      expect(style.text, equals('测试文本'));
      expect(style.fontSize, equals(16.0));
      expect(style.backgroundColor, equals(testBlue));
      expect(style.textColor, equals(testRed));
      expect(style.horizontalAlign, equals(TextAlign.center));
      expect(style.verticalAlign, equals(TextAlign.center));
      expect(style.padding.left, equals(10.0));
      expect(style.padding.top, equals(20.0));
      expect(style.padding.right, equals(30.0));
      expect(style.padding.bottom, equals(40.0));
    });

    test('颜色转换的双向一致性', () {
      final nativeMap = OverlayConverter.styleToNative(testStyle);
      final convertedStyle = OverlayConverter.styleFromNative(nativeMap);

      expect(convertedStyle.backgroundColor.r,
          equals(testStyle.backgroundColor.r));
      expect(convertedStyle.backgroundColor.g,
          equals(testStyle.backgroundColor.g));
      expect(convertedStyle.backgroundColor.b,
          equals(testStyle.backgroundColor.b));
      expect(convertedStyle.textColor.r, equals(testStyle.textColor.r));
      expect(convertedStyle.textColor.g, equals(testStyle.textColor.g));
      expect(convertedStyle.textColor.b, equals(testStyle.textColor.b));
    });

    test('文本对齐转换的双向一致性', () {
      final alignments = [TextAlign.left, TextAlign.center, TextAlign.right];

      for (final align in alignments) {
        final style =
            testStyle.copyWith(horizontalAlign: align, verticalAlign: align);
        final nativeMap = OverlayConverter.styleToNative(style);
        final convertedStyle = OverlayConverter.styleFromNative(nativeMap);

        expect(convertedStyle.horizontalAlign, equals(style.horizontalAlign));
        expect(convertedStyle.verticalAlign, equals(style.verticalAlign));
      }
    });

    test('边距转换的双向一致性', () {
      final nativeMap = OverlayConverter.styleToNative(testStyle);
      final convertedStyle = OverlayConverter.styleFromNative(nativeMap);

      expect(convertedStyle.padding, equals(testStyle.padding));
    });
  });
}
