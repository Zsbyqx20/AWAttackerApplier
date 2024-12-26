import 'package:flutter/material.dart';
import '../models/overlay_style.dart';
import 'text_input_field.dart';
import 'color_picker_field.dart';

class StyleEditor extends StatelessWidget {
  final OverlayStyle style;
  final TextEditingController textController;
  final TextEditingController uiAutomatorCodeController;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<String> onPositionChanged;
  final ValueChanged<Color> onBackgroundColorChanged;
  final ValueChanged<Color> onTextColorChanged;
  final ValueChanged<String> onUiAutomatorCodeChanged;

  const StyleEditor({
    super.key,
    required this.style,
    required this.textController,
    required this.uiAutomatorCodeController,
    required this.onTextChanged,
    required this.onFontSizeChanged,
    required this.onPositionChanged,
    required this.onBackgroundColorChanged,
    required this.onTextColorChanged,
    required this.onUiAutomatorCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStyleSection(
          '文本内容',
          TextInputField(
            label: '',
            hint: '请输入显示的文本内容',
            controller: textController,
            onChanged: onTextChanged,
          ),
        ),
        const SizedBox(height: 16),
        _buildStyleSection(
          '字体大小',
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: style.fontSize,
                  min: 12,
                  max: 32,
                  divisions: 20,
                  label: style.fontSize.round().toString(),
                  onChanged: onFontSizeChanged,
                ),
              ),
              Container(
                width: 48,
                alignment: Alignment.center,
                child: Text(
                  style.fontSize.round().toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStyleSection(
          '位置和大小',
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      'X',
                      style.x.toString(),
                      (value) => onPositionChanged('x:$value'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberField(
                      'Y',
                      style.y.toString(),
                      (value) => onPositionChanged('y:$value'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      '宽度',
                      style.width.toString(),
                      (value) => onPositionChanged('width:$value'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberField(
                      '高度',
                      style.height.toString(),
                      (value) => onPositionChanged('height:$value'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStyleSection(
          '颜色设置',
          Row(
            children: [
              Expanded(
                child: ColorPickerField(
                  label: '背景颜色',
                  color: style.backgroundColor,
                  onColorChanged: onBackgroundColorChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ColorPickerField(
                  label: '文字颜色',
                  color: style.textColor,
                  onColorChanged: onTextColorChanged,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStyleSection(
          'UI自动化代码',
          TextInputField(
            label: '',
            hint: '请输入UI自动化代码',
            controller: uiAutomatorCodeController,
            maxLines: 3,
            onChanged: onUiAutomatorCodeChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildStyleSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildNumberField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
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
        TextField(
          controller: TextEditingController(text: value),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: Colors.blue,
                width: 1.5,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
