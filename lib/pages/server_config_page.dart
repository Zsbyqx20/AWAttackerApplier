import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../models/permission_status.dart';
import '../providers/connection_provider.dart';
import '../widgets/permission_card.dart';

class ServerConfigPage extends StatefulWidget {
  final void Function({bool? overlayPermission, bool? accessibilityPermission})
      onPermissionsChanged;

  const ServerConfigPage({
    super.key,
    required this.onPermissionsChanged,
  });

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

    final provider = context.read<ConnectionProvider>();
    _hostController.text = provider.grpcHost;
    _portController.text = provider.grpcPort.toString();
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

    final l10n = AppLocalizations.of(context)!;

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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildGrpcConfigCard(ConnectionProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final isServiceRunning = provider.isServiceRunning;
    final connectionStatus = provider.status;

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dns_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.grpcSettings,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                _buildConnectionStatusChip(connectionStatus, l10n),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hostController,
              decoration: InputDecoration(
                labelText: l10n.grpcHost,
                hintText: 'auto',
                border: const OutlineInputBorder(),
                enabled: !isServiceRunning,
              ),
              onChanged: (value) => _updateGrpcConfig(provider),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              decoration: InputDecoration(
                labelText: l10n.grpcPort,
                hintText: '50051',
                border: const OutlineInputBorder(),
                enabled: !isServiceRunning,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => _updateGrpcConfig(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusChip(
      ConnectionStatus status, AppLocalizations l10n) {
    Color chipColor;
    String label;
    IconData icon;

    switch (status) {
      case ConnectionStatus.connected:
        chipColor = Colors.green;
        label = l10n.grpcConnected;
        icon = Icons.check_circle;
        break;
      case ConnectionStatus.disconnected:
        chipColor = Colors.grey;
        label = l10n.grpcDisconnected;
        icon = Icons.cancel;
        break;
      case ConnectionStatus.connecting:
        chipColor = Colors.orange;
        label = l10n.grpcConnecting;
        icon = Icons.sync;
        break;
      case ConnectionStatus.disconnecting:
        chipColor = Colors.orange;
        label = l10n.grpcDisconnecting;
        icon = Icons.sync;
        break;
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
    );
  }

  void _updateGrpcConfig(ConnectionProvider provider) {
    if (provider.isServiceRunning) return;

    final host = _hostController.text;
    final portStr = _portController.text;

    if (portStr.isEmpty) return;

    final port = int.tryParse(portStr);
    if (port == null || port <= 0 || port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.grpcInvalidPort),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    provider.setGrpcConfig(host, port);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ConnectionProvider>();
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
          _buildGrpcConfigCard(provider),
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
                  onPressed: allPermissionsGranted && !_isStartingService
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
                              allPermissionsGranted
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
