import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _showColorPicker(context),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showColorPicker(BuildContext context) async {
    final String currentHex =
        '${color.r.toInt().toRadixString(16).padLeft(2, '0')}'
        '${color.g.toInt().toRadixString(16).padLeft(2, '0')}'
        '${color.b.toInt().toRadixString(16).padLeft(2, '0')}';
    final TextEditingController hexController =
        TextEditingController(text: currentHex);
    Color previewColor = color;

    final String? newHex = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            label,
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
                  labelText: 'HEX颜色值',
                  hintText: '例如：FF0000',
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
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (value) {
                  if (value.length == 6) {
                    try {
                      final newColor = Color(int.parse('FF$value', radix: 16));
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
                '取消',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final hex = hexController.text;
                if (hex.length == 6) {
                  try {
                    final newColor = Color(int.parse('FF$hex', radix: 16));
                    Navigator.of(context).pop(hex);
                  } catch (e) {
                    // 忽略无效的颜色值
                  }
                }
              },
              child: Text(
                '确定',
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
      final newColor = Color(int.parse('FF$newHex', radix: 16));
      onColorChanged(newColor);
    }
  }
}
