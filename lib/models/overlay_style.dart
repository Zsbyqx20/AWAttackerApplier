import 'package:flutter/material.dart';
import '../utils/overlay_converter.dart';
import '../exceptions/rule_import_exception.dart';

class OverlayStyle {
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

  const OverlayStyle({
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
    this.text = '',
    this.fontSize = 14,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.horizontalAlign = TextAlign.left,
    this.verticalAlign = TextAlign.center,
    this.uiAutomatorCode = '',
    this.padding = const EdgeInsets.all(0),
  });

  factory OverlayStyle.defaultStyle() {
    return const OverlayStyle();
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
    debugPrint('Converting backgroundColor: ${backgroundColor.toString()}');
    debugPrint('Converting textColor: ${textColor.toString()}');
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'text': text,
      'fontSize': fontSize,
      'backgroundColor': (backgroundColor.r * 255).toInt() << 16 |
          (backgroundColor.g * 255).toInt() << 8 |
          (backgroundColor.b * 255).toInt() |
          (0xFF << 24),
      'textColor': (textColor.r * 255).toInt() << 16 |
          (textColor.g * 255).toInt() << 8 |
          (textColor.b * 255).toInt() |
          (0xFF << 24),
      'horizontalAlign': horizontalAlign.index,
      'verticalAlign': verticalAlign.index,
      'uiAutomatorCode': uiAutomatorCode,
      'padding': {
        'left': padding.left,
        'top': padding.top,
        'right': padding.right,
        'bottom': padding.bottom,
      },
    };
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
        paddingMap['left']?.toDouble() ?? 0,
        paddingMap['top']?.toDouble() ?? 0,
        paddingMap['right']?.toDouble() ?? 0,
        paddingMap['bottom']?.toDouble() ?? 0,
      );
      // 验证 padding 不能为负数
      if (padding.left < 0 ||
          padding.top < 0 ||
          padding.right < 0 ||
          padding.bottom < 0) {
        throw RuleImportException.invalidFieldValue('padding', '内边距不能为负数');
      }
    } catch (e) {
      throw RuleImportException.invalidFieldValue('padding', '无效的内边距格式');
    }

    // 处理颜色值，支持整数和十六进制字符串
    int parseColorValue(dynamic value, String fieldName, int defaultColor) {
      if (value == null) return defaultColor;
      try {
        if (value is int) return value;
        if (value is String) {
          final hexString = value.startsWith('#') ? value.substring(1) : value;
          if (hexString.length == 6) {
            // 如果是6位的RGB值，添加FF作为alpha通道
            return int.parse('FF$hexString', radix: 16);
          }
          if (hexString.length == 8) {
            // 如果是8位的ARGB值，直接解析
            return int.parse(hexString, radix: 16);
          }
        }
        throw RuleImportException.invalidFieldValue(fieldName, '无效的颜色格式');
      } catch (e) {
        throw RuleImportException.invalidFieldValue(fieldName, '无效的颜色格式');
      }
    }

    final defaultBackgroundColor =
        (0xFF << 24) | (0xFF << 16) | (0xFF << 8) | 0xFF;
    final defaultTextColor = (0xFF << 24) | (0 << 16) | (0 << 8) | 0;

    // 处理文本对齐方式
    TextAlign parseTextAlign(dynamic value, TextAlign defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return TextAlign.values[value];
      if (value is String) {
        switch (value.toLowerCase()) {
          case 'left':
          case 'start':
            return TextAlign.left;
          case 'center':
            return TextAlign.center;
          case 'right':
          case 'end':
            return TextAlign.right;
          default:
            return defaultValue;
        }
      }
      return defaultValue;
    }

    try {
      return OverlayStyle(
        x: json['x']?.toDouble() ?? 0,
        y: json['y']?.toDouble() ?? 0,
        width: json['width']?.toDouble() ?? 0,
        height: json['height']?.toDouble() ?? 0,
        text: json['text'] ?? '',
        fontSize: json['fontSize']?.toDouble() ?? 14,
        backgroundColor: Color(parseColorValue(json['backgroundColor'],
            'backgroundColor', defaultBackgroundColor)),
        textColor: Color(
            parseColorValue(json['textColor'], 'textColor', defaultTextColor)),
        horizontalAlign:
            parseTextAlign(json['horizontalAlign'], TextAlign.left),
        verticalAlign: parseTextAlign(json['verticalAlign'], TextAlign.center),
        uiAutomatorCode: json['uiAutomatorCode'] ?? '',
        padding: EdgeInsets.fromLTRB(
          paddingMap['left']?.toDouble() ?? 0,
          paddingMap['top']?.toDouble() ?? 0,
          paddingMap['right']?.toDouble() ?? 0,
          paddingMap['bottom']?.toDouble() ?? 0,
        ),
      );
    } catch (e) {
      if (e is RuleImportException) {
        rethrow;
      }
      throw RuleImportException.invalidFieldValue('overlayStyle', e.toString());
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
}
