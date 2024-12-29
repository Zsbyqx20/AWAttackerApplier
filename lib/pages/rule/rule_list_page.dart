import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../models/rule.dart';
import '../../providers/rule_provider.dart';
import '../../widgets/rule_stats_card.dart';
import '../../widgets/rule_card.dart';
import '../../widgets/empty_rule_list.dart';
import 'rule_edit_page.dart';
import '../../widgets/rule_import_preview_dialog.dart';
import '../../widgets/rule_import_result_dialog.dart';
import '../../models/rule_import.dart';

class RuleListPage extends StatefulWidget {
  const RuleListPage({super.key});

  @override
  State<RuleListPage> createState() => _RuleListPageState();
}

class _RuleListPageState extends State<RuleListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;

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

  void _handleAddRule() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RuleEditPage(),
      ),
    );
  }

  void _handleEditRule(Rule rule) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RuleEditPage(rule: rule),
      ),
    );
  }

  Future<void> _handleImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || !mounted) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final ruleImport = await RuleImport.fromJson(content);

      if (!mounted) return;

      final selectedRules = await RuleImportPreviewDialog.show(
        context: context,
        rules: ruleImport.rules,
        existingRules: context.read<RuleProvider>().rules,
      );

      if (selectedRules == null || !mounted) return;

      final importResult = await context.read<RuleProvider>().importRules(
            RuleImport(
              version: RuleImport.currentVersion,
              rules: selectedRules,
            ).toJson(),
          );

      if (!mounted) return;

      await RuleImportResultDialog.show(
        context: context,
        result: importResult,
      );

      setState(() {
        _isExpanded = false;
      });
    } catch (e) {
      if (!mounted) return;

      await RuleImportResultDialog.show(
        context: context,
        result: RuleImportResult.failure(e.toString()),
      );

      setState(() {
        _isExpanded = false;
      });
    }
  }

  Future<void> _handleExport() async {
    try {
      final provider = context.read<RuleProvider>();
      final rules = provider.rules;
      final ruleImport = RuleImport(
        version: RuleImport.currentVersion,
        rules: rules,
      );
      final content = ruleImport.toJson();

      final result = await FilePicker.platform.saveFile(
        dialogTitle: '导出规则',
        fileName: 'rules.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || !mounted) return;

      final file = File(result);
      await file.writeAsString(content);

      setState(() {
        _isExpanded = false;
      });
    } catch (e) {
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导出失败'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );

      setState(() {
        _isExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RuleProvider>(
      builder: (context, provider, child) {
        final rules = provider.rules;
        final enabledCount = rules.where((r) => r.isEnabled).length;

        return Scaffold(
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
                      onTap: () => _handleEditRule(rule),
                    );
                  },
                ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isExpanded) ...[
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOut,
                  ),
                  child: FloatingActionButton.extended(
                    heroTag: 'add',
                    onPressed: () {
                      setState(() => _isExpanded = false);
                      _controller.reverse();
                      _handleAddRule();
                    },
                    icon: const Icon(Icons.add_box),
                    label: const Text('添加规则'),
                  ),
                ),
                const SizedBox(height: 8),
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOut,
                  ),
                  child: FloatingActionButton.extended(
                    heroTag: 'import',
                    onPressed: () {
                      setState(() => _isExpanded = false);
                      _controller.reverse();
                      _handleImport();
                    },
                    icon: const Icon(Icons.file_upload),
                    label: const Text('导入规则'),
                  ),
                ),
                const SizedBox(height: 8),
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOut,
                  ),
                  child: FloatingActionButton.extended(
                    heroTag: 'export',
                    onPressed: () {
                      setState(() => _isExpanded = false);
                      _controller.reverse();
                      _handleExport();
                    },
                    icon: const Icon(Icons.file_download),
                    label: const Text('导出规则'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              FloatingActionButton(
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
        );
      },
    );
  }
}
