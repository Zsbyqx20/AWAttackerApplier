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
  final ValueChanged<TextAlign> onHorizontalAlignChanged;
  final ValueChanged<TextAlign> onVerticalAlignChanged;
  final ValueChanged<String> onPaddingChanged;

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
    required this.onHorizontalAlignChanged,
    required this.onVerticalAlignChanged,
    required this.onPaddingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 位置和大小
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

        // 颜色设置
        Row(
          children: [
            Expanded(
              child: _buildStyleSection(
                '背景颜色',
                ColorPickerField(
                  label: '',
                  color: style.backgroundColor,
                  onColorChanged: (color) {
                    debugPrint('Background color changed: ${color.toString()}');
                    onBackgroundColorChanged(color);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStyleSection(
                '文字颜色',
                ColorPickerField(
                  label: '',
                  color: style.textColor,
                  onColorChanged: (color) {
                    debugPrint('Text color changed: ${color.toString()}');
                    onTextColorChanged(color);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 文本内容
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextInputField(
              label: '文本内容',
              hint: '请输入显示的文本内容',
              controller: textController,
              onChanged: onTextChanged,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 字体大小
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

        // 文本边距
        _buildStyleSection(
          '文本边距',
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  '左',
                  style.padding.left.toString(),
                  (value) => onPaddingChanged('left:$value'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNumberField(
                  '上',
                  style.padding.top.toString(),
                  (value) => onPaddingChanged('top:$value'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNumberField(
                  '右',
                  style.padding.right.toString(),
                  (value) => onPaddingChanged('right:$value'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNumberField(
                  '下',
                  style.padding.bottom.toString(),
                  (value) => onPaddingChanged('bottom:$value'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 文字对齐
        _buildStyleSection(
          '文字对齐',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      '水平：',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: SegmentedButton<TextAlign>(
                      segments: const [
                        ButtonSegment<TextAlign>(
                          value: TextAlign.left,
                          icon: Icon(Icons.format_align_left),
                          label: Text('左'),
                        ),
                        ButtonSegment<TextAlign>(
                          value: TextAlign.center,
                          icon: Icon(Icons.format_align_center),
                          label: Text('中'),
                        ),
                        ButtonSegment<TextAlign>(
                          value: TextAlign.right,
                          icon: Icon(Icons.format_align_right),
                          label: Text('右'),
                        ),
                      ],
                      selected: {style.horizontalAlign},
                      onSelectionChanged: (Set<TextAlign> selected) {
                        if (selected.isNotEmpty) {
                          onHorizontalAlignChanged(selected.first);
                        }
                      },
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      '垂直：',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: SegmentedButton<TextAlign>(
                      segments: const [
                        ButtonSegment<TextAlign>(
                          value: TextAlign.start,
                          icon: Icon(Icons.vertical_align_top),
                          label: Text('上'),
                        ),
                        ButtonSegment<TextAlign>(
                          value: TextAlign.center,
                          icon: Icon(Icons.vertical_align_center),
                          label: Text('中'),
                        ),
                        ButtonSegment<TextAlign>(
                          value: TextAlign.end,
                          icon: Icon(Icons.vertical_align_bottom),
                          label: Text('下'),
                        ),
                      ],
                      selected: {style.verticalAlign},
                      onSelectionChanged: (Set<TextAlign> selected) {
                        if (selected.isNotEmpty) {
                          onVerticalAlignChanged(selected.first);
                        }
                      },
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // UI自动化代码
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextInputField(
              label: 'UI Automator代码',
              hint: '请输入UI自动化代码',
              controller: uiAutomatorCodeController,
              maxLines: 3,
              onChanged: onUiAutomatorCodeChanged,
            ),
          ],
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

  TextAlign _getHorizontalAlign(TextAlign align) {
    switch (align) {
      case TextAlign.left:
      case TextAlign.start:
        return TextAlign.left;
      case TextAlign.right:
      case TextAlign.end:
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  TextAlign _getVerticalAlign(TextAlign align) {
    switch (align) {
      case TextAlign.start:
        return TextAlign.start;
      case TextAlign.end:
        return TextAlign.end;
      default:
        return TextAlign.center;
    }
  }
}
