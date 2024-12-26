import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';

class ServerStatusCard extends StatelessWidget {
  const ServerStatusCard({super.key});

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return '已连接';
      case ConnectionStatus.disconnected:
        return '未连接';
      case ConnectionStatus.connecting:
        return '连接中...';
      case ConnectionStatus.error:
        return '连接错误';
    }
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Consumer<ConnectionProvider>(
            builder: (context, provider, child) {
              final status = provider.apiStatus;
              return ListTile(
                leading: Icon(Icons.api, color: theme.colorScheme.primary),
                title: const Text('API 服务器'),
                subtitle: Text(
                  _getStatusText(status),
                  style: TextStyle(color: _getStatusColor(status)),
                ),
                trailing: status == ConnectionStatus.connecting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary),
                        ),
                      )
                    : Icon(
                        status == ConnectionStatus.connected
                            ? Icons.check_circle
                            : status == ConnectionStatus.error
                                ? Icons.error
                                : Icons.offline_bolt,
                        color: _getStatusColor(status),
                      ),
              );
            },
          ),
          Divider(color: Colors.grey[200]),
          Consumer<ConnectionProvider>(
            builder: (context, provider, child) {
              final status = provider.wsStatus;
              return ListTile(
                leading:
                    Icon(Icons.swap_calls, color: theme.colorScheme.primary),
                title: const Text('WebSocket 服务器'),
                subtitle: Text(
                  _getStatusText(status),
                  style: TextStyle(color: _getStatusColor(status)),
                ),
                trailing: status == ConnectionStatus.connecting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary),
                        ),
                      )
                    : Icon(
                        status == ConnectionStatus.connected
                            ? Icons.check_circle
                            : status == ConnectionStatus.error
                                ? Icons.error
                                : Icons.offline_bolt,
                        color: _getStatusColor(status),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}
