import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/rule.dart';
import '../../models/rule_merge_result.dart';
import '../../models/rule_import.dart';
import '../../providers/rule_provider.dart';
import '../../widgets/rule_import_preview_dialog.dart';
import '../../widgets/rule_import_result_dialog.dart';
import '../../widgets/rule_stats_card.dart';
import '../../widgets/rule_card.dart';
import 'rule_edit_page.dart';

class RuleListPage extends StatefulWidget {
  const RuleListPage({super.key});

  @override
  State<RuleListPage> createState() => _RuleListPageState();
}

class _RuleListPageState extends State<RuleListPage>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RuleProvider>().loadRules();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RuleProvider>(
      builder: (context, provider, child) {
        final rules = provider.rules;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RuleStatsCard(
                rules: rules,
              ),
              const SizedBox(height: 16),
              if (rules.isEmpty)
                const Center(
                  child: Text('没有规则'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rules.length,
                  itemBuilder: (context, index) {
                    final rule = rules[index];
                    return RuleCard(
                      rule: rule,
                      onTap: () => _handleEdit(rule),
                    );
                  },
                ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(right: 24, bottom: 24),
            child: Stack(
              alignment: Alignment.bottomRight,
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_isExpanded) ...[
                      ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeOutBack,
                          reverseCurve: Curves.easeInBack,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: FloatingActionButton.extended(
                            heroTag: 'add',
                            elevation: 4,
                            backgroundColor: const Color(0xFFE3F2FD),
                            foregroundColor: const Color(0xFF1565C0),
                            onPressed: () {
                              setState(() => _isExpanded = false);
                              _controller.reverse();
                              _handleAdd();
                            },
                            icon: const Icon(Icons.add_box),
                            label: const Text('添加规则'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeOutBack,
                          reverseCurve: Curves.easeInBack,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: FloatingActionButton.extended(
                            heroTag: 'import',
                            elevation: 4,
                            backgroundColor: const Color(0xFFE8EAF6),
                            foregroundColor: const Color(0xFF3949AB),
                            onPressed: () {
                              setState(() => _isExpanded = false);
                              _controller.reverse();
                              _handleImport();
                            },
                            icon: const Icon(Icons.file_open_outlined),
                            label: const Text('导入规则'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeOutBack,
                          reverseCurve: Curves.easeInBack,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: FloatingActionButton.extended(
                            heroTag: 'export',
                            elevation: 4,
                            backgroundColor: const Color(0xFFF3E5F5),
                            foregroundColor: const Color(0xFF6A1B9A),
                            onPressed: () {
                              setState(() => _isExpanded = false);
                              _controller.reverse();
                              _handleExport();
                            },
                            icon: const Icon(Icons.save_alt_outlined),
                            label: const Text('导出规则'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FloatingActionButton(
                      elevation: 6,
                      onPressed: () {
                        setState(() => _isExpanded = !_isExpanded);
                        if (_isExpanded) {
                          _controller.forward();
                        } else {
                          _controller.reverse();
                        }
                      },
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: _isExpanded ? 0.125 : 0,
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final ruleImport = RuleImport.fromJson(content);
      final rules = ruleImport.rules;

      if (rules.isEmpty) {
        if (!mounted) return;
        await RuleImportResultDialog.show(
          context: context,
          mergeResults: [RuleMergeResult.conflict(errorMessage: '没有找到可导入的规则')],
        );
        return;
      }

      if (!mounted) return;
      final selectedRules = await RuleImportPreviewDialog.show(
        context: context,
        rules: rules,
        existingRules: context.read<RuleProvider>().rules,
      );

      if (selectedRules == null || selectedRules.isEmpty) return;

      if (!mounted) return;
      final provider = context.read<RuleProvider>();
      final results = await provider.importRules(selectedRules);

      if (!mounted) return;
      await RuleImportResultDialog.show(
        context: context,
        mergeResults: results,
      );

      setState(() {
        _isExpanded = false;
      });
    } catch (e) {
      if (!mounted) return;
      await RuleImportResultDialog.show(
        context: context,
        mergeResults: [RuleMergeResult.conflict(errorMessage: e.toString())],
      );

      setState(() {
        _isExpanded = false;
      });
    }
  }

  Future<void> _handleExport() async {
    try {
      final rules = context.read<RuleProvider>().rules;
      if (rules.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有可导出的规则')),
        );
        return;
      }

      final json = jsonEncode(rules);
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '导出规则',
        fileName: 'rules.json',
      );

      if (result == null) return;

      final file = File(result);
      await file.writeAsString(json);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导出成功')),
      );

      setState(() {
        _isExpanded = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );

      setState(() {
        _isExpanded = false;
      });
    }
  }

  Future<void> _handleAdd() async {
    if (!mounted) return;
    final newRule = await Navigator.push<Rule>(
      context,
      MaterialPageRoute<Rule>(
        builder: (context) => const RuleEditPage(),
      ),
    );

    if (newRule != null && mounted) {
      await context.read<RuleProvider>().addRule(newRule);
    }
  }

  Future<void> _handleEdit(Rule rule) async {
    if (!mounted) return;
    final editedRule = await Navigator.push<Rule>(
      context,
      MaterialPageRoute<Rule>(
        builder: (context) => RuleEditPage(rule: rule),
      ),
    );

    if (editedRule != null && mounted) {
      await context.read<RuleProvider>().updateRule(editedRule);
    }
  }
}
