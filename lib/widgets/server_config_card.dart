import 'package:flutter/material.dart';

class ServerConfigCard extends StatelessWidget {
  final TextEditingController apiController;
  final TextEditingController wsController;
  final bool enabled;
  final Function(String) onApiChanged;
  final Function(String) onWsChanged;

  const ServerConfigCard({
    super.key,
    required this.apiController,
    required this.wsController,
    required this.enabled,
    required this.onApiChanged,
    required this.onWsChanged,
  });

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: apiController,
              onChanged: onApiChanged,
              enabled: enabled,
              decoration: InputDecoration(
                labelText: 'API服务器地址',
                hintText: 'http://10.0.2.2:8000',
                filled: true,
                fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
                prefixIcon: Icon(Icons.link,
                    color: enabled ? theme.colorScheme.primary : Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: wsController,
              onChanged: onWsChanged,
              enabled: enabled,
              decoration: InputDecoration(
                labelText: 'WebSocket服务器地址',
                hintText: 'ws://10.0.2.2:8000/ws',
                filled: true,
                fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
                prefixIcon: Icon(Icons.swap_calls,
                    color: enabled ? theme.colorScheme.primary : Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
