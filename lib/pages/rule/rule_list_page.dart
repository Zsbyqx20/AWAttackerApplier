import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../models/rule.dart';
import '../../models/rule_import.dart';
import '../../models/rule_merge_result.dart';
import '../../providers/rule_provider.dart';
import '../../widgets/rule_card.dart';
import '../../widgets/rule_import_preview_dialog.dart';
import '../../widgets/rule_import_result_dialog.dart';
import '../../widgets/rule_stats_card.dart';
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
    final l10n = AppLocalizations.of(context)!;

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
                Center(
                  child: Text(l10n.noRules),
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
                          child: SizedBox(
                            width: 140,
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
                              label: Text(l10n.addRule),
                            ),
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
                          child: SizedBox(
                            width: 140,
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
                              label: Text(l10n.importRules),
                            ),
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
                          child: SizedBox(
                            width: 140,
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
                              label: Text(l10n.exportRules),
                            ),
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
    final l10n = AppLocalizations.of(context)!;
    try {
      final jsonStr = await const MethodChannel(
              'com.mobilellm.awattackapplier/overlay_service')
          .invokeMethod<String>('openFile');

      if (jsonStr == null) {
        if (!mounted) return;
        await RuleImportResultDialog.show(
          context: context,
          mergeResults: [
            RuleMergeResult.conflict(errorMessage: l10n.importError)
          ],
        );
        return;
      }

      final ruleImport = RuleImport.fromJson(jsonStr);
      final rules = ruleImport.rules;

      if (rules.isEmpty) {
        if (!mounted) return;
        await RuleImportResultDialog.show(
          context: context,
          mergeResults: [RuleMergeResult.conflict(errorMessage: l10n.noRules)],
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
    final l10n = AppLocalizations.of(context)!;
    try {
      final rules = context.read<RuleProvider>().rules;
      if (rules.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noRules)),
        );
        return;
      }

      final jsonStr = RuleImport(
        version: RuleImport.currentVersion,
        rules: rules,
      ).toJson();

      final result = await const MethodChannel(
              'com.mobilellm.awattackapplier/overlay_service')
          .invokeMethod<bool>('saveFile', {
        'content': jsonStr,
        'fileName': 'rules.json',
      });

      if (!mounted) return;
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportSuccess)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importError)),
        );
      }

      setState(() {
        _isExpanded = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportErrorWithException(e.toString()))),
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
