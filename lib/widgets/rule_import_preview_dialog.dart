import 'package:flutter/material.dart';
import '../models/rule.dart';

class RuleImportPreviewDialog extends StatelessWidget {
  final List<Rule> rules;
  final List<Rule> existingRules;

  const RuleImportPreviewDialog._({
    super.key,
    required this.rules,
    required this.existingRules,
  });

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

  bool _hasConflict(Rule rule) {
    return existingRules.any(
      (r) =>
          r.packageName == rule.packageName &&
          r.activityName == rule.activityName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedRules = ValueNotifier<List<Rule>>(List.from(rules));

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.rule_folder,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              // 标题和统计
              Text(
                '导入预览',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<List<Rule>>(
                valueListenable: selectedRules,
                builder: (context, selected, _) => Text(
                  '共 ${rules.length} 条规则，已选择 ${selected.length} 条',
                  style: TextStyle(
                    fontSize: 14,
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
                  final isAllSelected = selected.length == rules.length;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        if (isAllSelected) {
                          selectedRules.value = [];
                        } else {
                          selectedRules.value = List.from(rules);
                        }
                      },
                      icon: Icon(
                        isAllSelected ? Icons.select_all : Icons.deselect,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        isAllSelected ? '取消全选' : '全选',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                      final hasConflict = _hasConflict(rule);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: InkWell(
                          onTap: () {
                            final newSelected = List<Rule>.from(selected);
                            if (isSelected) {
                              newSelected.remove(rule);
                            } else {
                              newSelected.add(rule);
                            }
                            selectedRules.value = newSelected;
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    final newSelected =
                                        List<Rule>.from(selected);
                                    if (value == true) {
                                      newSelected.add(rule);
                                    } else {
                                      newSelected.remove(rule);
                                    }
                                    selectedRules.value = newSelected;
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
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (hasConflict)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.error
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '冲突',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      theme.colorScheme.error,
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
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey[200]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.android_outlined,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    rule.packageName,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[700],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.apps_outlined,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    rule.activityName,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[700],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (rule.tags.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: rule.tags.map((tag) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                tag,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '导入所选 (${selected.length})',
                          style: const TextStyle(
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
