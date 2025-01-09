import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/overlay_style.dart';
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
        _buildFontSizeSlider(context),
        const SizedBox(height: 16),
        _buildColorPickers(context),
        const SizedBox(height: 16),
        _buildPositionFields(context),
        const SizedBox(height: 16),
        _buildAlignmentControls(context),
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

  Widget _buildFontSizeSlider(BuildContext context) {
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
              GestureDetector(
                onTap: () => _showColorPicker(
                  context,
                  style.backgroundColor,
                  onBackgroundColorChanged,
                  l10n.backgroundColor,
                ),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: style.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                ),
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
              GestureDetector(
                onTap: () => _showColorPicker(
                  context,
                  style.textColor,
                  onTextColorChanged,
                  l10n.textColor,
                ),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: style.textColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                ),
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

  Widget _buildAlignmentControls(BuildContext context) {
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

  Future<void> _showColorPicker(
    BuildContext context,
    Color initialColor,
    ValueChanged<Color> onColorChanged,
    String title,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: onColorChanged,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(initialColor),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (result != null) {
      onColorChanged(result);
    }
  }
}

class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final double pickerAreaHeightPercent;

  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.pickerAreaHeightPercent = 1.0,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late HSVColor _currentHsvColor;

  @override
  void initState() {
    super.initState();
    _currentHsvColor = HSVColor.fromColor(widget.pickerColor);
  }

  void _onColorChanged(HSVColor color) {
    setState(() => _currentHsvColor = color);
    widget.onColorChanged(_currentHsvColor.toColor());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 280,
          height: 280 * widget.pickerAreaHeightPercent,
          child: CustomPaint(
            painter: _ColorPickerPainter(
              _currentHsvColor,
              (color) => _onColorChanged(color),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 12,
          child: CustomPaint(
            painter: _HueSliderPainter(
              _currentHsvColor.hue,
              (hue) => _onColorChanged(
                _currentHsvColor.withHue(hue),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: _currentHsvColor.toColor(),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
      ],
    );
  }
}

class _ColorPickerPainter extends CustomPainter {
  final HSVColor color;
  final ValueChanged<HSVColor> onColorChanged;

  _ColorPickerPainter(this.color, this.onColorChanged);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        HSVColor.fromAHSV(1.0, color.hue, 0.0, 1.0).toColor(),
        HSVColor.fromAHSV(1.0, color.hue, 1.0, 1.0).toColor(),
      ],
    );
    canvas.drawRect(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );

    final valueGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white,
        Colors.black,
      ],
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = valueGradient.createShader(rect)
        ..blendMode = BlendMode.multiply,
    );

    final currentPoint = Offset(
      size.width * color.saturation,
      size.height * (1 - color.value),
    );
    canvas.drawCircle(
      currentPoint,
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ColorPickerPainter oldDelegate) =>
      color != oldDelegate.color;

  @override
  bool hitTest(Offset position) => true;
}

class _HueSliderPainter extends CustomPainter {
  final double hue;
  final ValueChanged<double> onHueChanged;

  _HueSliderPainter(this.hue, this.onHueChanged);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = List.generate(
      360,
      (index) => HSVColor.fromAHSV(1.0, index.toDouble(), 1.0, 1.0).toColor(),
    );
    final gradient = LinearGradient(colors: colors);
    canvas.drawRect(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );

    final currentPoint = Offset(size.width * (hue / 360), size.height / 2);
    canvas.drawCircle(
      currentPoint,
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_HueSliderPainter oldDelegate) => hue != oldDelegate.hue;

  @override
  bool hitTest(Offset position) => true;
}
