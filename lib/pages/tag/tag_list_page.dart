import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../providers/rule_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/tag_stats_card.dart';

class TagListPage extends StatefulWidget {
  const TagListPage({super.key});

  @override
  State<TagListPage> createState() => _TagListPageState();
}

class _TagListPageState extends State<TagListPage> {
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

  void _handleTagActivation(BuildContext context, RuleProvider provider,
      String tag, bool active) async {
    if (active) {
      final affectedRules = provider.rules.where((r) => r.tags.contains(tag));
      final confirmed = await ConfirmDialog.show(
        context: context,
        title: '激活标签',
        content: '激活标签"$tag"将影响${affectedRules.length}条规则，是否继续？',
        confirmText: '激活',
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
}

class _TagListItem extends StatelessWidget {
  final String tag;
  final int ruleCount;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onDelete;

  const _TagListItem({
    required this.tag,
    required this.ruleCount,
    required this.isActive,
    required this.onActiveChanged,
    required this.onDelete,
  });

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

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red[400],
                size: 20,
              ),
            ),
          ),
          confirmDismiss: (_) async {
            final confirmed = await ConfirmDialog.show(
              context: context,
              title: '删除标签',
              content: '删除标签"$tag"将从$ruleCount条规则中移除，是否继续？',
              confirmText: '删除',
              icon: Icons.delete_outline,
            );
            if (confirmed == true) {
              onDelete();
            }
            return confirmed ?? false;
          },
          child: InkWell(
            onTap: () => onActiveChanged(!isActive),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive
                          ? tagColor.withValues(alpha: 0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_offer_outlined,
                      color: isActive ? tagColor : Colors.grey[600],
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
                          '使用于 $ruleCount 条规则',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
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
