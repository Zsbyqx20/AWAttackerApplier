import 'package:flutter/material.dart';
import '../../models/overlay_style.dart';
import '../../models/rule.dart';
import '../../widgets/text_input_field.dart';
import '../../widgets/style_editor.dart';

class RuleEditPage extends StatefulWidget {
  final Rule? rule;

  const RuleEditPage({super.key, this.rule});

  @override
  State<RuleEditPage> createState() => _RuleEditPageState();
}

class _RuleEditPageState extends State<RuleEditPage>
    with TickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _packageNameController;
  late final TextEditingController _activityNameController;
  late final TextEditingController _textController;
  late final TextEditingController _uiAutomatorCodeController;
  late TabController _tabController;

  List<OverlayStyle> _overlayStyles = [];
  int _currentTabIndex = 0;

  OverlayStyle get _currentStyle => _overlayStyles[_currentTabIndex];

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
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rule?.name ?? '');
    _packageNameController =
        TextEditingController(text: widget.rule?.packageName ?? '');
    _activityNameController =
        TextEditingController(text: widget.rule?.activityName ?? '');

    if (widget.rule != null) {
      _overlayStyles = List.from(widget.rule!.overlayStyles);
    } else {
      _overlayStyles = [OverlayStyle.defaultStyle()];
    }

    _textController = TextEditingController(text: _currentStyle.text);
    _uiAutomatorCodeController =
        TextEditingController(text: _currentStyle.uiAutomatorCode);

    _initTabController();
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
    if (parts.length != 2) return;

    final field = parts[0];
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
    if (parts.length != 2) return;

    final field = parts[0];
    final doubleValue = double.tryParse(parts[1]);
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

  void _saveRule() {
    final rule = Rule(
      id: widget.rule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      packageName: _packageNameController.text,
      activityName: _activityNameController.text,
      isEnabled: widget.rule?.isEnabled ?? false,
      overlayStyles: _overlayStyles,
    );

    Navigator.of(context).pop(rule);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _packageNameController.dispose();
    _activityNameController.dispose();
    _textController.dispose();
    _uiAutomatorCodeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.rule == null ? '添加规则' : '编辑规则'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveRule,
            child: Text(
              '保存',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('基本信息'),
                  const SizedBox(height: 16),
                  TextInputField(
                    label: '规则名称',
                    hint: '请输入规则名称',
                    controller: _nameController,
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextInputField(
                    label: '包名',
                    hint: '请输入包名',
                    controller: _packageNameController,
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextInputField(
                    label: '活动名',
                    hint: '请输入活动名',
                    controller: _activityNameController,
                    onChanged: (value) => setState(() {}),
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
                      _buildSectionTitle('悬浮窗样式'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _removeCurrentOverlayStyle,
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red[400],
                            ),
                            tooltip: '删除当前样式',
                            splashRadius: 24,
                          ),
                          IconButton(
                            onPressed: _addOverlayStyle,
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: theme.colorScheme.primary,
                            ),
                            tooltip: '添加新样式',
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
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
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
                          color: theme.colorScheme.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withAlpha(51),
                          ),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        padding: EdgeInsets.zero,
                        dividerColor: Colors.transparent,
                        tabAlignment: TabAlignment.center,
                        tabs: List.generate(
                          _overlayStyles.length,
                          (index) => Container(
                            width: 80,
                            height: 36,
                            alignment: Alignment.center,
                            child: Text('样式 ${index + 1}'),
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
                  ),
                ],
              ),
            ),
          ],
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
}
