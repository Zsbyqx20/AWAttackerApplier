import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/overlay_style.dart';
import 'color_picker_field.dart';
import 'text_input_field.dart';

class StyleEditor extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }

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
        FontSizeField(
            style: style,
            onFontSizeChanged: onFontSizeChanged,
            context: context),
        const SizedBox(height: 16),
        ColorPickers(
            style: style,
            onBackgroundColorChanged: onBackgroundColorChanged,
            onTextColorChanged: onTextColorChanged,
            context: context),
        const SizedBox(height: 16),
        PositionFields(
            style: style,
            onPositionChanged: onPositionChanged,
            context: context),
        const SizedBox(height: 16),
        AlignmentFields(
            style: style,
            onHorizontalAlignChanged: onHorizontalAlignChanged,
            onVerticalAlignChanged: onVerticalAlignChanged,
            context: context),
        const SizedBox(height: 16),
        PaddingFields(
            style: style, onPaddingChanged: onPaddingChanged, context: context),
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
}

class PaddingFields extends StatelessWidget {
  const PaddingFields({
    super.key,
    required this.style,
    required this.onPaddingChanged,
    required this.context,
  });

  final OverlayStyle style;
  final ValueChanged<String> onPaddingChanged;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.padding,
          style: TextStyle(
            // ignore: no-magic-number
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: NumberField(
                  label: 'L',
                  value: style.padding.left,
                  onChanged: (value) => onPaddingChanged('left:$value')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NumberField(
                  label: 'T',
                  value: style.padding.top,
                  onChanged: (value) => onPaddingChanged('top:$value')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NumberField(
                  label: 'R',
                  value: style.padding.right,
                  onChanged: (value) => onPaddingChanged('right:$value')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NumberField(
                  label: 'B',
                  value: style.padding.bottom,
                  onChanged: (value) => onPaddingChanged('bottom:$value')),
            ),
          ],
        ),
      ],
    );
  }
}

class AlignmentFields extends StatelessWidget {
  const AlignmentFields({
    super.key,
    required this.style,
    required this.onHorizontalAlignChanged,
    required this.onVerticalAlignChanged,
    required this.context,
  });

  final OverlayStyle style;
  final ValueChanged<TextAlign> onHorizontalAlignChanged;
  final ValueChanged<TextAlign> onVerticalAlignChanged;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.alignment,
          style: TextStyle(
            // ignore: no-magic-number
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AlignmentSelector(
                  context: context,
                  currentAlign: style.horizontalAlign,
                  onChanged: onHorizontalAlignChanged,
                  alignments: [
                    TextAlign.left,
                    TextAlign.center,
                    TextAlign.right
                  ],
                  icons: const [
                    Icons.format_align_left,
                    Icons.format_align_center,
                    Icons.format_align_right,
                  ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AlignmentSelector(
                  context: context,
                  currentAlign: style.verticalAlign,
                  onChanged: onVerticalAlignChanged,
                  alignments: [
                    TextAlign.start,
                    TextAlign.center,
                    TextAlign.end
                  ],
                  icons: const [
                    Icons.align_vertical_top,
                    Icons.align_vertical_center,
                    Icons.align_vertical_bottom,
                  ]),
            ),
          ],
        ),
      ],
    );
  }
}

class PositionFields extends StatelessWidget {
  const PositionFields({
    super.key,
    required this.style,
    required this.onPositionChanged,
    required this.context,
  });

  final OverlayStyle style;
  final ValueChanged<String> onPositionChanged;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.position,
          style: TextStyle(
            // ignore: no-magic-number
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: NumberField(
                  label: 'x',
                  value: style.x,
                  onChanged: (value) => onPositionChanged('x:$value')),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: NumberField(
                  label: 'y',
                  value: style.y,
                  onChanged: (value) => onPositionChanged('y:$value')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.size,
          style: TextStyle(
            // ignore: no-magic-number
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: NumberField(
                  label: l10n.width,
                  value: style.width,
                  onChanged: (value) => onPositionChanged('width:$value')),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: NumberField(
                  label: l10n.height,
                  value: style.height,
                  onChanged: (value) => onPositionChanged('height:$value')),
            ),
          ],
        ),
      ],
    );
  }
}

class ColorPickers extends StatelessWidget {
  const ColorPickers({
    super.key,
    required this.style,
    required this.onBackgroundColorChanged,
    required this.onTextColorChanged,
    required this.context,
  });

  final OverlayStyle style;
  final ValueChanged<Color> onBackgroundColorChanged;
  final ValueChanged<Color> onTextColorChanged;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.backgroundColor,
                style: TextStyle(
                  // ignore: no-magic-number
                  fontSize: 14,
                  color: Colors.grey.shade700,
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
                  // ignore: no-magic-number
                  fontSize: 14,
                  color: Colors.grey.shade700,
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
}

class FontSizeField extends StatelessWidget {
  const FontSizeField({
    super.key,
    required this.style,
    required this.onFontSizeChanged,
    required this.context,
  });

  final OverlayStyle style;
  final ValueChanged<double> onFontSizeChanged;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.fontSize}: ${style.fontSize.toStringAsFixed(1)}',
          style: TextStyle(
            // ignore: no-magic-number
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Slider(
          value: style.fontSize,
          // ignore: no-magic-number
          min: 8,
          // ignore: no-magic-number
          max: 32,
          // ignore: no-magic-number
          divisions: 48,
          label: style.fontSize.toStringAsFixed(1),
          onChanged: onFontSizeChanged,
        ),
      ],
    );
  }
}

class AlignmentSelector extends StatelessWidget {
  const AlignmentSelector({
    super.key,
    required this.context,
    required this.currentAlign,
    required this.onChanged,
    required this.alignments,
    required this.icons,
  });

  final BuildContext context;
  final TextAlign currentAlign;
  final ValueChanged<TextAlign> onChanged;
  final List<TextAlign> alignments;
  final List<IconData> icons;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        children: List.generate(
          alignments.length,
          (index) => Expanded(
            child: InkWell(
              onTap: () => onChanged(alignments[index]),
              child: Container(
                // ignore: no-magic-number
                height: 40,
                decoration: BoxDecoration(
                  color: currentAlign == alignments[index]
                      // ignore: no-magic-number
                      ? Theme.of(context).colorScheme.primary.withAlpha(26)
                      : null,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  border: currentAlign == alignments[index]
                      ? Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              // ignore: no-magic-number
                              .withAlpha(51),
                        )
                      : null,
                ),
                child: Icon(
                  icons[index],
                  color: currentAlign == alignments[index]
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade600,
                  // ignore: no-magic-number
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

class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value.toString()),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(8),
      ),
      style: const TextStyle(fontSize: 14),
      onChanged: onChanged,
    );
  }
}
