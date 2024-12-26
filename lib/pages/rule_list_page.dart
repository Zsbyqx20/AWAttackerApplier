import 'package:flutter/material.dart';
import '../models/rule.dart';
import '../pages/rule_edit_page.dart';
import '../services/storage_service.dart';

class RuleListPage extends StatefulWidget {
  const RuleListPage({super.key});

  @override
  State<RuleListPage> createState() => _RuleListPageState();
}

class _RuleListPageState extends State<RuleListPage> {
  final List<Rule> _rules = [];
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    final rules = await _storageService.loadRules();
    setState(() {
      _rules.clear();
      _rules.addAll(rules);
    });
  }

  Future<void> _saveRules() async {
    await _storageService.saveRules(_rules);
  }

  void _editRule(BuildContext context, Rule rule) async {
    final editedRule = await Navigator.of(context).push<Rule>(
      MaterialPageRoute(
        builder: (context) => RuleEditPage(rule: rule),
      ),
    );

    if (editedRule != null) {
      setState(() {
        final index = _rules.indexWhere((r) => r.id == editedRule.id);
        if (index != -1) {
          _rules[index] = editedRule;
        }
      });
      await _saveRules();
    }
  }

  void _addRule(BuildContext context) async {
    final newRule = await Navigator.of(context).push<Rule>(
      MaterialPageRoute(
        builder: (context) => const RuleEditPage(),
      ),
    );

    if (newRule != null) {
      setState(() {
        _rules.add(newRule);
      });
      await _saveRules();
    }
  }

  void _deleteRule(Rule rule) async {
    setState(() {
      _rules.removeWhere((r) => r.id == rule.id);
    });
    await _saveRules();
  }

  void _toggleRuleState(Rule rule) async {
    setState(() {
      final index = _rules.indexWhere((r) => r.id == rule.id);
      if (index != -1) {
        _rules[index] = rule.copyWith(isEnabled: !rule.isEnabled);
      }
    });
    await _saveRules();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 规则操作区域
            Card(
              elevation: 1,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '规则操作',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _addRule(context),
                        icon: const Icon(Icons.add),
                        label: const Text('添加规则'),
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          foregroundColor:
                              const WidgetStatePropertyAll<Color>(Colors.white),
                          elevation: const WidgetStatePropertyAll<double>(0),
                          padding:
                              const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                            EdgeInsets.symmetric(vertical: 12),
                          ),
                          shape: const WidgetStatePropertyAll<OutlinedBorder>(
                            RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.white
                                    .withAlpha(51); // 0.2 * 255 ≈ 51
                              }
                              if (states.contains(WidgetState.hovered)) {
                                return Colors.white
                                    .withAlpha(26); // 0.1 * 255 ≈ 26
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 规则列表区域
            if (_rules.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rule_folder_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无规则',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击上方按钮添加规则',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 1,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '规则列表',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            '共 ${_rules.length} 条规则',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._rules.map((rule) => Column(
                            children: [
                              _buildRuleItem(context, rule),
                              if (rule != _rules.last)
                                Divider(color: Colors.grey[200]),
                            ],
                          )),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, Rule rule) {
    // 计算最大宽度：屏幕宽度减去边距和状态标签的宽度
    final maxTextWidth = MediaQuery.of(context).size.width - 140;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：规则名称、悬浮窗数量和状态标签
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        rule.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 14,
                            color: Colors.purple[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${rule.overlayStyles.length}个悬浮窗',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 启用/禁用切换按钮
              Material(
                color: rule.isEnabled ? Colors.green[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: () => _toggleRuleState(rule),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          rule.isEnabled
                              ? Icons.check_circle_outline
                              : Icons.radio_button_unchecked,
                          size: 14,
                          color: rule.isEnabled
                              ? Colors.green[700]
                              : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rule.isEnabled ? '已启用' : '已停用',
                          style: TextStyle(
                            fontSize: 12,
                            color: rule.isEnabled
                                ? Colors.green[700]
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 第二行：包名
          Row(
            children: [
              Icon(
                Icons.android_outlined,
                size: 14,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxTextWidth),
                child: Text(
                  rule.packageName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // 第三行：活动名
          Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                size: 14,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxTextWidth),
                child: Text(
                  rule.activityName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 第四行：操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 编辑按钮
              Material(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: () => _editRule(context, rule),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '编辑',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 删除按钮
              Material(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: () => _deleteRule(rule),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '删除',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
