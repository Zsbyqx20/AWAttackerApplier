import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:awattackerapplier/l10n/app_localizations.dart';

import '../providers/connection_provider.dart';
import 'connection_status_chip.dart';

class GrpcConfigCard extends StatelessWidget {
  const GrpcConfigCard({
    super.key,
    required this.provider,
    required this.hostController,
    required this.portController,
    required this.onConfigChanged,
  });

  final ConnectionProvider provider;
  final TextEditingController hostController;
  final TextEditingController portController;
  final void Function(ConnectionProvider) onConfigChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }
    final isServiceRunning = provider.isServiceRunning;
    final connectionStatus = provider.status;

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(
          color: Colors.grey.shade100,
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
                ConnectionStatusChip(status: connectionStatus),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hostController,
              decoration: InputDecoration(
                labelText: l10n.grpcHost,
                hintText: 'auto',
                border: const OutlineInputBorder(),
                enabled: !isServiceRunning,
              ),
              onChanged: (_) => onConfigChanged(provider),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portController,
              decoration: InputDecoration(
                labelText: l10n.grpcPort,
                hintText: '50051',
                border: const OutlineInputBorder(),
                enabled: !isServiceRunning,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => onConfigChanged(provider),
            ),
          ],
        ),
      ),
    );
  }
}
