import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.onTap,
    this.backgroundColor,
    this.isSelected = false,
    this.isActive = false,
    this.showActiveState = false,
  });
  final String label;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool isSelected;
  final bool isActive;
  final bool showActiveState;

  Color _getBackgroundColor(BuildContext context) {
    if (isActive && showActiveState) {
      // ignore: no-magic-number
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);
    }
    if (isSelected) {
      // ignore: no-magic-number
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
    }
    if (backgroundColor != null) {
      return backgroundColor ?? Theme.of(context).colorScheme.surface;
    }

    // 根据标签文本生成一个稳定的浅色背景
    final int hash = label.hashCode;
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

    final baseColor = baseColors[hash.abs() % baseColors.length];

    // ignore: no-magic-number
    return baseColor.withValues(alpha: 0.12);
  }

  Color _getTextColor(BuildContext context) {
    if (isActive && showActiveState) {
      return Theme.of(context).colorScheme.primary;
    }
    if (isSelected) {
      return Theme.of(context).colorScheme.primary;
    }

    final int hash = label.hashCode;
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
    final chip = Chip(
      label: Text(
        label,
        style: TextStyle(
          // ignore: no-magic-number
          fontSize: 12,
          color: _getTextColor(context),
        ),
      ),
      backgroundColor: _getBackgroundColor(context),
      deleteIcon: onDeleted != null
          ? Icon(
              Icons.cancel,
              // ignore: no-magic-number
              size: 14,
              color: _getTextColor(context),
            )
          : null,
      onDeleted: onDeleted,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: -2),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      avatar: showActiveState && isActive
          ? Icon(
              Icons.check_circle_outline,
              // ignore: no-magic-number
              size: 14,
              color: _getTextColor(context),
            )
          : null,
    );

    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              child: chip,
            )
          : chip,
    );
  }
}

class TagChipsRow extends StatelessWidget {
  const TagChipsRow({
    super.key,
    required this.tags,
    this.onTagDeleted,
    this.onTagTap,
    this.scrollController,
    this.showDeleteButton = false,
    this.showActiveState = false,
    this.activeTags = const {},
  });
  final List<String> tags;
  final void Function(String)? onTagDeleted;
  final void Function(String)? onTagTap;
  final ScrollController? scrollController;
  final bool showDeleteButton;
  final bool showActiveState;
  final Set<String> activeTags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: scrollController,
      child: Wrap(
        // ignore: no-magic-number
        spacing: 4,
        runSpacing: 0,
        children: tags.map((tag) {
          return TagChip(
            label: tag,
            onDeleted: showDeleteButton ? () => onTagDeleted?.call(tag) : null,
            onTap: onTagTap != null ? () => onTagTap?.call(tag) : null,
            isActive: activeTags.contains(tag),
            showActiveState: showActiveState,
          );
        }).toList(),
      ),
    );
  }
}

class TagChipsInput extends StatefulWidget {
  const TagChipsInput({
    super.key,
    required this.tags,
    required this.onChanged,
    this.suggestions = const [],
    this.maxTags,
  });
  final List<String> tags;
  final List<String> suggestions;
  final ValueChanged<List<String>> onChanged;
  final int? maxTags;

  @override
  State<TagChipsInput> createState() => _TagChipsInputState();
}

class _TagChipsInputState extends State<TagChipsInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;
  List<String> _filteredSuggestions = [];

  void _addTag(String tag) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return;
    }
    if (tag.isEmpty) return;
    final maxTags = widget.maxTags;
    if (maxTags != null && widget.tags.length >= maxTags) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tagChipsLimitHint(maxTags))),
      );

      return;
    }

    final newTag = tag.trim();
    if (newTag.isNotEmpty && !widget.tags.contains(newTag)) {
      final newTags = List<String>.of(widget.tags)..add(newTag);
      widget.onChanged(newTags);
      _controller.clear();
      setState(() {
        _showSuggestions = false;
        _filteredSuggestions = [];
      });
    }
  }

  void _removeTag(String tag) {
    final newTags = List<String>.of(widget.tags)..remove(tag);
    widget.onChanged(newTags);
  }

  void _updateSuggestions(String value) {
    if (value.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _filteredSuggestions = [];
      });

      return;
    }

    final suggestions = widget.suggestions
        .where((tag) =>
            !widget.tags.contains(tag) &&
            tag.toLowerCase().contains(value.toLowerCase()))
        .toList();

    setState(() {
      _showSuggestions = suggestions.isNotEmpty;
      _filteredSuggestions = suggestions;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TagChipsRow(
              tags: widget.tags,
              onTagDeleted: _removeTag,
              showDeleteButton: true,
            ),
          ),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: l10n.tagChipsHint,
            hintStyle: TextStyle(
              // ignore: no-magic-number
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(_controller.text),
              // ignore: no-magic-number
              iconSize: 20,
              // ignore: no-magic-number
              splashRadius: 24,
              padding: const EdgeInsets.all(12),
            ),
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
          ),
          onSubmitted: _addTag,
          onChanged: _updateSuggestions,
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Wrap(
              // ignore: no-magic-number
              spacing: 8,
              children: _filteredSuggestions
                  .map((tag) => ActionChip(
                        label: Text(tag),
                        onPressed: () => _addTag(tag),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
