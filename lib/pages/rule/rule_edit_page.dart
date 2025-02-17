import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../models/overlay_style.dart';
import '../../models/rule.dart';
import '../../providers/rule_provider.dart';
import '../../providers/rule_validation_provider.dart';
import '../../widgets/style_editor.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/text_input_field.dart';
import '../../widgets/validation_error_widget.dart';

class RuleEditPage extends StatefulWidget {
  const RuleEditPage({super.key, this.rule});
  final Rule? rule;

  @override
  State<RuleEditPage> createState() => _RuleEditPageState();
}

class _RuleEditPageState extends State<RuleEditPage>
    with TickerProviderStateMixin {
  // ignore: avoid-late-keyword
  late final TextEditingController _nameController;
  // ignore: avoid-late-keyword
  late final TextEditingController _packageNameController;
  // ignore: avoid-late-keyword
  late final TextEditingController _activityNameController;
  // ignore: avoid-late-keyword
  late final TextEditingController _textController;
  // ignore: avoid-late-keyword
  late final TextEditingController _uiAutomatorCodeController;
  // ignore: avoid-late-keyword
  late final TextEditingController _allowController;
  // ignore: avoid-late-keyword
  late final TextEditingController _denyController;
  // ignore: avoid-late-keyword
  late TabController _tabController;
  // ignore: avoid-late-keyword
  late final RuleValidationProvider _validationProvider;
  final ScrollController _scrollController = ScrollController();

  List<OverlayStyle> _overlayStyles = [];
  List<String> _tags = [];
  int _currentTabIndex = 0;

  // 添加字段的GlobalKey
  final _nameFieldKey = GlobalKey();
  final _packageNameFieldKey = GlobalKey();
  final _activityNameFieldKey = GlobalKey();
  final _tagsFieldKey = GlobalKey();

  OverlayStyle get _currentStyle => _overlayStyles[_currentTabIndex];
  @override
  void initState() {
    super.initState();
    _validationProvider = RuleValidationProvider();

    _nameController = TextEditingController(text: widget.rule?.name ?? '');
    _packageNameController =
        TextEditingController(text: widget.rule?.packageName ?? '');
    _activityNameController =
        TextEditingController(text: widget.rule?.activityName ?? '');

    if (widget.rule != null) {
      final rule = widget.rule;
      if (rule == null) return;
      _overlayStyles = List.of(rule.overlayStyles);
      _tags = List.of(rule.tags);
    } else {
      _overlayStyles = [OverlayStyle.defaultStyle()];
    }

    _textController = TextEditingController(text: _currentStyle.text);
    _uiAutomatorCodeController =
        TextEditingController(text: _currentStyle.uiAutomatorCode);
    _allowController =
        TextEditingController(text: _currentStyle.allow?.join('\n') ?? '');
    _denyController =
        TextEditingController(text: _currentStyle.deny?.join('\n') ?? '');

    _initTabController();

    // 初始验证
    _validateAllFields();

    // 添加监听器
    _nameController.addListener(() {
      _validationProvider.validateField('name', _nameController.text);
    });
    _packageNameController.addListener(() {
      _validationProvider.validateField(
          'packageName', _packageNameController.text);
    });
    _activityNameController.addListener(() {
      _validationProvider.validateField(
          'activityName', _activityNameController.text);
    });
  }

  void _initTabController({int initialIndex = 0}) {
    _tabController = TabController(
      length: _overlayStyles.length,
      vsync: this,
      initialIndex: initialIndex,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() {
        _currentTabIndex = _tabController.index;
        _textController.text = _currentStyle.text;
        _uiAutomatorCodeController.text = _currentStyle.uiAutomatorCode;
        _allowController.text = _currentStyle.allow?.join('\n') ?? '';
        _denyController.text = _currentStyle.deny?.join('\n') ?? '';
      });
    });
  }

  void _validateAllFields() {
    _validationProvider.validateField('name', _nameController.text);
    _validationProvider.validateField(
        'packageName', _packageNameController.text);
    _validationProvider.validateField(
        'activityName', _activityNameController.text);
    _validationProvider.validateField('tags', _tags);
    for (final style in _overlayStyles) {
      _validationProvider.validateField('overlayStyle', style);
    }
  }

  void _addOverlayStyle() {
    setState(() {
      _overlayStyles.add(OverlayStyle.defaultStyle());
      final newIndex = _overlayStyles.length - 1;
      _tabController.dispose();
      _initTabController(initialIndex: newIndex);
      _currentTabIndex = newIndex;
      _textController.text = _currentStyle.text;
      _uiAutomatorCodeController.text = _currentStyle.uiAutomatorCode;
      _allowController.text = _currentStyle.allow?.join('\n') ?? '';
      _denyController.text = _currentStyle.deny?.join('\n') ?? '';
    });
  }

  void _removeCurrentOverlayStyle() {
    if (_overlayStyles.length <= 1) return;

    setState(() {
      final newIndex = _currentTabIndex > 0 ? _currentTabIndex - 1 : 0;
      _overlayStyles.removeAt(_currentTabIndex);
      _tabController.dispose();
      _initTabController(initialIndex: newIndex);
      _currentTabIndex = newIndex;
      _textController.text = _currentStyle.text;
      _uiAutomatorCodeController.text = _currentStyle.uiAutomatorCode;
      _allowController.text = _currentStyle.allow?.join('\n') ?? '';
      _denyController.text = _currentStyle.deny?.join('\n') ?? '';
    });
  }

  void _updateTextContent(String value) {
    setState(() {
      _overlayStyles[_currentTabIndex] = _currentStyle.copyWith(text: value);
    });
  }

  void _updateFontSize(double value) {
    setState(() {
      _overlayStyles[_currentTabIndex] =
          _currentStyle.copyWith(fontSize: value);
    });
  }

  void _updatePosition(String value) {
    final parts = value.split(':');
    // ignore: no-magic-number
    if (parts.length != 2) return;

    final field = parts.first;
    final doubleValue = double.tryParse(parts[1]);
    if (doubleValue == null) return;

    setState(() {
      switch (field) {
        case 'x':
          _overlayStyles[_currentTabIndex] =
              _currentStyle.copyWith(x: doubleValue);
        case 'y':
          _overlayStyles[_currentTabIndex] =
              _currentStyle.copyWith(y: doubleValue);
        case 'width':
          _overlayStyles[_currentTabIndex] =
              _currentStyle.copyWith(width: doubleValue);
        case 'height':
          _overlayStyles[_currentTabIndex] =
              _currentStyle.copyWith(height: doubleValue);
      }
    });
  }

  void _updateBackgroundColor(Color color) {
    debugPrint('Updating background color: ${color.toString()}');
    setState(() {
      _overlayStyles[_currentTabIndex] =
          _currentStyle.copyWith(backgroundColor: color);
    });
  }

  void _updateTextColor(Color color) {
    debugPrint('Updating text color: ${color.toString()}');
    setState(() {
      _overlayStyles[_currentTabIndex] =
          _currentStyle.copyWith(textColor: color);
    });
  }

  void _updateUiAutomatorCode(String value) {
    setState(() {
      _overlayStyles[_currentTabIndex] =
          _currentStyle.copyWith(uiAutomatorCode: value);
    });
  }

  void _updateHorizontalAlign(TextAlign align) {
    setState(() {
      _overlayStyles[_currentTabIndex] =
          _currentStyle.copyWith(horizontalAlign: align);
    });
  }

  void _updateVerticalAlign(TextAlign align) {
    setState(() {
      _overlayStyles[_currentTabIndex] =
          _currentStyle.copyWith(verticalAlign: align);
    });
  }

  void _updatePadding(String value) {
    final parts = value.split(':');
    // ignore: no-magic-number
    if (parts.length != 2) return;

    final field = parts.first;
    final doubleValue = double.tryParse(parts.last);
    if (doubleValue == null) return;

    setState(() {
      final currentPadding = _currentStyle.padding;
      EdgeInsets newPadding;
      switch (field) {
        case 'left':
          newPadding = EdgeInsets.fromLTRB(
            doubleValue,
            currentPadding.top,
            currentPadding.right,
            currentPadding.bottom,
          );
        case 'top':
          newPadding = EdgeInsets.fromLTRB(
            currentPadding.left,
            doubleValue,
            currentPadding.right,
            currentPadding.bottom,
          );
        case 'right':
          newPadding = EdgeInsets.fromLTRB(
            currentPadding.left,
            currentPadding.top,
            doubleValue,
            currentPadding.bottom,
          );
        case 'bottom':
          newPadding = EdgeInsets.fromLTRB(
            currentPadding.left,
            currentPadding.top,
            currentPadding.right,
            doubleValue,
          );
        default:
          return;
      }
      _overlayStyles[_currentTabIndex] =
          _currentStyle.copyWith(padding: newPadding);
    });
  }

  void _updateTags(List<String> newTags) {
    setState(() {
      _tags = newTags;
    });
  }

  void _updateAllowConditions(List<String> conditions) {
    setState(() {
      _overlayStyles[_currentTabIndex] =
          _currentStyle.copyWith(allow: conditions);
    });
  }

  void _updateDenyConditions(List<String> conditions) {
    setState(() {
      _overlayStyles[_currentTabIndex] =
          _currentStyle.copyWith(deny: conditions);
    });
  }

  void _saveRule() {
    // 验证所有字段
    _validateAllFields();

    // 如果验证通过，保存并返回
    if (_validationProvider.state.isValid) {
      final rule = widget.rule?.copyWith(
            name: _nameController.text,
            packageName: _packageNameController.text,
            activityName: _activityNameController.text,
            overlayStyles: _overlayStyles,
            tags: _tags,
            isEnabled: widget.rule?.isEnabled ?? false,
          ) ??
          Rule(
            name: _nameController.text,
            packageName: _packageNameController.text,
            activityName: _activityNameController.text,
            isEnabled: false,
            overlayStyles: _overlayStyles,
            tags: _tags,
          );
      Navigator.of(context).pop(rule);

      return;
    }

    // 如果验证失败，找到第一个错误字段并滚动到其位置
    final firstErrorField = _validationProvider.state.fieldResults.entries
        .where((entry) => !entry.value.isValid)
        .map((entry) => entry.key)
        .first;

    // 获取错误字段对应的GlobalKey
    final fieldKeys = {
      'name': _nameFieldKey,
      'packageName': _packageNameFieldKey,
      'activityName': _activityNameFieldKey,
      'tags': _tagsFieldKey,
    };

    // 获取字段的显示名称
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return;
    }
    final fieldDisplayNames = {
      'name': l10n.ruleName,
      'packageName': l10n.packageName,
      'activityName': l10n.activityName,
      'tags': l10n.tags,
      'overlayStyle': l10n.overlayStyleTitle,
    };

    final errorFieldKey = fieldKeys[firstErrorField];
    final errorContext = errorFieldKey?.currentContext;
    if (errorContext != null) {
      Scrollable.ensureVisible(
        errorContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        // ignore: no-magic-number
        alignment: 0.2,
      );
    }

    // 构建详细的错误信息
    final validationResult =
        _validationProvider.getFieldValidation(firstErrorField);
    final errorMessage = StringBuffer();

    // 添加字段名称
    errorMessage
        .write('${fieldDisplayNames[firstErrorField] ?? firstErrorField}: ');

    // 添加错误消息
    errorMessage.write(validationResult?.errorMessage ?? l10n.error);

    // 如果有错误代码，添加错误代码
    final errorCode = validationResult?.errorCode;
    if (errorCode != null) {
      errorMessage.write(' [$errorCode]');
    }

    // 如果有详细信息，添加详细信息
    final details = validationResult?.errorDetails;
    if (details != null) {
      final detailsStr = details.toString();
      if (detailsStr.isNotEmpty) {
        errorMessage.write('\n$detailsStr');
      }
    }

    // 显示错误提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errorMessage.toString(),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(8))),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.confirm,
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _packageNameController.dispose();
    _activityNameController.dispose();
    _textController.dispose();
    _uiAutomatorCodeController.dispose();
    _allowController.dispose();
    _denyController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ruleProvider = context.watch<RuleProvider>();
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title:
            Text(widget.rule == null ? l10n.ruleAddTitle : l10n.ruleEditTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveRule,
            child: Text(
              l10n.save,
              style: TextStyle(
                // ignore: no-magic-number
                fontSize: 16,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _validationProvider,
        builder: (context, child) => SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(l10n.basicInfo),
                    const SizedBox(height: 16),
                    ValidationErrorContainer(
                      key: _nameFieldKey,
                      validationResult:
                          _validationProvider.getFieldValidation('name'),
                      child: TextInputField(
                        label: l10n.ruleName,
                        hint: l10n.ruleNameHint,
                        controller: _nameController,
                        // ignore: no-empty-block
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ValidationErrorContainer(
                      key: _packageNameFieldKey,
                      validationResult:
                          _validationProvider.getFieldValidation('packageName'),
                      child: TextInputField(
                        label: l10n.packageName,
                        hint: l10n.packageNameHint,
                        controller: _packageNameController,
                        // ignore: no-empty-block
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ValidationErrorContainer(
                      key: _activityNameFieldKey,
                      validationResult: _validationProvider
                          .getFieldValidation('activityName'),
                      child: TextInputField(
                        label: l10n.activityName,
                        hint: l10n.activityNameHint,
                        controller: _activityNameController,
                        // ignore: no-empty-block
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ValidationErrorContainer(
                      key: _tagsFieldKey,
                      validationResult:
                          _validationProvider.getFieldValidation('tags'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.tags,
                            style: TextStyle(
                              // ignore: no-magic-number
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TagChipsInput(
                            tags: _tags,
                            suggestions: ruleProvider.allTags.toList(),
                            onChanged: _updateTags,
                            // ignore: no-magic-number
                            maxTags: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle(l10n.overlayStyleTitle),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _removeCurrentOverlayStyle,
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red[400],
                              ),
                              tooltip: l10n.removeStyle,
                              // ignore: no-magic-number
                              splashRadius: 24,
                            ),
                            IconButton(
                              onPressed: _addOverlayStyle,
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: theme.colorScheme.primary,
                              ),
                              tooltip: l10n.addStyle,
                              // ignore: no-magic-number
                              splashRadius: 24,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Center(
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor: Colors.grey[600],
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          indicator: BoxDecoration(
                            // ignore: no-magic-number
                            color: theme.colorScheme.primary.withAlpha(26),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            border: Border.all(
                              // ignore: no-magic-number
                              color: theme.colorScheme.primary.withAlpha(51),
                            ),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          padding: EdgeInsets.zero,
                          dividerColor: Colors.transparent,
                          tabAlignment: TabAlignment.center,
                          tabs: List.generate(
                            _overlayStyles.length,
                            (index) => Container(
                              // ignore: no-magic-number
                              width: 80,
                              // ignore: no-magic-number
                              height: 36,
                              alignment: Alignment.center,
                              child: Text(l10n.styleNumber(index + 1)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StyleEditor(
                      style: _currentStyle,
                      textController: _textController,
                      uiAutomatorCodeController: _uiAutomatorCodeController,
                      onTextChanged: _updateTextContent,
                      onFontSizeChanged: _updateFontSize,
                      onPositionChanged: _updatePosition,
                      onBackgroundColorChanged: _updateBackgroundColor,
                      onTextColorChanged: _updateTextColor,
                      onHorizontalAlignChanged: _updateHorizontalAlign,
                      onVerticalAlignChanged: _updateVerticalAlign,
                      onUiAutomatorCodeChanged: _updateUiAutomatorCode,
                      onPaddingChanged: _updatePadding,
                      onAllowChanged: _updateAllowConditions,
                      onDenyChanged: _updateDenyConditions,
                      allowController: _allowController,
                      denyController: _denyController,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
