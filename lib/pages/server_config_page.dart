import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/storage_keys.dart';
import '../pages/rule/rule_list_page.dart';
import '../providers/connection_provider.dart';
import '../repositories/storage_repository.dart';
import '../services/overlay_service.dart';
import '../widgets/permission_card.dart';
import '../widgets/server_config_card.dart';
import '../widgets/server_status_card.dart';

class ServerConfigPage extends StatefulWidget {
  const ServerConfigPage({super.key});

  @override
  State<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final TextEditingController _apiController = TextEditingController();
  final TextEditingController _wsController = TextEditingController();
  final StorageRepository _storageRepository;
  final _channel = const MethodChannel('com.example.awattacker/overlay');

  bool _hasOverlayPermission = false;
  bool _isCheckingPermission = false;
  late TabController _tabController;
  bool _isStartingService = false;
  OverlayEntry? _overlayEntry;

  _ServerConfigPageState() : _storageRepository = StorageRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addObserver(this);
    _loadUrls();
    _checkOverlayPermission();
    _setupPermissionListener();
  }

  void _setupPermissionListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPermissionChanged') {
        final bool hasPermission = call.arguments as bool;
        if (mounted) {
          setState(() {
            _hasOverlayPermission = hasPermission;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiController.dispose();
    _wsController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkOverlayPermission();
    }
  }

  Future<void> _loadUrls() async {
    await _storageRepository.init();
    final urls = await _storageRepository.loadUrls();
    if (mounted) {
      setState(() {
        _apiController.text = urls[StorageKeys.apiUrlKey]!;
        _wsController.text = urls[StorageKeys.wsUrlKey]!;
      });
    }
  }

  Future<void> _saveUrls() async {
    await _storageRepository.saveUrls(
      apiUrl: _apiController.text,
      wsUrl: _wsController.text,
    );
  }

  Future<bool> _checkOverlayPermission() async {
    if (_isCheckingPermission) return false;

    setState(() {
      _isCheckingPermission = true;
    });

    try {
      final hasPermission = await OverlayService().checkPermission();
      if (mounted) {
        setState(() {
          _hasOverlayPermission = hasPermission;
        });
      }
      return hasPermission;
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
      final granted = await OverlayService().requestPermission();
      if (mounted) {
        setState(() {
          _hasOverlayPermission = granted;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(granted ? '权限已授予' : '权限请求被拒绝'),
          ),
        );
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

  void _handleTabChange() {
    if (!_hasOverlayPermission && _tabController.index > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先授予悬浮窗权限')),
      );
      _tabController.animateTo(0);
    }
  }

  Future<void> _startService() async {
    if (_isStartingService) return;

    setState(() {
      _isStartingService = true;
    });

    try {
      final provider = context.read<ConnectionProvider>();
      provider.updateUrls(_apiController.text, _wsController.text);
      await provider.checkAndConnect();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('启动服务时发生错误: $e')),
        );
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
    if (_isStartingService) return;

    setState(() {
      _isStartingService = true;
    });

    try {
      final provider = context.read<ConnectionProvider>();
      await provider.stop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止服务时发生错误: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStartingService = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConnectionProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('AW Attacker'),
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
                        ? (provider.isServiceRunning
                            ? _stopService
                            : _startService)
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
                            provider.isServiceRunning
                                ? Icons.stop_outlined
                                : Icons.play_arrow_outlined,
                            color: _hasOverlayPermission
                                ? Colors.white
                                : Colors.grey[400],
                          ),
                    label: Text(
                      provider.isServiceRunning ? '停止服务' : '启动服务',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: provider.isServiceRunning
                          ? Colors.red[400]
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[400],
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
