import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/rule_merge_result.dart';

class RuleImportResultDialog extends StatelessWidget {
  const RuleImportResultDialog._({
    required this.mergeResults,
  });

  /// 导入结果的文字大小
  static const double _textSize = 12;

  /// decoration 透明度
  static const double _decorationAlpha = 0.1;

  /// 显示导入结果对话框
  static Future<void> show({
    required BuildContext context,
    required List<RuleMergeResult> mergeResults,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          RuleImportResultDialog._(mergeResults: mergeResults),
    );
  }

  final List<RuleMergeResult> mergeResults;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }
    final totalCount = mergeResults.length;
    final successCount = mergeResults.where((r) => r.isSuccess).length;
    final mergeableCount = mergeResults.where((r) => r.isMergeable).length;
    final conflictCount = mergeResults.where((r) => r.isConflict).length;
    final hasErrors = conflictCount > 0;

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              // ignore: no-magic-number
              width: 48,
              // ignore: no-magic-number
              height: 48,
              decoration: BoxDecoration(
                color: (hasErrors
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary)
                    // ignore: no-magic-number
                    .withAlpha(26),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Icon(
                hasErrors ? Icons.error_outline : Icons.check_circle_outline,
                color: hasErrors
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                // ignore: no-magic-number
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasErrors ? l10n.importError : l10n.importSuccess,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                  child: Text(
                    l10n.ruleImportResultDetail(totalCount),
                    style: TextStyle(
                      fontSize: _textSize,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                if (successCount > 0)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: _decorationAlpha,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                    child: Text(
                      l10n.ruleImportResultSuccess(successCount),
                      style: TextStyle(
                        fontSize: _textSize,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                if (mergeableCount > 0)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(
                        alpha: _decorationAlpha,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                    child: Text(
                      l10n.ruleImportResultMergeable(mergeableCount),
                      style: TextStyle(
                        fontSize: _textSize,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                if (conflictCount > 0)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(
                        alpha: _decorationAlpha,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                    child: Text(
                      l10n.ruleImportResultConflict(conflictCount),
                      style: TextStyle(
                        fontSize: _textSize,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasErrors) ...[
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: mergeResults
                        .where((r) => r.isConflict)
                        .map((result) => Text(
                              result.errorMessage ?? l10n.unknown,
                              style: TextStyle(
                                fontSize: _textSize,
                                color: Colors.grey.shade700,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasErrors
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                child: Text(
                  l10n.dialogDefaultConfirm,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
