import 'package:flutter/material.dart';

import 'package:awattackerapplier/l10n/app_localizations.dart';
import '../models/rule.dart';
import '../models/rule_merge_result.dart';
import '../utils/rule_field_validator.dart';
import '../utils/rule_merger.dart';

class RuleImportPreviewDialog extends StatelessWidget {
  const RuleImportPreviewDialog._({
    required this.rules,
    required this.existingRules,
  });
  static const double _iconSize = 48.0;
  static const double _iconInnerSize = 24.0;
  static const double _dialogPadding = 24.0;
  static const double _dialogRadius = 16.0;
  static const double _iconRadius = 12.0;
  static const double _buttonRadius = 8.0;
  static const double _titleFontSize = 18.0;
  static const double _textFontSize = 14.0;
  static const double _smallTextFontSize = 12.0;
  static const double _buttonPadding = 12.0;
  static const double _maxWidth = 500.0;
  static const double _maxHeight = 600.0;
  static const int _iconAlpha = 26;

  /// 显示导入预览对话框
  static Future<List<Rule>?> show({
    required BuildContext context,
    required List<Rule> rules,
    required List<Rule> existingRules,
  }) {
    return showDialog<List<Rule>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RuleImportPreviewDialog._(
        rules: rules,
        existingRules: existingRules,
      ),
    );
  }

  final List<Rule> rules;
  final List<Rule> existingRules;

  RuleMergeResult _checkConflict(Rule rule) {
    // 首先验证活动名格式
    final activityNameResult =
        RuleFieldValidator.validateActivityName(rule.activityName);
    if (!activityNameResult.isValid) {
      return RuleMergeResult.conflict(
        errorMessage: '${rule.activityName} ${activityNameResult.errorMessage}',
      );
    }

    for (final existingRule in existingRules) {
      final result = RuleMerger.checkConflict(existingRule, rule);
      if (result.isConflict || result.isMergeable) {
        return result;
      }
    }

    return RuleMergeResult.success(rule);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }
    // 初始化时只选择没有冲突的规则
    final initialRules = rules.where((rule) {
      final result = _checkConflict(rule);

      return !result.isConflict;
    }).toList();
    final selectedRules = ValueNotifier<List<Rule>>(initialRules);

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(_dialogRadius)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _maxWidth,
          maxHeight: _maxHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(_dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 图标
              Container(
                width: _iconSize,
                height: _iconSize,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(_iconAlpha),
                  borderRadius:
                      const BorderRadius.all(Radius.circular(_iconRadius)),
                ),
                child: Icon(
                  Icons.rule_folder,
                  color: theme.colorScheme.primary,
                  size: _iconInnerSize,
                ),
              ),
              const SizedBox(height: 16),
              // 标题和统计
              Text(
                l10n.ruleImportPreviewDialogTitle,
                style: const TextStyle(
                  fontSize: _titleFontSize,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<List<Rule>>(
                valueListenable: selectedRules,
                builder: (context, selected, _) => Text(
                  l10n.ruleImportPreviewDialogRuleImportStatus(
                    rules.length,
                    selected.length,
                  ),
                  style: TextStyle(
                    fontSize: _textFontSize,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // 全选按钮
              ValueListenableBuilder<List<Rule>>(
                valueListenable: selectedRules,
                builder: (context, selected, _) {
                  final selectableRules = rules.where((rule) {
                    final result = _checkConflict(rule);

                    return !result.isConflict;
                  }).toList();
                  // 只有当选中的规则数量等于可选规则数量，且可选规则数量大于0时，才显示为全选状态
                  final isAllSelected = selectableRules.isNotEmpty &&
                      selected.length == selectableRules.length;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.all(
                          Radius.circular(_buttonRadius)),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        if (isAllSelected) {
                          selectedRules.value = [];
                        } else {
                          // 只选择没有冲突的规则
                          final selectableRules = rules.where((rule) {
                            final result = _checkConflict(rule);

                            return !result.isConflict;
                          }).toList();
                          selectedRules.value = selectableRules;
                        }
                      },
                      icon: Icon(
                        isAllSelected ? Icons.select_all : Icons.deselect,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        isAllSelected
                            ? l10n.ruleImportPreviewDialogCancelAll
                            : l10n.ruleImportPreviewDialogSelectAll,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.all(_buttonPadding),
                        shape: RoundedRectangleBorder(
                          borderRadius: const BorderRadius.all(
                              Radius.circular(_buttonRadius)),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              // 规则列表
              Flexible(
                child: ValueListenableBuilder<List<Rule>>(
                  valueListenable: selectedRules,
                  builder: (context, selected, _) => ListView.builder(
                    itemCount: rules.length,
                    itemBuilder: (context, index) {
                      final rule = rules[index];
                      final isSelected = selected.contains(rule);
                      final mergeResult = _checkConflict(rule);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(12)),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: InkWell(
                                onTap: () {
                                  final mergeResult = _checkConflict(rule);
                                  if (mergeResult.isConflict) return;

                                  final newSelected = List<Rule>.of(selected);
                                  if (isSelected) {
                                    newSelected.remove(rule);
                                  } else {
                                    newSelected.add(rule);
                                  }
                                  selectedRules.value = newSelected;
                                },
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: mergeResult.isConflict
                                            ? null
                                            : (value) {
                                                final newSelected =
                                                    List<Rule>.of(selected);
                                                if (value == true) {
                                                  newSelected.add(rule);
                                                } else {
                                                  newSelected.remove(rule);
                                                }
                                                selectedRules.value =
                                                    newSelected;
                                              },
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    rule.name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (mergeResult.isConflict)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: theme
                                                          .colorScheme.error
                                                          .withValues(
                                                              // ignore: no-magic-number
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                              Radius.circular(
                                                                  6)),
                                                    ),
                                                    child: Text(
                                                      mergeResult.errorMessage
                                                                  ?.contains(l10n
                                                                      .ruleImportPreviewDialogImportActivityName) ==
                                                              true
                                                          ? l10n
                                                              .ruleImportPreviewDialogActivityNameInvalidHint
                                                          : l10n
                                                              .ruleImportPreviewDialogConflict,
                                                      style: TextStyle(
                                                        fontSize:
                                                            _smallTextFontSize,
                                                        color: theme
                                                            .colorScheme.error,
                                                      ),
                                                    ),
                                                  )
                                                else if (mergeResult
                                                    .isMergeable)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: theme
                                                          .colorScheme.secondary
                                                          .withValues(
                                                              // ignore: no-magic-number
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                              Radius.circular(
                                                                  6)),
                                                    ),
                                                    child: Text(
                                                      l10n.ruleImportPreviewDialogImportMergeable,
                                                      style: TextStyle(
                                                        fontSize:
                                                            _smallTextFontSize,
                                                        color: theme.colorScheme
                                                            .secondary,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius:
                                                    const BorderRadius.all(
                                                        Radius.circular(8)),
                                                border: Border.all(
                                                    color:
                                                        Colors.grey.shade200),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.android_outlined,
                                                        // ignore: no-magic-number
                                                        size: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          '${rule.packageName}/${rule.activityName}',
                                                          style: TextStyle(
                                                            fontSize:
                                                                _smallTextFontSize,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (rule.tags.isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    Wrap(
                                                      // ignore: no-magic-number
                                                      spacing: 4,
                                                      // ignore: no-magic-number
                                                      runSpacing: 4,
                                                      children: rule.tags
                                                          .map(
                                                            (tag) => Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: theme
                                                                    .colorScheme
                                                                    .primary
                                                                    .withValues(
                                                                        alpha:
                                                                            // ignore: no-magic-number
                                                                            0.1),
                                                                borderRadius:
                                                                    const BorderRadius
                                                                        .all(
                                                                        Radius.circular(
                                                                            4)),
                                                              ),
                                                              child: Text(
                                                                tag,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      _smallTextFontSize,
                                                                  color: theme
                                                                      .colorScheme
                                                                      .primary,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                          .toList(),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (mergeResult.isConflict)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: (mergeResult.errorMessage?.contains(l10n
                                                  .ruleImportPreviewDialogImportActivityName) ==
                                              true
                                          ? Colors.orange
                                          : theme.colorScheme.error)
                                      // ignore: no-magic-number
                                      .withValues(alpha: 0.1),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(8)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      mergeResult.errorMessage?.contains(l10n
                                                  .ruleImportPreviewDialogImportActivityName) ==
                                              true
                                          ? Icons.warning_amber_outlined
                                          : Icons.error_outline,
                                      // ignore: no-magic-number
                                      size: 16,
                                      color: mergeResult.errorMessage?.contains(
                                                  l10n.ruleImportPreviewDialogImportActivityName) ==
                                              true
                                          ? Colors.orange
                                          : theme.colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        mergeResult.errorMessage ??
                                            l10n.ruleImportPreviewDialogImportUnknownError,
                                        style: TextStyle(
                                          // ignore: no-magic-number
                                          fontSize: 13,
                                          color: mergeResult.errorMessage
                                                      ?.contains(l10n
                                                          .ruleImportPreviewDialogImportActivityName) ==
                                                  true
                                              ? Colors.orange
                                              : theme.colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        l10n.dialogDefaultCancel,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ValueListenableBuilder<List<Rule>>(
                      valueListenable: selectedRules,
                      builder: (context, selected, _) => ElevatedButton(
                        onPressed: selected.isEmpty
                            ? null
                            : () => Navigator.of(context).pop(selected),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        child: Text(
                          l10n.ruleImportPreviewDialogImport,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
