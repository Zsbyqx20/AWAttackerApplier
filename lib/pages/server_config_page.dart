import 'package:flutter/material.dart';
import '../constants/storage_keys.dart';
import '../pages/rule_list_page.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';
import '../widgets/permission_card.dart';
import '../widgets/server_config_card.dart';
import '../widgets/server_status_card.dart';
import '../services/connection_service.dart';
import '../services/rule_matching_service.dart';

class ServerConfigPage extends StatefulWidget {
  const ServerConfigPage({super.key});

  @override
  State<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final TextEditingController _apiController = TextEditingController();
  final TextEditingController _wsController = TextEditingController();
  final StorageService _storageService = StorageService();

  bool _hasOverlayPermission = false;
  bool _isCheckingPermission = false;
  late TabController _tabController;
  bool _isStartingService = false;
  final ConnectionService _connectionService = ConnectionService();
  bool _isServiceRunning = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _storageService.init();
    await _loadSavedUrls();
    await _checkOverlayPermission();
    _listenToServiceStatus();

    // 启动规则匹配服务
    final ruleMatchingService = RuleMatchingService();
    await ruleMatchingService.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _apiController.dispose();
    _wsController.dispose();
    _hideNotification();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(seconds: 1), () async {
        for (int i = 0; i < 3; i++) {
          final hasPermission =
              await PermissionService.checkOverlayPermission();
          if (hasPermission) {
            if (mounted) {
              setState(() {
                _hasOverlayPermission = true;
              });
            }
            break;
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
      });
    }
  }

  Future<void> _loadSavedUrls() async {
    final urls = await _storageService.loadUrls();
    if (mounted) {
      setState(() {
        _apiController.text = urls[StorageKeys.apiUrlKey]!;
        _wsController.text = urls[StorageKeys.wsUrlKey]!;
      });
    }
  }

  Future<void> _saveUrls() async {
    await _storageService.saveUrls(
      apiUrl: _apiController.text,
      wsUrl: _wsController.text,
    );
  }

  Future<void> _checkOverlayPermission() async {
    if (_isCheckingPermission) return;

    setState(() {
      _isCheckingPermission = true;
    });

    try {
      bool hasPermission = false;
      for (int i = 0; i < 3; i++) {
        hasPermission = await PermissionService.checkOverlayPermission();
        if (hasPermission) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (mounted) {
        setState(() {
          _hasOverlayPermission = hasPermission;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPermission = false;
        });
      }
    }
  }

  Future<void> _requestOverlayPermission() async {
    if (_isCheckingPermission) return;

    setState(() {
      _isCheckingPermission = true;
    });

    try {
      final granted = await PermissionService.requestOverlayPermission();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(granted ? '权限已授予' : '权限请求被拒绝'),
          ),
        );
        await _checkOverlayPermission();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请求权限时发生错误')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPermission = false;
        });
      }
    }
  }

  void _onTabTapped(int index) {
    if (!_hasOverlayPermission && index > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先授予悬浮窗权限')),
      );
      return;
    }
    _tabController.animateTo(index);
  }

  void _listenToServiceStatus() {
    _connectionService.serviceStatus.listen((running) {
      if (mounted) {
        setState(() {
          _isServiceRunning = running;
        });
      }
    });
  }

  Future<void> _startService() async {
    if (_isStartingService) return;

    setState(() {
      _isStartingService = true;
    });

    try {
      _connectionService.updateUrls(_apiController.text, _wsController.text);

      final success = await _connectionService.checkAndConnect();
      if (!success) {
        if (mounted) {
          _showTopBanner(
            '无法连接到服务器，请检查服务器地址和状态',
            isError: true,
          );
        }
        return;
      }

      if (mounted) {
        _showTopBanner('服务已启动', isError: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStartingService = false;
        });
      }
    }
  }

  Future<void> _stopService() async {
    await _connectionService.stop();
    if (mounted) {
      _showTopBanner('服务已停止', isError: false);
    }
  }

  void _hideNotification() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showTopBanner(String message, {bool isError = false}) {
    _hideNotification();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isError ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      isError ? Icons.error : Icons.check_circle,
                      color: isError ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: isError ? Colors.red[900] : Colors.green[900],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _hideNotification,
                      color: isError ? Colors.red[300] : Colors.green[300],
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // 3秒后自动关闭
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _hideNotification();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'AWAttacker',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: theme.colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          onTap: _onTabTapped,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          labelPadding: EdgeInsets.zero,
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
                    color: !_hasOverlayPermission ? Colors.grey[400] : null),
                text: '规则',
                height: 60,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: !_hasOverlayPermission
            ? const NeverScrollableScrollPhysics()
            : null,
        children: [
          // 配置页面
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PermissionCard(
                  hasPermission: _hasOverlayPermission,
                  onRequestPermission: _requestOverlayPermission,
                ),
                const SizedBox(height: 12),
                ServerConfigCard(
                  apiController: _apiController,
                  wsController: _wsController,
                  enabled: _hasOverlayPermission,
                  onApiChanged: (_) => _saveUrls(),
                  onWsChanged: (_) => _saveUrls(),
                ),
                const SizedBox(height: 12),
                const ServerStatusCard(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _hasOverlayPermission && !_isStartingService
                        ? (_isServiceRunning ? _stopService : _startService)
                        : null,
                    icon: _isStartingService
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _hasOverlayPermission
                                    ? Colors.white
                                    : Colors.grey[400]!,
                              ),
                            ),
                          )
                        : Icon(
                            _isServiceRunning
                                ? Icons.stop_circle_outlined
                                : Icons.play_circle_outline,
                            color: _hasOverlayPermission
                                ? Colors.white
                                : Colors.grey[400],
                          ),
                    label: Text(
                      _isStartingService
                          ? '正在启动...'
                          : (_isServiceRunning ? '停止服务' : '启动服务'),
                      style: TextStyle(
                        color: _hasOverlayPermission
                            ? Colors.white
                            : Colors.grey[400],
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isServiceRunning
                          ? Colors.red
                          : theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 规则页面
          const RuleListPage(),
        ],
      ),
    );
  }
}
