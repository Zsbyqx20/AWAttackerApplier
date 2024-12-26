import 'package:flutter/material.dart';
import '../../models/rule.dart';
import '../../models/overlay_style.dart';
import '../../providers/rule_provider.dart';

class RuleEditController extends ChangeNotifier {
  final RuleProvider _ruleProvider;
  final Rule? initialRule;
  late TextEditingController nameController;
  late TextEditingController packageNameController;
  late TextEditingController activityNameController;
  late List<OverlayStyle> overlayStyles;
  late TabController tabController;
  int currentTabIndex = 0;
  TickerProvider? _vsync;

  RuleEditController(this._ruleProvider, this.initialRule) {
    nameController = TextEditingController(text: initialRule?.name ?? '');
    packageNameController =
        TextEditingController(text: initialRule?.packageName ?? '');
    activityNameController =
        TextEditingController(text: initialRule?.activityName ?? '');
    overlayStyles =
        List.from(initialRule?.overlayStyles ?? [OverlayStyle.defaultStyle()]);
  }

  void initTabController(TickerProvider vsync) {
    _vsync = vsync;
    tabController = TabController(
      length: overlayStyles.length,
      vsync: vsync,
      initialIndex: currentTabIndex,
    );
    tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (tabController.index != currentTabIndex) {
      currentTabIndex = tabController.index;
      notifyListeners();
    }
  }

  void addStyle() {
    overlayStyles.add(OverlayStyle.defaultStyle());
    tabController.dispose();
    if (_vsync != null) {
      tabController = TabController(
        length: overlayStyles.length,
        vsync: _vsync!,
        initialIndex: overlayStyles.length - 1,
      );
      tabController.addListener(_handleTabChange);
      currentTabIndex = overlayStyles.length - 1;
      notifyListeners();
    }
  }

  void removeCurrentStyle() {
    if (overlayStyles.length <= 1) return;

    overlayStyles.removeAt(currentTabIndex);
    tabController.dispose();
    if (_vsync != null) {
      tabController = TabController(
        length: overlayStyles.length,
        vsync: _vsync!,
        initialIndex: currentTabIndex > 0 ? currentTabIndex - 1 : 0,
      );
      tabController.addListener(_handleTabChange);
      currentTabIndex = tabController.index;
      notifyListeners();
    }
  }

  void updateCurrentStyle(OverlayStyle style) {
    overlayStyles[currentTabIndex] = style;
    notifyListeners();
  }

  Future<bool> saveRule() async {
    if (nameController.text.isEmpty ||
        packageNameController.text.isEmpty ||
        activityNameController.text.isEmpty) {
      return false;
    }

    final rule = Rule(
      id: initialRule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text,
      packageName: packageNameController.text,
      activityName: activityNameController.text,
      isEnabled: initialRule?.isEnabled ?? false,
      overlayStyles: overlayStyles,
    );

    try {
      if (initialRule != null) {
        await _ruleProvider.updateRule(rule);
      } else {
        await _ruleProvider.addRule(rule);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    packageNameController.dispose();
    activityNameController.dispose();
    tabController.dispose();
    super.dispose();
  }
}
