import 'package:flutter/material.dart';

import 'package:awattackerapplier/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../models/rule.dart';
import '../providers/rule_provider.dart';

class TagStatsCard extends StatelessWidget {
  const TagStatsCard({
    super.key,
    required this.rules,
  });
  final List<Rule> rules;

  Set<String> _getAllTags() {
    final tagSet = <String>{};
    for (final rule in rules) {
      tagSet.addAll(rule.tags);
    }

    return tagSet;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }

    final provider = context.watch<RuleProvider>();
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: Colors.grey.shade200),
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
                  // ignore: no-magic-number
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.tagStats,
                  style: const TextStyle(
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
                    label: l10n.tagStatsCount,
                    valueColor: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.bookmark_outline,
                    value: '${rules.where((r) => r.tags.isNotEmpty).length}',
                    label: l10n.tagStatsRules,
                    valueColor: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_activity_outlined,
                    value: '${provider.activeTags.length}',
                    label: l10n.tagStatsActive,
                    valueColor: provider.activeTags.isNotEmpty
                        ? theme.colorScheme.primary
                        : Colors.grey.shade800,
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
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              // ignore: no-magic-number
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              // ignore: no-magic-number
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
