import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog._({
    required this.title,
    required this.content,
    this.cancelText,
    this.confirmText,
    this.confirmColor,
    this.icon,
  }) : onConfirm = _noOp;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelText,
    this.confirmText,
    required this.onConfirm,
    this.confirmColor,
    this.icon,
  });
  static const double _iconSize = 48.0;
  static const double _iconInnerSize = 24.0;
  static const double _dialogPadding = 24.0;
  static const double _dialogRadius = 16.0;
  static const double _iconRadius = 12.0;
  static const double _buttonRadius = 8.0;
  static const double _titleFontSize = 18.0;
  static const double _textFontSize = 14.0;
  static const double _spacing = 16.0;
  static const double _smallSpacing = 8.0;
  static const double _buttonPadding = 12.0;
  static const int _iconAlpha = 26;

  /// 显示确认对话框
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String? cancelText,
    String? confirmText,
    Color? confirmColor,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog._(
        title: title,
        content: content,
        cancelText: cancelText,
        confirmText: confirmText,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
  }

  // ignore: no-empty-block
  static void _noOp() {}
  final String title;
  final String content;
  final String? cancelText;
  final String? confirmText;
  final VoidCallback onConfirm;
  final Color? confirmColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(_dialogRadius)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_dialogPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: _iconSize,
                height: _iconSize,
                decoration: BoxDecoration(
                  color: (confirmColor ?? theme.colorScheme.error)
                      .withAlpha(_iconAlpha),
                  borderRadius:
                      const BorderRadius.all(Radius.circular(_iconRadius)),
                ),
                child: Icon(
                  icon,
                  color: confirmColor ?? theme.colorScheme.error,
                  size: _iconInnerSize,
                ),
              ),
              const SizedBox(height: _spacing),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: _titleFontSize,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _smallSpacing),
            Text(
              content,
              style: TextStyle(
                fontSize: _textFontSize,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _spacing),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: _buttonPadding),
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.all(
                            Radius.circular(_buttonRadius)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      cancelText ?? l10n.dialogDefaultCancel,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _buttonPadding),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor ?? theme.colorScheme.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(vertical: _buttonPadding),
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.all(
                            Radius.circular(_buttonRadius)),
                      ),
                    ),
                    child: Text(
                      confirmText ?? l10n.dialogDefaultConfirm,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
