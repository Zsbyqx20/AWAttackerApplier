import 'package:flutter/material.dart';

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
  late TabController _tabController;
  bool _hasOverlayPermission = false;
  bool _hasAccessibilityPermission = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index > 0) {
      if (!_hasOverlayPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先授予悬浮窗权限')),
        );
        _tabController.animateTo(0);
      } else if (!_hasAccessibilityPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先授予无障碍服务权限')),
        );
        _tabController.animateTo(0);
      }
    }
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('AW Attack Applier'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Tab(
                icon: Icon(Icons.settings_outlined),
                text: '配置',
                height: 60,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Tab(
                icon: Icon(Icons.rule_folder_outlined,
                    color:
                        !_hasOverlayPermission || !_hasAccessibilityPermission
                            ? Colors.grey[400]
                            : null),
                text: '规则',
                height: 60,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Tab(
                icon: Icon(Icons.sell_outlined,
                    color:
                        !_hasOverlayPermission || !_hasAccessibilityPermission
                            ? Colors.grey[400]
                            : null),
                text: '标签',
                height: 60,
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
