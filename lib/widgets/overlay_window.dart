import 'package:flutter/material.dart';

import '../models/overlay_style.dart';

class OverlayWindow extends StatelessWidget {
  final OverlayStyle style;

  const OverlayWindow({
    super.key,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: style.x,
      top: style.y,
      child: Container(
        width: style.width,
        height: style.height,
        decoration: BoxDecoration(
          color: Color.fromRGBO(
            (style.backgroundColor.r * 255).toInt(),
            (style.backgroundColor.g * 255).toInt(),
            (style.backgroundColor.b * 255).toInt(),
            0.8,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: style.padding,
          child: Center(
            child: Text(
              style.text,
              style: TextStyle(
                fontSize: style.fontSize,
                color: style.textColor,
              ),
              textAlign: style.horizontalAlign,
            ),
          ),
        ),
      ),
    );
  }
}
