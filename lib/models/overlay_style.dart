import 'package:flutter/material.dart';

import '../exceptions/rule_import_exception.dart';
import '../utils/overlay_converter.dart';

class OverlayStyle {
  /// 颜色通道位移值
  static const int alphaShift = 24;
  static const int redShift = 16;
  static const int greenShift = 8;
  static const int blueShift = 0;

  /// 文本对齐值
  static const int alignStart = 0;
  static const int alignCenter = 1;
  static const int alignEnd = 2;

  /// 颜色通道最大值
  static const int channelMax = 0xFF;

  /// Alpha通道掩码 (用于Java端的值)
  static const int alphaMask = 0x7F;

  /// 颜色掩码 (不包含alpha通道)
  static const int colorMask = 0x00FFFFFF;

  /// 规则名称最大长度
  static const int maxRuleNameLength = 50;

  /// 默认字体大小
  static const double defaultFontSize = 14.0;

  /// RGB颜色字符串长度
  static const int rgbHexLength = 6;

  /// ARGB颜色字符串长度
  static const int argbHexLength = 8;

  /// 十六进制基数
  static const int hexRadix = 16;

  /// 完全不透明的Alpha通道值
  static const String opaqueAlpha = 'FF';

  /// 默认位置和尺寸
  static const double defaultPosition = 0.0;

  /// 默认尺寸
  static const double defaultSize = 0.0;

  /// 默认文本
  static const String defaultText = '';

  /// 默认UI自动化代码
  static const String defaultUiAutomatorCode = '';

  /// 默认内边距
  static const double defaultPadding = 0.0;

  /// 颜色通道最大值（0-255）
  static const int colorChannelMaxValue = 255;

  /// 十六进制颜色位数
  static const int hexColorDigits = 2;

  final double x;
  final double y;
  final double width;
  final double height;
  final String text;
  final double fontSize;
  final Color backgroundColor;
  final Color textColor;
  final TextAlign horizontalAlign;
  final TextAlign verticalAlign;
  final String uiAutomatorCode;
  final EdgeInsets padding;

  @override
  int get hashCode {
    return Object.hash(
      x,
      y,
      width,
      height,
      text,
      fontSize,
      backgroundColor,
      textColor,
      horizontalAlign,
      verticalAlign,
      uiAutomatorCode,
      padding,
    );
  }

  const OverlayStyle({
    this.x = defaultPosition,
    this.y = defaultPosition,
    this.width = defaultSize,
    this.height = defaultSize,
    this.text = defaultText,
    this.fontSize = defaultFontSize,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.horizontalAlign = TextAlign.left,
    this.verticalAlign = TextAlign.center,
    this.uiAutomatorCode = defaultUiAutomatorCode,
    this.padding = const EdgeInsets.all(0),
  });

  factory OverlayStyle.defaultStyle() {
    return const OverlayStyle();
  }

  factory OverlayStyle.fromJson(Map<String, dynamic> json) {
    // 验证必需字段
    if (!json.containsKey('text')) {
      throw RuleImportException.missingField('text');
    }
    if (!json.containsKey('fontSize')) {
      throw RuleImportException.missingField('fontSize');
    }

    // 解析 padding
    final paddingMap = json['padding'] as Map<String, dynamic>? ?? {};
    try {
      final padding = EdgeInsets.fromLTRB(
        (paddingMap['left'] as num?)?.toDouble() ?? defaultPadding,
        (paddingMap['top'] as num?)?.toDouble() ?? defaultPadding,
        (paddingMap['right'] as num?)?.toDouble() ?? defaultPadding,
        (paddingMap['bottom'] as num?)?.toDouble() ?? defaultPadding,
      );
      // 验证 padding 不能为负数
      if (padding.left < 0 ||
          padding.top < 0 ||
          padding.right < 0 ||
          padding.bottom < 0) {
        throw RuleImportException.invalidFieldValue('padding', '内边距不能为负数');
      }
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        RuleImportException.invalidFieldValue('padding', '无效的内边距格式'),
        stackTrace,
      );
    }

    // 处理颜色值，支持整数和十六进制字符串
    int parseColorValue(Object? value, String fieldName, int defaultColor) {
      if (value == null) return defaultColor;
      try {
        if (value is int) return value;
        if (value is String) {
          final hexString = value.startsWith('#')
              ? value.characters.getRange(1).string
              : value;
          if (hexString.length == rgbHexLength) {
            // 如果是6位的RGB值，添加FF作为alpha通道
            return int.parse('$opaqueAlpha$hexString', radix: hexRadix);
          }
          if (hexString.length == argbHexLength) {
            // 如果是8位的ARGB值，直接解析
            return int.parse(hexString, radix: hexRadix);
          }
        }
        throw RuleImportException.invalidFieldValue(fieldName, '无效的颜色格式');
      } catch (e, stackTrace) {
        Error.throwWithStackTrace(
            RuleImportException.invalidFieldValue(fieldName, '无效的颜色格式'),
            stackTrace);
      }
    }

    final defaultBackgroundColor = (channelMax << alphaShift) |
        (channelMax << redShift) |
        (channelMax << greenShift) |
        channelMax;
    final defaultTextColor =
        (channelMax << alphaShift) | (0 << redShift) | (0 << greenShift) | 0;

    // 处理文本对齐方式
    TextAlign parseTextAlign(
        Object? value, TextAlign defaultValue, bool isHorizontal) {
      if (value == null) return defaultValue;
      if (value is int) return TextAlign.values[value];
      if (value is String) {
        switch (value.toLowerCase()) {
          case 'left':
            return TextAlign.left;
          case 'start':
            return isHorizontal ? TextAlign.left : TextAlign.start;
          case 'center':
            return TextAlign.center;
          case 'right':
            return TextAlign.right;
          case 'end':
            return isHorizontal ? TextAlign.right : TextAlign.end;
          default:
            return defaultValue;
        }
      }

      return defaultValue;
    }

    try {
      return OverlayStyle(
        x: (json['x'] as num?)?.toDouble() ?? defaultPosition,
        y: (json['y'] as num?)?.toDouble() ?? defaultPosition,
        width: (json['width'] as num?)?.toDouble() ?? defaultSize,
        height: (json['height'] as num?)?.toDouble() ?? defaultSize,
        text: json['text'] as String? ?? defaultText,
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? defaultFontSize,
        backgroundColor: Color(parseColorValue(json['backgroundColor'],
            'backgroundColor', defaultBackgroundColor)),
        textColor: Color(
            parseColorValue(json['textColor'], 'textColor', defaultTextColor)),
        horizontalAlign:
            parseTextAlign(json['horizontalAlign'], TextAlign.left, true),
        verticalAlign:
            parseTextAlign(json['verticalAlign'], TextAlign.center, false),
        uiAutomatorCode: json['uiAutomatorCode'] as String? ?? '',
        padding: EdgeInsets.fromLTRB(
          (paddingMap['left'] as num?)?.toDouble() ?? defaultPadding,
          (paddingMap['top'] as num?)?.toDouble() ?? defaultPadding,
          (paddingMap['right'] as num?)?.toDouble() ?? defaultPadding,
          (paddingMap['bottom'] as num?)?.toDouble() ?? defaultPadding,
        ),
      );
    } catch (e, stackTrace) {
      if (e is RuleImportException) {
        rethrow;
      }
      Error.throwWithStackTrace(
          RuleImportException.invalidFieldValue('overlayStyle', e.toString()),
          stackTrace);
    }
  }

  @override
  String toString() {
    return 'OverlayStyle{x: $x, y: $y, width: $width, height: $height, text: $text, fontSize: $fontSize}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OverlayStyle &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height &&
        other.text == text &&
        other.fontSize == fontSize &&
        other.backgroundColor == backgroundColor &&
        other.textColor == textColor &&
        other.horizontalAlign == horizontalAlign &&
        other.verticalAlign == verticalAlign &&
        other.uiAutomatorCode == uiAutomatorCode &&
        other.padding == padding;
  }

  OverlayStyle copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    String? text,
    double? fontSize,
    Color? backgroundColor,
    Color? textColor,
    TextAlign? horizontalAlign,
    TextAlign? verticalAlign,
    String? uiAutomatorCode,
    EdgeInsets? padding,
  }) {
    return OverlayStyle(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      horizontalAlign: horizontalAlign ?? this.horizontalAlign,
      verticalAlign: verticalAlign ?? this.verticalAlign,
      uiAutomatorCode: uiAutomatorCode ?? this.uiAutomatorCode,
      padding: padding ?? this.padding,
    );
  }

  /// 转换为原生平台可用的格式
  Map<String, dynamic> toNative() {
    return OverlayConverter.styleToNative(this);
  }

  /// 验证样式是否有效
  bool isValid() {
    return width >= 0 && height >= 0 && fontSize > 0 && text.isNotEmpty;
  }

  /// 获取验证错误信息
  String? getValidationError() {
    if (width < 0) return '宽度不能为负数';
    if (height < 0) return '高度不能为负数';
    if (fontSize <= 0) return '字体大小必须大于0';
    if (text.isEmpty) return '文本内容不能为空';

    return null;
  }

  Map<String, dynamic> toJson() {
    String colorToHex(Color color) {
      return '#${(color.a * colorChannelMaxValue).toInt().toRadixString(hexRadix).padLeft(hexColorDigits, '0').toUpperCase()}'
          '${(color.r * colorChannelMaxValue).toInt().toRadixString(hexRadix).padLeft(hexColorDigits, '0').toUpperCase()}'
          '${(color.g * colorChannelMaxValue).toInt().toRadixString(hexRadix).padLeft(hexColorDigits, '0').toUpperCase()}'
          '${(color.b * colorChannelMaxValue).toInt().toRadixString(hexRadix).padLeft(hexColorDigits, '0').toUpperCase()}';
    }

    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'text': text,
      'fontSize': fontSize,
      'backgroundColor': colorToHex(backgroundColor),
      'textColor': colorToHex(textColor),
      'horizontalAlign': _textAlignToString(horizontalAlign),
      'verticalAlign': _textAlignToString(verticalAlign),
      'uiAutomatorCode': uiAutomatorCode,
      'padding': {
        'left': padding.left,
        'top': padding.top,
        'right': padding.right,
        'bottom': padding.bottom,
      },
    };
  }

  // 将 TextAlign 转换为字符串
  String _textAlignToString(TextAlign align) {
    switch (align) {
      case TextAlign.left:
      case TextAlign.start:
        return 'start';
      case TextAlign.center:
        return 'center';
      case TextAlign.right:
      case TextAlign.end:
        return 'end';
      case TextAlign.justify:
        return 'center';
    }
  }
}
