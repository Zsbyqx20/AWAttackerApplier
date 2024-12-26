import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:study_flutter/models/rule.dart';

class RuleEditPage extends StatefulWidget {
  final String? ruleName;
  final String? packageName;
  final String? activityName;
  final Rule? rule;

  const RuleEditPage({
    super.key,
    this.ruleName,
    this.packageName,
    this.activityName,
    this.rule,
  });

  @override
  State<RuleEditPage> createState() => _RuleEditPageState();
}

class _RuleEditPageState extends State<RuleEditPage>
    with TickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _packageNameController;
  late final TextEditingController _activityNameController;
  late final TabController _tabController;

  late List<OverlayStyle> _overlayStyles;
  late OverlayStyle _currentStyle;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _tabController = TabController(
      length: _overlayStyles.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
          _currentStyle = _overlayStyles[_currentTabIndex];
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _packageNameController.dispose();
    _activityNameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.rule?.name ?? '');
    _packageNameController =
        TextEditingController(text: widget.rule?.packageName ?? '');
    _activityNameController =
        TextEditingController(text: widget.rule?.activityName ?? '');

    if (widget.rule != null) {
      _overlayStyles = List.from(widget.rule!.overlayStyles);
    } else {
      _overlayStyles = [
        OverlayStyle(
          uiAutomatorCode: '',
          x: 0,
          y: 0,
          width: 0,
          height: 0,
          backgroundColor: Colors.white,
          text: '',
          fontSize: 14,
          textColor: Colors.black,
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
        ),
      ];
    }

    _currentStyle = _overlayStyles[_currentTabIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.rule == null ? '添加规则' : '编辑规则',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              '取消',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: _saveRule,
            child: Text(
              '保存',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本信息部分
            Card(
              elevation: 1,
              margin: const EdgeInsets.all(16),
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
                    Text(
                      '基本信息',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '规则名称',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: '请输入规则名称',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _packageNameController,
                      decoration: InputDecoration(
                        labelText: '包名',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: '请输入应用包名',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _activityNameController,
                      decoration: InputDecoration(
                        labelText: '活动名',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: '请输入活动名称',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 悬浮窗配置部分
            Card(
              elevation: 1,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    tabs: List.generate(
                      _overlayStyles.length,
                      (index) => Tab(text: '悬浮窗 ${index + 1}'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 筛选规则
                        Text(
                          '筛选规则',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _currentStyle.uiAutomatorCode,
                          onChanged: (value) {
                            setState(() {
                              _currentStyle = _currentStyle.copyWith(
                                uiAutomatorCode: value,
                              );
                              _overlayStyles[_currentTabIndex] = _currentStyle;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'UI Automator代码',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            hintText:
                                '请输入UI Automator代码，例如：new UiSelector().text("搜索")',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 悬浮窗设置
                        Text(
                          '悬浮窗设置',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _currentStyle.x.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _currentStyle = _currentStyle.copyWith(
                                      x: double.tryParse(value) ?? 0,
                                    );
                                    _overlayStyles[_currentTabIndex] =
                                        _currentStyle;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'X 偏移 (dp)',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _currentStyle.y.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _currentStyle = _currentStyle.copyWith(
                                      y: double.tryParse(value) ?? 0,
                                    );
                                    _overlayStyles[_currentTabIndex] =
                                        _currentStyle;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Y 偏移 (dp)',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _currentStyle.width.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _currentStyle = _currentStyle.copyWith(
                                      width: double.tryParse(value) ?? 0,
                                    );
                                    _overlayStyles[_currentTabIndex] =
                                        _currentStyle;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: '宽度偏移 (dp)',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _currentStyle.height.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _currentStyle = _currentStyle.copyWith(
                                      height: double.tryParse(value) ?? 0,
                                    );
                                    _overlayStyles[_currentTabIndex] =
                                        _currentStyle;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: '高度偏移 (dp)',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildColorInput(
                          color: _currentStyle.backgroundColor,
                          onColorChanged: _updateBackgroundColor,
                          hintText: '背景颜色',
                        ),
                        const SizedBox(height: 24),
                        // 文字风格设置
                        Text(
                          '文字风格设置',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _currentStyle.text,
                          onChanged: (value) {
                            setState(() {
                              _currentStyle = _currentStyle.copyWith(
                                text: value,
                              );
                              _overlayStyles[_currentTabIndex] = _currentStyle;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: '文字内容',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            hintText: '请输入文字内容',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _currentStyle.fontSize.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _currentStyle = _currentStyle.copyWith(
                                      fontSize: double.tryParse(value) ?? 14,
                                    );
                                    _overlayStyles[_currentTabIndex] =
                                        _currentStyle;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: '文字大小 (sp)',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildColorInput(
                                color: _currentStyle.textColor,
                                onColorChanged: _updateTextColor,
                                hintText: '文字颜色',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextAlignmentSection(),
                        const SizedBox(height: 16),
                        Text(
                          '内边距',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue:
                                    _currentStyle.padding.top.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _currentStyle = _currentStyle.copyWith(
                                      padding: _currentStyle.padding.copyWith(
                                        top: double.tryParse(value) ?? 0,
                                      ),
                                    );
                                    _overlayStyles[_currentTabIndex] =
                                        _currentStyle;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: '上 (dp)',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue:
                                    _currentStyle.padding.right.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _currentStyle = _currentStyle.copyWith(
                                      padding: _currentStyle.padding.copyWith(
                                        right: double.tryParse(value) ?? 0,
                                      ),
                                    );
                                    _overlayStyles[_currentTabIndex] =
                                        _currentStyle;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: '右 (dp)',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue:
                                    _currentStyle.padding.bottom.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _currentStyle = _currentStyle.copyWith(
                                      padding: _currentStyle.padding.copyWith(
                                        bottom: double.tryParse(value) ?? 0,
                                      ),
                                    );
                                    _overlayStyles[_currentTabIndex] =
                                        _currentStyle;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: '下 (dp)',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue:
                                    _currentStyle.padding.left.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _currentStyle = _currentStyle.copyWith(
                                      padding: _currentStyle.padding.copyWith(
                                        left: double.tryParse(value) ?? 0,
                                      ),
                                    );
                                    _overlayStyles[_currentTabIndex] =
                                        _currentStyle;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: '左 (dp)',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _addOverlay,
            heroTag: 'add',
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _deleteCurrentOverlay,
            heroTag: 'delete',
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _addOverlay() {
    if (_overlayStyles.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多只能添加10个悬浮窗')),
      );
      return;
    }

    setState(() {
      _overlayStyles.add(
        OverlayStyle(
          uiAutomatorCode: '',
          x: 0,
          y: 0,
          width: 0,
          height: 0,
          backgroundColor: Colors.white,
          text: '',
          fontSize: 14,
          textColor: Colors.black,
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
        ),
      );
      _tabController = TabController(
        length: _overlayStyles.length,
        vsync: this,
        initialIndex: _overlayStyles.length - 1,
      );
    });
  }

  void _deleteCurrentOverlay() {
    if (_overlayStyles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少需要保留一个悬浮窗')),
      );
      return;
    }

    setState(() {
      _overlayStyles.removeAt(_currentTabIndex);
      _tabController = TabController(
        length: _overlayStyles.length,
        vsync: this,
        initialIndex: math.min(_currentTabIndex, _overlayStyles.length - 1),
      );
      _currentTabIndex = _tabController.index;
      _currentStyle = _overlayStyles[_currentTabIndex];
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

  Widget _buildColorInput({
    required Color color,
    required Function(Color) onColorChanged,
    required String hintText,
  }) {
    // 构建六位十六进制颜色字符串（不包含透明度）
    String colorHex = color.r.toInt().toRadixString(16).padLeft(2, '0') +
        color.g.toInt().toRadixString(16).padLeft(2, '0') +
        color.b.toInt().toRadixString(16).padLeft(2, '0');

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
        Expanded(
          child: TextFormField(
            initialValue: colorHex.toUpperCase(),
            onChanged: (value) {
              if (value.length == 6) {
                try {
                  final color = Color(int.parse('FF$value', radix: 16));
                  onColorChanged(color);
                } catch (e) {
                  // 忽略无效的颜色值
                }
              }
            },
            decoration: InputDecoration(
              labelText: hintText,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextAlignmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '文字对齐',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        // 水平对齐
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '水平对齐',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Row(
              children: [
                _buildAlignmentButton(
                  icon: Icons.format_align_left,
                  isSelected: _currentStyle.alignment.x == -1,
                  onTap: () => _updateAlignment(x: -1),
                  tooltip: '左对齐',
                ),
                const SizedBox(width: 12),
                _buildAlignmentButton(
                  icon: Icons.format_align_center,
                  isSelected: _currentStyle.alignment.x == 0,
                  onTap: () => _updateAlignment(x: 0),
                  tooltip: '水平居中',
                ),
                const SizedBox(width: 12),
                _buildAlignmentButton(
                  icon: Icons.format_align_right,
                  isSelected: _currentStyle.alignment.x == 1,
                  onTap: () => _updateAlignment(x: 1),
                  tooltip: '右对齐',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 垂直对齐
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '垂直对齐',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Row(
              children: [
                _buildAlignmentButton(
                  icon: Icons.vertical_align_top,
                  isSelected: _currentStyle.alignment.y == -1,
                  onTap: () => _updateAlignment(y: -1),
                  tooltip: '顶部对齐',
                ),
                const SizedBox(width: 12),
                _buildAlignmentButton(
                  icon: Icons.vertical_align_center,
                  isSelected: _currentStyle.alignment.y == 0,
                  onTap: () => _updateAlignment(y: 0),
                  tooltip: '垂直居中',
                ),
                const SizedBox(width: 12),
                _buildAlignmentButton(
                  icon: Icons.vertical_align_bottom,
                  isSelected: _currentStyle.alignment.y == 1,
                  onTap: () => _updateAlignment(y: 1),
                  tooltip: '底部对齐',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlignmentButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  void _updateAlignment({double? x, double? y}) {
    setState(() {
      _currentStyle = _currentStyle.copyWith(
        alignment: Alignment(
          x ?? _currentStyle.alignment.x,
          y ?? _currentStyle.alignment.y,
        ),
      );
      _overlayStyles[_currentTabIndex] = _currentStyle;
    });
  }

  void _updateBackgroundColor(Color color) {
    setState(() {
      _currentStyle = _currentStyle.copyWith(
          backgroundColor: Color.fromARGB(
        color.a.toInt(),
        color.r.toInt(),
        color.g.toInt(),
        color.b.toInt(),
      ));
    });
  }

  void _updateTextColor(Color color) {
    setState(() {
      _currentStyle = _currentStyle.copyWith(
          textColor: Color.fromARGB(
        color.a.toInt(),
        color.r.toInt(),
        color.g.toInt(),
        color.b.toInt(),
      ));
    });
  }
}
