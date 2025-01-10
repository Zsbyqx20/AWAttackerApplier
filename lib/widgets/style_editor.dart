import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/overlay_style.dart';
import 'color_picker_field.dart';
import 'text_input_field.dart';

class StyleEditor extends StatelessWidget {
  final OverlayStyle style;
  final TextEditingController textController;
  final TextEditingController uiAutomatorCodeController;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<String> onPositionChanged;
  final ValueChanged<Color> onBackgroundColorChanged;
  final ValueChanged<Color> onTextColorChanged;
  final ValueChanged<TextAlign> onHorizontalAlignChanged;
  final ValueChanged<TextAlign> onVerticalAlignChanged;
  final ValueChanged<String> onUiAutomatorCodeChanged;
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
    required this.onHorizontalAlignChanged,
    required this.onVerticalAlignChanged,
    required this.onUiAutomatorCodeChanged,
    required this.onPaddingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextInputField(
          label: l10n.text,
          hint: l10n.textHint,
          controller: textController,
          onChanged: onTextChanged,
        ),
        const SizedBox(height: 16),
        _buildFontSizeField(context),
        const SizedBox(height: 16),
        _buildColorPickers(context),
        const SizedBox(height: 16),
        _buildPositionFields(context),
        const SizedBox(height: 16),
        _buildAlignmentFields(context),
        const SizedBox(height: 16),
        _buildPaddingFields(context),
        const SizedBox(height: 16),
        TextInputField(
          label: l10n.uiAutomatorCode,
          hint: l10n.uiAutomatorCodeHint,
          controller: uiAutomatorCodeController,
          onChanged: onUiAutomatorCodeChanged,
        ),
      ],
    );
  }

  Widget _buildFontSizeField(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.fontSize}: ${style.fontSize.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Slider(
          value: style.fontSize,
          min: 8,
          max: 32,
          divisions: 48,
          label: style.fontSize.toStringAsFixed(1),
          onChanged: onFontSizeChanged,
        ),
      ],
    );
  }

  Widget _buildColorPickers(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.backgroundColor,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ColorPickerField(
                label: l10n.backgroundColor,
                color: style.backgroundColor,
                onColorChanged: onBackgroundColorChanged,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.textColor,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ColorPickerField(
                label: l10n.textColor,
                color: style.textColor,
                onColorChanged: onTextColorChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPositionFields(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.position,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                'x',
                style.x,
                (value) => onPositionChanged('x:$value'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNumberField(
                'y',
                style.y,
                (value) => onPositionChanged('y:$value'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.size,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                l10n.width,
                style.width,
                (value) => onPositionChanged('width:$value'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNumberField(
                l10n.height,
                style.height,
                (value) => onPositionChanged('height:$value'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlignmentFields(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.alignment,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildAlignmentSelector(
                context,
                style.horizontalAlign,
                onHorizontalAlignChanged,
                [TextAlign.left, TextAlign.center, TextAlign.right],
                const [
                  Icons.format_align_left,
                  Icons.format_align_center,
                  Icons.format_align_right,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAlignmentSelector(
                context,
                style.verticalAlign,
                onVerticalAlignChanged,
                [TextAlign.start, TextAlign.center, TextAlign.end],
                const [
                  Icons.align_vertical_top,
                  Icons.align_vertical_center,
                  Icons.align_vertical_bottom,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaddingFields(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.padding,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                'L',
                style.padding.left,
                (value) => onPaddingChanged('left:$value'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNumberField(
                'T',
                style.padding.top,
                (value) => onPaddingChanged('top:$value'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNumberField(
                'R',
                style.padding.right,
                (value) => onPaddingChanged('right:$value'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNumberField(
                'B',
                style.padding.bottom,
                (value) => onPaddingChanged('bottom:$value'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberField(
    String label,
    double value,
    ValueChanged<String> onChanged,
  ) {
    return TextField(
      controller: TextEditingController(text: value.toString()),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      style: const TextStyle(fontSize: 14),
      onChanged: onChanged,
    );
  }

  Widget _buildAlignmentSelector(
    BuildContext context,
    TextAlign currentAlign,
    ValueChanged<TextAlign> onChanged,
    List<TextAlign> alignments,
    List<IconData> icons,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(
          alignments.length,
          (index) => Expanded(
            child: InkWell(
              onTap: () => onChanged(alignments[index]),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: currentAlign == alignments[index]
                      ? Theme.of(context).colorScheme.primary.withAlpha(26)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  border: currentAlign == alignments[index]
                      ? Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(51),
                        )
                      : null,
                ),
                child: Icon(
                  icons[index],
                  color: currentAlign == alignments[index]
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
