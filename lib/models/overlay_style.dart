import 'package:flutter/material.dart';

class OverlayStyle {
  final String text;
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final double x;
  final double y;
  final double width;
  final double height;
  final String uiAutomatorCode;

  const OverlayStyle({
    required this.text,
    required this.fontSize,
    required this.textColor,
    required this.backgroundColor,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.uiAutomatorCode,
  });

  factory OverlayStyle.defaultStyle() {
    return const OverlayStyle(
      text: '',
      fontSize: 14,
      textColor: Colors.black,
      backgroundColor: Colors.white,
      x: 0,
      y: 0,
      width: 0,
      height: 0,
      uiAutomatorCode: '',
    );
  }

  OverlayStyle copyWith({
    String? text,
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    double? x,
    double? y,
    double? width,
    double? height,
    String? uiAutomatorCode,
  }) {
    return OverlayStyle(
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      uiAutomatorCode: uiAutomatorCode ?? this.uiAutomatorCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'fontSize': fontSize,
      'textColor': {
        'r': textColor.r,
        'g': textColor.g,
        'b': textColor.b,
        'a': textColor.a,
      },
      'backgroundColor': {
        'r': backgroundColor.r,
        'g': backgroundColor.g,
        'b': backgroundColor.b,
        'a': backgroundColor.a,
      },
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'uiAutomatorCode': uiAutomatorCode,
    };
  }

  factory OverlayStyle.fromJson(Map<String, dynamic> json) {
    final textColor = json['textColor'] as Map<String, dynamic>;
    final backgroundColor = json['backgroundColor'] as Map<String, dynamic>;

    return OverlayStyle(
      text: json['text'] as String,
      fontSize: (json['fontSize'] as num).toDouble(),
      textColor: Color.fromARGB(
        (textColor['a'] as num).toInt(),
        (textColor['r'] as num).toInt(),
        (textColor['g'] as num).toInt(),
        (textColor['b'] as num).toInt(),
      ),
      backgroundColor: Color.fromARGB(
        (backgroundColor['a'] as num).toInt(),
        (backgroundColor['r'] as num).toInt(),
        (backgroundColor['g'] as num).toInt(),
        (backgroundColor['b'] as num).toInt(),
      ),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      uiAutomatorCode: json['uiAutomatorCode'] as String,
    );
  }
}
