import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:awattackerapplier/l10n/app_localizations.dart';

import '../models/overlay_style.dart';

class ColorPickerField extends StatelessWidget {
  const ColorPickerField({
    super.key,
    required this.label,
    required this.color,
    required this.onColorChanged,
  });

  static const double _titleFontSize = 16.0;
  static const double _textFontSize = 14.0;
  static const double _previewHeight = 40.0;
  static const double _previewWidth = 100.0;
  static const double _containerHeight = 36.0;
  static const double _borderWidth = 1.0;
  static const double _focusedBorderWidth = 1.5;
  static const double _borderRadius = 6.0;
  static const double _dialogBorderRadius = 12.0;
  static const double _dialogPaddingHorizontal = 16.0;
  static const double _dialogPaddingVertical = 8.0;
  static const double _previewSpacing = 16.0;

  final String label;
  final Color color;
  final ValueChanged<Color> onColorChanged;

  Future<void> _showColorPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return;
    }

    final String currentHex =
        '${(color.a * OverlayStyle.colorChannelMaxValue).toInt().toRadixString(OverlayStyle.hexRadix).padLeft(OverlayStyle.hexColorDigits, '0')}'
        '${(color.r * OverlayStyle.colorChannelMaxValue).toInt().toRadixString(OverlayStyle.hexRadix).padLeft(OverlayStyle.hexColorDigits, '0')}'
        '${(color.g * OverlayStyle.colorChannelMaxValue).toInt().toRadixString(OverlayStyle.hexRadix).padLeft(OverlayStyle.hexColorDigits, '0')}'
        '${(color.b * OverlayStyle.colorChannelMaxValue).toInt().toRadixString(OverlayStyle.hexRadix).padLeft(OverlayStyle.hexColorDigits, '0')}';
    debugPrint('Current color: ${color.toString()} (hex: #$currentHex)');
    final TextEditingController hexController = TextEditingController(
        text:
            currentHex.characters.getRange(OverlayStyle.hexColorDigits).string);
    Color previewColor = color;

    final String? newHex = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            label.isNotEmpty ? label : l10n.selectColor,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: _titleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: _previewHeight,
                width: _previewWidth,
                decoration: BoxDecoration(
                  color: previewColor,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: _previewSpacing),
              TextField(
                controller: hexController,
                decoration: InputDecoration(
                  labelText: l10n.hexColorValue,
                  hintText: l10n.hexColorHint,
                  prefixText: '#',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: _focusedBorderWidth,
                    ),
                  ),
                ),
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                  LengthLimitingTextInputFormatter(OverlayStyle.argbHexLength),
                ],
                onChanged: (value) {
                  if (value.length == OverlayStyle.rgbHexLength ||
                      value.length == OverlayStyle.argbHexLength) {
                    try {
                      final colorHex = value.length == OverlayStyle.rgbHexLength
                          ? 'FF$value'
                          : value;
                      final newColor = Color(
                          int.parse(colorHex, radix: OverlayStyle.hexRadix));
                      debugPrint(
                          'New color from hex: ${newColor.toString()} (hex: #$value)');
                      setState(() {
                        previewColor = newColor;
                      });
                    } catch (e) {
                      // 忽略无效的颜色值
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  fontSize: _textFontSize,
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final hex = hexController.text;
                if (hex.length == OverlayStyle.rgbHexLength ||
                    hex.length == OverlayStyle.argbHexLength) {
                  try {
                    final colorHex = hex.length == OverlayStyle.rgbHexLength
                        ? 'FF$hex'
                        : hex;
                    Color(int.parse(colorHex, radix: OverlayStyle.hexRadix));
                    Navigator.of(context).pop(colorHex);
                  } catch (e) {
                    // 忽略无效的颜色值
                  }
                }
              },
              child: Text(
                l10n.confirm,
                style: TextStyle(
                  fontSize: _textFontSize,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: _dialogPaddingHorizontal,
            vertical: _dialogPaddingVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                const BorderRadius.all(Radius.circular(_dialogBorderRadius)),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );

    if (newHex != null) {
      final newColor = Color(int.parse(newHex, radix: OverlayStyle.hexRadix));
      debugPrint('Selected color: ${newColor.toString()} (hex: #$newHex)');
      onColorChanged(newColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showColorPicker(context),
      borderRadius: const BorderRadius.all(Radius.circular(_borderRadius)),
      child: Container(
        height: _containerHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(_borderRadius)),
          border: Border.all(
            color: Colors.grey.shade300,
            width: _borderWidth,
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
