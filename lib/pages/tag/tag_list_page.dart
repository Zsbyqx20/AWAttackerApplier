import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:awattackerapplier/l10n/app_localizations.dart';
import '../../providers/rule_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/tag_stats_card.dart';

class TagListPage extends StatefulWidget {
  const TagListPage({super.key});

  @override
  State<TagListPage> createState() => _TagListPageState();
}

class _TagListPageState extends State<TagListPage> {
  void _handleTagActivation(BuildContext context, RuleProvider provider,
      String tag, bool active) async {
    if (active) {
      final l10n = AppLocalizations.of(context);
      if (l10n == null) {
        debugPrint('Error: AppLocalizations not found');

        return;
      }
      final affectedRules = provider.rules.where((r) => r.tags.contains(tag));
      final confirmed = await ConfirmDialog.show(
        context: context,
        title: l10n.activateTag,
        content: l10n.activateTagConfirm(tag, affectedRules.length),
        confirmText: l10n.activate,
        icon: Icons.local_offer_outlined,
        confirmColor: Theme.of(context).colorScheme.primary,
      );
      if (confirmed == true) {
        await provider.toggleTagActivation(tag);
      }
    } else {
      await provider.toggleTagActivation(tag);
    }
  }

  void _handleTagDelete(BuildContext context, RuleProvider provider, String tag,
      int ruleCount) async {
    await provider.deleteTag(tag);
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
                  child: TagStatsCard(rules: provider.rules),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tags = provider.allTags.toList()..sort();
                      final tag = tags[index];
                      final taggedRules =
                          provider.rules.where((r) => r.tags.contains(tag));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TagListItem(
                          tag: tag,
                          ruleCount: taggedRules.length,
                          isActive: provider.activeTags.contains(tag),
                          onActiveChanged: (active) {
                            _handleTagActivation(
                                context, provider, tag, active);
                          },
                          onDelete: () {
                            _handleTagDelete(
                                context, provider, tag, taggedRules.length);
                          },
                        ),
                      );
                    },
                    childCount: provider.allTags.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TagListItem extends StatelessWidget {
  const _TagListItem({
    required this.tag,
    required this.ruleCount,
    required this.isActive,
    required this.onActiveChanged,
    required this.onDelete,
  });
  final String tag;
  final int ruleCount;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onDelete;

  Color _getTagColor(BuildContext context) {
    // 根据标签文本生成一个稳定的颜色
    final int hash = tag.hashCode;
    final List<Color> baseColors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.deepPurple,
    ];

    return baseColors[hash.abs() % baseColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final tagColor = _getTagColor(context);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Dismissible(
          key: Key(tag),
          direction: DismissDirection.endToStart,
          dismissThresholds: const {
            DismissDirection.endToStart: 0.2,
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: Colors.white,
            child: Container(
              // ignore: no-magic-number
              width: 40,
              // ignore: no-magic-number
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red[400],
                // ignore: no-magic-number
                size: 20,
              ),
            ),
          ),
          confirmDismiss: (_) async {
            final confirmed = await ConfirmDialog.show(
              context: context,
              title: l10n.deleteTag,
              content: l10n.deleteTagConfirm(tag, ruleCount),
              confirmText: l10n.delete,
              icon: Icons.delete_outline,
            );
            if (confirmed == true) {
              onDelete();
            }

            return confirmed ?? false;
          },
          child: InkWell(
            onTap: () => onActiveChanged(!isActive),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    // ignore: no-magic-number
                    width: 40,
                    // ignore: no-magic-number
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive
                          // ignore: no-magic-number
                          ? tagColor.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Icon(
                      Icons.local_offer_outlined,
                      color: isActive ? tagColor : Colors.grey.shade600,
                      // ignore: no-magic-number
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.usedInRules(ruleCount),
                          style: TextStyle(
                            // ignore: no-magic-number
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    // ignore: no-magic-number
                    scale: 0.8,
                    child: Switch(
                      value: isActive,
                      onChanged: onActiveChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
