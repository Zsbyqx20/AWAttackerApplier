import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/storage_keys.dart';
import '../providers/connection_provider.dart';
import '../repositories/storage_repository.dart';
import '../services/overlay_service.dart';
import '../widgets/permission_card.dart';
import '../widgets/server_config_card.dart';
import '../widgets/server_status_card.dart';

class ServerConfigPage extends StatefulWidget {
  final Function(bool) onPermissionChanged;

  const ServerConfigPage({
    super.key,
    required this.onPermissionChanged,
  });

  @override
  State<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage>
    with WidgetsBindingObserver {
  final TextEditingController _apiController = TextEditingController();
  final TextEditingController _wsController = TextEditingController();
  final StorageRepository _storageRepository;
  final _channel =
      const MethodChannel('com.mobilellm.awattackapplier/overlay_service');

  bool _hasOverlayPermission = false;
  bool _isCheckingPermission = false;
  bool _isStartingService = false;

  _ServerConfigPageState() : _storageRepository = StorageRepository();

  @override
  void initState() {
    super.initState();
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
          widget.onPermissionChanged(hasPermission);
        }
      }
    });
  }

  @override
  void dispose() {
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
        widget.onPermissionChanged(hasPermission);
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
        widget.onPermissionChanged(granted);
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

    return SingleChildScrollView(
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
          Card(
            elevation: 1,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.grey[100]!,
                width: 1,
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(2),
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
                      : Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            provider.isServiceRunning
                                ? Icons.power_settings_new_rounded
                                : Icons.play_circle_outline_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                  label: Text(
                    provider.isServiceRunning ? '停止服务' : '启动服务',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.isServiceRunning
                        ? Colors.red[400]
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
