import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/connection_provider.dart';

class ConnectionStatusChip extends StatelessWidget {
  const ConnectionStatusChip({
    super.key,
    required this.status,
  });

  /// 连接状态图标大小
  static const double iconSize = 16;

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }
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
      avatar: Icon(icon, color: Colors.white, size: iconSize),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
    );
  }
}
