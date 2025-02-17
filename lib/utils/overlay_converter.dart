import 'package:flutter/material.dart';

import '../models/overlay_style.dart';

/// 悬浮窗数据转换工具类
class OverlayConverter {
  /// 将OverlayStyle转换为原生平台可用的格式
  static Map<String, dynamic> styleToNative(OverlayStyle style) {
    final backgroundColor =
        ((style.backgroundColor.r * OverlayStyle.colorChannelMaxValue)
                    .toInt() <<
                OverlayStyle.redShift) |
            ((style.backgroundColor.g * OverlayStyle.colorChannelMaxValue)
                    .toInt() <<
                OverlayStyle.greenShift) |
            ((style.backgroundColor.b * OverlayStyle.colorChannelMaxValue)
                    .toInt() <<
                OverlayStyle.blueShift) |
            (OverlayStyle.channelMax << OverlayStyle.alphaShift);
    final textColor =
        ((style.textColor.r * OverlayStyle.colorChannelMaxValue).toInt() <<
                OverlayStyle.redShift) |
            ((style.textColor.g * OverlayStyle.colorChannelMaxValue).toInt() <<
                OverlayStyle.greenShift) |
            ((style.textColor.b * OverlayStyle.colorChannelMaxValue).toInt() <<
                OverlayStyle.blueShift) |
            (OverlayStyle.channelMax << OverlayStyle.alphaShift);

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
      'uiAutomatorCode': style.uiAutomatorCode,
      'allow': style.allow,
      'deny': style.deny,
    };
  }

  /// 从原生平台响应创建OverlayStyle
  static OverlayStyle styleFromNative(Map<String, dynamic> map) {
    final backgroundColor = map['backgroundColor'] as int;
    final textColor = map['textColor'] as int;

    // 从 Java 端的值恢复完整的 alpha 通道
    final bgAlpha =
        (backgroundColor >> OverlayStyle.alphaShift) & OverlayStyle.alphaMask;
    final txtAlpha =
        (textColor >> OverlayStyle.alphaShift) & OverlayStyle.alphaMask;

    // 将 0x7F 映射回 0xFF
    final restoredBgAlpha =
        (bgAlpha * OverlayStyle.channelMax) ~/ OverlayStyle.alphaMask;
    final restoredTxtAlpha =
        (txtAlpha * OverlayStyle.channelMax) ~/ OverlayStyle.alphaMask;

    final restoredBgColor = ((restoredBgAlpha & OverlayStyle.channelMax) <<
            OverlayStyle.alphaShift) |
        (backgroundColor & OverlayStyle.colorMask);
    final restoredTxtColor = ((restoredTxtAlpha & OverlayStyle.channelMax) <<
            OverlayStyle.alphaShift) |
        (textColor & OverlayStyle.colorMask);

    // 处理 allow 和 deny 列表
    final allowList = map['allow'] as List<String>?;
    final denyList = map['deny'] as List<String>?;

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
      uiAutomatorCode: map['uiAutomatorCode'] as String,
      allow: allowList?.cast<String>(),
      deny: denyList?.cast<String>(),
    );
  }

  /// 将TextAlign转换为整数值
  /// 0: left/top, 1: center, 2: right/bottom
  static int _convertTextAlign(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return OverlayStyle.alignCenter;
      case TextAlign.right:
      case TextAlign.end:
        return OverlayStyle.alignEnd;
      case TextAlign.left:
      case TextAlign.start:
      default:
        return OverlayStyle.alignStart;
    }
  }

  /// 将整数值转换为TextAlign
  static TextAlign _convertToTextAlign(int value) {
    switch (value) {
      case OverlayStyle.alignCenter:
        return TextAlign.center;
      case OverlayStyle.alignEnd:
        return TextAlign.right;
      case OverlayStyle.alignStart:
      default:
        return TextAlign.left;
    }
  }
}
