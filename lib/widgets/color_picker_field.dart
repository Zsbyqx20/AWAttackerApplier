import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

class ColorPickerField extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerField({
    super.key,
    required this.label,
    required this.color,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showColorPicker(context),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
    );
  }

  Future<void> _showColorPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final String currentHex =
        '${(color.a * 255).toInt().toRadixString(16).padLeft(2, '0')}'
        '${(color.r * 255).toInt().toRadixString(16).padLeft(2, '0')}'
        '${(color.g * 255).toInt().toRadixString(16).padLeft(2, '0')}'
        '${(color.b * 255).toInt().toRadixString(16).padLeft(2, '0')}';
    debugPrint('Current color: ${color.toString()} (hex: #$currentHex)');
    final TextEditingController hexController =
        TextEditingController(text: currentHex.substring(2));
    Color previewColor = color;

    final String? newHex = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            label.isNotEmpty ? label : l10n.selectColor,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40,
                width: 100,
                decoration: BoxDecoration(
                  color: previewColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hexController,
                decoration: InputDecoration(
                  labelText: l10n.hexColorValue,
                  hintText: l10n.hexColorHint,
                  prefixText: '#',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                  LengthLimitingTextInputFormatter(8),
                ],
                onChanged: (value) {
                  if (value.length == 6 || value.length == 8) {
                    try {
                      final colorHex = value.length == 6 ? 'FF$value' : value;
                      final newColor = Color(int.parse(colorHex, radix: 16));
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
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final hex = hexController.text;
                if (hex.length == 6 || hex.length == 8) {
                  try {
                    final colorHex = hex.length == 6 ? 'FF$hex' : hex;
                    Color(int.parse(colorHex, radix: 16));
                    Navigator.of(context).pop(colorHex);
                  } catch (e) {
                    // 忽略无效的颜色值
                  }
                }
              },
              child: Text(
                l10n.confirm,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );

    if (newHex != null) {
      final newColor = Color(int.parse(newHex, radix: 16));
      debugPrint('Selected color: ${newColor.toString()} (hex: #$newHex)');
      onColorChanged(newColor);
    }
  }
}
