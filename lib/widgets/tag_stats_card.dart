import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../models/rule.dart';
import '../providers/rule_provider.dart';

class TagStatsCard extends StatelessWidget {
  final List<Rule> rules;

  const TagStatsCard({
    super.key,
    required this.rules,
  });

  Set<String> _getAllTags() {
    final tagSet = <String>{};
    for (final rule in rules) {
      tagSet.addAll(rule.tags);
    }
    return tagSet;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RuleProvider>();
    final theme = Theme.of(context);

    return Card(
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
              children: [
                Icon(
                  Icons.sell_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '标签统计',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_offer_outlined,
                    value: '${_getAllTags().length}',
                    label: '标签数',
                    valueColor: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.bookmark_outline,
                    value: '${rules.where((r) => r.tags.isNotEmpty).length}',
                    label: '标记规则',
                    valueColor: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_activity_outlined,
                    value: '${provider.activeTags.length}',
                    label: '已激活',
                    valueColor: provider.activeTags.isNotEmpty
                        ? theme.colorScheme.primary
                        : Colors.grey[800],
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
