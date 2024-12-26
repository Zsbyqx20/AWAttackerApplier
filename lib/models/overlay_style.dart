import 'package:flutter/material.dart';
import '../utils/overlay_converter.dart';

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
    debugPrint(
        'Converting backgroundColor: ${backgroundColor.value} (${backgroundColor.toString()})');
    debugPrint(
        'Converting textColor: ${textColor.value} (${textColor.toString()})');
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'text': text,
      'fontSize': fontSize,
      'backgroundColor': backgroundColor.value,
      'textColor': textColor.value,
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
    final paddingMap = json['padding'] as Map<String, dynamic>? ?? {};
    return OverlayStyle(
      x: json['x']?.toDouble() ?? 0,
      y: json['y']?.toDouble() ?? 0,
      width: json['width']?.toDouble() ?? 0,
      height: json['height']?.toDouble() ?? 0,
      text: json['text'] ?? '',
      fontSize: json['fontSize']?.toDouble() ?? 14,
      backgroundColor: Color(json['backgroundColor'] ?? Colors.white.value),
      textColor: Color(json['textColor'] ?? Colors.black.value),
      horizontalAlign:
          TextAlign.values[json['horizontalAlign'] ?? TextAlign.left.index],
      verticalAlign:
          TextAlign.values[json['verticalAlign'] ?? TextAlign.center.index],
      uiAutomatorCode: json['uiAutomatorCode'] ?? '',
      padding: EdgeInsets.fromLTRB(
        paddingMap['left']?.toDouble() ?? 0,
        paddingMap['top']?.toDouble() ?? 0,
        paddingMap['right']?.toDouble() ?? 0,
        paddingMap['bottom']?.toDouble() ?? 0,
      ),
    );
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
