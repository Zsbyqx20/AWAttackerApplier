import 'dart:ui';
import 'package:flutter/material.dart' show EdgeInsets, Alignment;

class OverlayStyle {
  final String uiAutomatorCode;
  final double x;
  final double y;
  final double width;
  final double height;
  final Color backgroundColor;
  final String text;
  final double fontSize;
  final Color textColor;
  final EdgeInsets padding;
  final Alignment alignment;

  OverlayStyle({
    required this.uiAutomatorCode,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.text,
    required this.fontSize,
    required this.textColor,
    required this.padding,
    required this.alignment,
  });

  OverlayStyle copyWith({
    String? uiAutomatorCode,
    double? x,
    double? y,
    double? width,
    double? height,
    Color? backgroundColor,
    String? text,
    double? fontSize,
    Color? textColor,
    EdgeInsets? padding,
    Alignment? alignment,
  }) {
    return OverlayStyle(
      uiAutomatorCode: uiAutomatorCode ?? this.uiAutomatorCode,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      padding: padding ?? this.padding,
      alignment: alignment ?? this.alignment,
    );
  }

  Map<String, dynamic> toJson() => {
        'uiAutomatorCode': uiAutomatorCode,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'backgroundColor': {
          'r': backgroundColor.r,
          'g': backgroundColor.g,
          'b': backgroundColor.b,
          'a': backgroundColor.a,
        },
        'text': text,
        'fontSize': fontSize,
        'textColor': {
          'r': textColor.r,
          'g': textColor.g,
          'b': textColor.b,
          'a': textColor.a,
        },
        'padding': {
          'top': padding.top,
          'right': padding.right,
          'bottom': padding.bottom,
          'left': padding.left,
        },
        'alignment': {
          'x': alignment.x,
          'y': alignment.y,
        },
      };

  factory OverlayStyle.fromJson(Map<String, dynamic> json) => OverlayStyle(
        uiAutomatorCode: json['uiAutomatorCode'] as String,
        x: json['x'] as double,
        y: json['y'] as double,
        width: json['width'] as double,
        height: json['height'] as double,
        backgroundColor: json['backgroundColor'] is Map
            ? Color.fromARGB(
                json['backgroundColor']['a'] as int,
                json['backgroundColor']['r'] as int,
                json['backgroundColor']['g'] as int,
                json['backgroundColor']['b'] as int,
              )
            : Color(json['backgroundColor'] as int),
        text: json['text'] as String,
        fontSize: json['fontSize'] as double,
        textColor: json['textColor'] is Map
            ? Color.fromARGB(
                json['textColor']['a'] as int,
                json['textColor']['r'] as int,
                json['textColor']['g'] as int,
                json['textColor']['b'] as int,
              )
            : Color(json['textColor'] as int),
        padding: json['padding'] != null
            ? EdgeInsets.fromLTRB(
                json['padding']['left'] as double,
                json['padding']['top'] as double,
                json['padding']['right'] as double,
                json['padding']['bottom'] as double,
              )
            : const EdgeInsets.all(8),
        alignment: json['alignment'] != null
            ? Alignment(
                json['alignment']['x'] as double,
                json['alignment']['y'] as double,
              )
            : Alignment.center,
      );
}

class Rule {
  final String id;
  final String name;
  final String packageName;
  final String activityName;
  final bool isEnabled;
  final List<OverlayStyle> overlayStyles;

  Rule({
    required this.id,
    required this.name,
    required this.packageName,
    required this.activityName,
    this.isEnabled = false,
    required this.overlayStyles,
  });

  Rule copyWith({
    String? id,
    String? name,
    String? packageName,
    String? activityName,
    bool? isEnabled,
    List<OverlayStyle>? overlayStyles,
  }) {
    return Rule(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      activityName: activityName ?? this.activityName,
      isEnabled: isEnabled ?? this.isEnabled,
      overlayStyles: overlayStyles ?? this.overlayStyles,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'packageName': packageName,
        'activityName': activityName,
        'isEnabled': isEnabled,
        'overlayStyles': overlayStyles.map((style) => style.toJson()).toList(),
      };

  factory Rule.fromJson(Map<String, dynamic> json) => Rule(
        id: json['id'] as String,
        name: json['name'] as String,
        packageName: json['packageName'] as String,
        activityName: json['activityName'] as String,
        isEnabled: json['isEnabled'] as bool,
        overlayStyles: (json['overlayStyles'] as List)
            .map(
                (style) => OverlayStyle.fromJson(style as Map<String, dynamic>))
            .toList(),
      );
}
