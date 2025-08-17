import 'package:flutter/material.dart';

import 'package:awattackerapplier/l10n/app_localizations.dart';
import 'rule/rule_list_page.dart';
import 'server_config_page.dart';
import 'tag/tag_list_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  // ignore: avoid-late-keyword
  late TabController _tabController;
  bool _hasOverlayPermission = false;
  bool _hasAccessibilityPermission = false;

  /// tab 图标高度
  static const double tabIconHeight = 60;

  /// controller 个数
  static const int controllerLength = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: controllerLength, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.index > 0) {
      final l10n = AppLocalizations.of(context);
      if (l10n == null) {
        debugPrint('Error: AppLocalizations not found');

        return;
      }
      if (!_hasOverlayPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.overlayPermissionRequired)),
        );
        _tabController.animateTo(0);
      } else if (!_hasAccessibilityPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accessibilityPermissionRequired)),
        );
        _tabController.animateTo(0);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void updatePermissions(
      {bool? overlayPermission, bool? accessibilityPermission}) {
    setState(() {
      if (overlayPermission != null) {
        _hasOverlayPermission = overlayPermission;
      }
      if (accessibilityPermission != null) {
        _hasAccessibilityPermission = accessibilityPermission;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('AW Attack Applier'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Tab(
                icon: const Icon(Icons.settings_outlined),
                text: l10n.configTab,
                height: tabIconHeight,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Tab(
                icon: Icon(Icons.rule_folder_outlined,
                    color:
                        !_hasOverlayPermission || !_hasAccessibilityPermission
                            ? Colors.grey.shade400
                            : null),
                text: l10n.rulesTab,
                height: tabIconHeight,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Tab(
                icon: Icon(Icons.sell_outlined,
                    color:
                        !_hasOverlayPermission || !_hasAccessibilityPermission
                            ? Colors.grey.shade400
                            : null),
                text: l10n.tagsTab,
                height: tabIconHeight,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: !_hasOverlayPermission || !_hasAccessibilityPermission
            ? const NeverScrollableScrollPhysics()
            : null,
        children: [
          ServerConfigPage(
            onPermissionsChanged: updatePermissions,
          ),
          const RuleListPage(),
          const TagListPage(),
        ],
      ),
    );
  }
}
