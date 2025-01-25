import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../models/permission_status.dart';
import '../providers/connection_provider.dart';
import '../widgets/permission_card.dart';
import '../widgets/grpc_config_card.dart';

class ServerConfigPage extends StatefulWidget {
  const ServerConfigPage({
    super.key,
    required this.onPermissionsChanged,
  });
  final void Function({bool? overlayPermission, bool? accessibilityPermission})
      onPermissionsChanged;

  @override
  State<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage>
    with WidgetsBindingObserver {
  final _channel =
      const MethodChannel('com.mobilellm.awattackerapplier/overlay_service');

  bool _hasOverlayPermission = false;
  bool _hasAccessibilityPermission = false;
  bool _isStartingService = false;

  final _hostController = TextEditingController(text: 'auto');
  final _portController = TextEditingController(text: '50051');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    _setupPermissionListener();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ConnectionProvider>();
      _hostController.text = provider.grpcHost;
      _portController.text = provider.grpcPort.toString();
    });
  }

  void _setupPermissionListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPermissionChanged') {
        final permissions =
            jsonDecode(call.arguments as String) as Map<String, dynamic>;
        final hasOverlay = permissions['overlay'] as bool;
        final hasAccessibility = permissions['accessibility'] as bool;

        if (mounted) {
          setState(() {
            _hasOverlayPermission = hasOverlay;
            _hasAccessibilityPermission = hasAccessibility;
          });
          widget.onPermissionsChanged(
            overlayPermission: hasOverlay,
            accessibilityPermission: hasAccessibility,
          );
        }
      }
    });
  }

  Future<void> _checkPermissions() async {
    try {
      final result = await _channel.invokeMethod<String>('checkAllPermissions');
      if (result != null) {
        final permissions = jsonDecode(result) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _hasOverlayPermission = permissions['overlay'] as bool;
            _hasAccessibilityPermission = permissions['accessibility'] as bool;
          });
          widget.onPermissionsChanged(
            overlayPermission: _hasOverlayPermission,
            accessibilityPermission: _hasAccessibilityPermission,
          );
        }
      }
    } catch (e) {
      debugPrint('检查权限时发生错误: $e');
    }
  }

  Future<void> _requestPermission(PermissionType type) async {
    try {
      switch (type) {
        case PermissionType.overlay:
          await _channel.invokeMethod<bool>('requestOverlayPermission');
          break;
        case PermissionType.accessibility:
          await _channel.invokeMethod<bool>('requestAccessibilityPermission');
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请求权限时发生错误: $e')),
        );
      }
    }
  }

  Future<void> _startService() async {
    if (_isStartingService) return;

    setState(() {
      _isStartingService = true;
    });

    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return;
    }

    try {
      final provider = context.read<ConnectionProvider>();
      final connected = await provider.checkAndConnect();

      if (!connected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.grpcConnectionError,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              side: BorderSide(color: Colors.grey.shade200),
            ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error starting service: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
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

  void _updateGrpcConfig(ConnectionProvider provider) {
    if (provider.isServiceRunning) return;

    final host = _hostController.text;
    final portStr = _portController.text;

    if (portStr.isEmpty) return;

    final port = int.tryParse(portStr);
    // ignore: no-magic-number
    if (port == null || port <= 0 || port > 65535) {
      final l10n = AppLocalizations.of(context);
      if (l10n == null) {
        debugPrint('Error: AppLocalizations not found');

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.grpcInvalidPort),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    provider.setGrpcConfig(host, port);
  }

  void _updateControllersFromProvider(ConnectionProvider provider) {
    if (_hostController.text != provider.grpcHost) {
      _hostController.text = provider.grpcHost;
    }
    if (_portController.text != provider.grpcPort.toString()) {
      _portController.text = provider.grpcPort.toString();
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }
    final provider = context.watch<ConnectionProvider>();
    _updateControllersFromProvider(provider);
    final allPermissionsGranted =
        _hasOverlayPermission && _hasAccessibilityPermission;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PermissionCard(
            permissions: [
              PermissionStatus.overlay(
                isGranted: _hasOverlayPermission,
                context: context,
              ),
              PermissionStatus.accessibility(
                isGranted: _hasAccessibilityPermission,
                context: context,
              ),
            ],
            onRequestPermission: _requestPermission,
          ),
          const SizedBox(height: 16),
          GrpcConfigCard(
            provider: provider,
            hostController: _hostController,
            portController: _portController,
            onConfigChanged: _updateGrpcConfig,
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 1,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              side: BorderSide(
                color: Colors.grey.shade100,
                width: 1,
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: ElevatedButton.icon(
                  onPressed: allPermissionsGranted && !_isStartingService
                      ? (provider.isServiceRunning
                          ? _stopService
                          : _startService)
                      : null,
                  icon: _isStartingService
                      ? SizedBox(
                          // ignore: no-magic-number
                          width: 20,
                          // ignore: no-magic-number
                          height: 20,
                          child: CircularProgressIndicator(
                            // ignore: no-magic-number
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              allPermissionsGranted
                                  ? Colors.white
                                  : Colors.grey.shade400,
                            ),
                          ),
                        )
                      : Container(
                          // ignore: no-magic-number
                          width: 32,
                          // ignore: no-magic-number
                          height: 32,
                          decoration: BoxDecoration(
                            // ignore: no-magic-number
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Icon(
                            provider.isServiceRunning
                                ? Icons.power_settings_new_rounded
                                : Icons.play_circle_outline_rounded,
                            // ignore: no-magic-number
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                  label: Text(
                    provider.isServiceRunning
                        ? l10n.stopService
                        : l10n.startService,
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
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade400,
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
