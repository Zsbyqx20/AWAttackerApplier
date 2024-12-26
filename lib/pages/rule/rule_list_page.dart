import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/rule.dart';
import '../../providers/rule_provider.dart';
import '../../widgets/rule_stats_card.dart';
import '../../widgets/rule_card.dart';
import '../../widgets/empty_rule_list.dart';
import 'rule_edit_page.dart';

class RuleListPage extends StatefulWidget {
  const RuleListPage({super.key});

  @override
  State<RuleListPage> createState() => _RuleListPageState();
}

class _RuleListPageState extends State<RuleListPage> {
  @override
  void initState() {
    super.initState();
    // 在初始化时加载规则列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RuleProvider>().loadRules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RuleProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: RuleStatsCard(
                    rules: provider.rules,
                    onAddRule: () => _navigateToEditPage(context),
                  ),
                ),
              ),
              if (provider.rules.isEmpty)
                const SliverFillRemaining(
                  child: EmptyRuleList(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => RuleCard(
                        rule: provider.rules[index],
                        onTap: () => _navigateToEditPage(
                          context,
                          rule: provider.rules[index],
                        ),
                      ),
                      childCount: provider.rules.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToEditPage(BuildContext context, {Rule? rule}) async {
    final provider = context.read<RuleProvider>();
    final result = await Navigator.of(context).push<Rule>(
      MaterialPageRoute(
        builder: (context) => RuleEditPage(rule: rule),
      ),
    );

    if (result != null && mounted) {
      if (rule != null) {
        provider.updateRule(result);
      } else {
        provider.addRule(result);
      }
    }
  }
}
