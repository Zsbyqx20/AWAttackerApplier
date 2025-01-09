import 'package:flutter/material.dart';

import '../models/overlay_style.dart';

/// 悬浮窗数据转换工具类
class OverlayConverter {
  /// 将OverlayStyle转换为原生平台可用的格式
  static Map<String, dynamic> styleToNative(OverlayStyle style) {
    final backgroundColor = ((style.backgroundColor.r * 255).toInt() << 16) |
        ((style.backgroundColor.g * 255).toInt() << 8) |
        (style.backgroundColor.b * 255).toInt() |
        (0xFF << 24);
    final textColor = ((style.textColor.r * 255).toInt() << 16) |
        ((style.textColor.g * 255).toInt() << 8) |
        (style.textColor.b * 255).toInt() |
        (0xFF << 24);

    return {
      'x': style.x,
      'y': style.y,
      'width': style.width,
      'height': style.height,
      'text': style.text,
      'fontSize': style.fontSize,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'horizontalAlign': _convertTextAlign(style.horizontalAlign),
      'verticalAlign': _convertTextAlign(style.verticalAlign),
      'padding': {
        'left': style.padding.left,
        'top': style.padding.top,
        'right': style.padding.right,
        'bottom': style.padding.bottom,
      },
    };
  }

  /// 将TextAlign转换为整数值
  /// 0: left/top, 1: center, 2: right/bottom
  static int _convertTextAlign(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return 1;
      case TextAlign.right:
      case TextAlign.end:
        return 2;
      case TextAlign.left:
      case TextAlign.start:
      default:
        return 0;
    }
  }

  /// 将整数值转换为TextAlign
  static TextAlign _convertToTextAlign(int value) {
    switch (value) {
      case 1:
        return TextAlign.center;
      case 2:
        return TextAlign.right;
      case 0:
      default:
        return TextAlign.left;
    }
  }

  /// 从原生平台响应创建OverlayStyle
  static OverlayStyle styleFromNative(Map<String, dynamic> map) {
    final backgroundColor = map['backgroundColor'] as int;
    final textColor = map['textColor'] as int;

    // 从 Java 端的值恢复完整的 alpha 通道
    final bgAlpha = (backgroundColor >> 24) & 0x7F;
    final txtAlpha = (textColor >> 24) & 0x7F;

    // 将 0x7F 映射回 0xFF
    final restoredBgAlpha = (bgAlpha * 0xFF) ~/ 0x7F;
    final restoredTxtAlpha = (txtAlpha * 0xFF) ~/ 0x7F;

    final restoredBgColor =
        ((restoredBgAlpha & 0xFF) << 24) | (backgroundColor & 0x00FFFFFF);
    final restoredTxtColor =
        ((restoredTxtAlpha & 0xFF) << 24) | (textColor & 0x00FFFFFF);

    return OverlayStyle(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      text: map['text'] as String,
      fontSize: (map['fontSize'] as num).toDouble(),
      backgroundColor: Color(restoredBgColor),
      textColor: Color(restoredTxtColor),
      horizontalAlign: _convertToTextAlign(map['horizontalAlign'] as int),
      verticalAlign: _convertToTextAlign(map['verticalAlign'] as int),
      padding: EdgeInsets.fromLTRB(
        (map['padding']['left'] as num).toDouble(),
        (map['padding']['top'] as num).toDouble(),
        (map['padding']['right'] as num).toDouble(),
        (map['padding']['bottom'] as num).toDouble(),
      ),
    );
  }
}
