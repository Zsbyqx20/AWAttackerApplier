import 'package:flutter/material.dart';
import '../models/permission_status.dart';

class PermissionCard extends StatefulWidget {
  final List<PermissionStatus> permissions;
  final Function(PermissionType) onRequestPermission;

  const PermissionCard({
    super.key,
    required this.permissions,
    required this.onRequestPermission,
  });

  @override
  State<PermissionCard> createState() => _PermissionCardState();
}

class _PermissionCardState extends State<PermissionCard> {
  final Map<PermissionType, bool> _isRequesting = {};

  Future<void> _requestPermission(PermissionType type) async {
    if (_isRequesting[type] == true) return;

    setState(() {
      _isRequesting[type] = true;
    });

    try {
      await widget.onRequestPermission(type);
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting[type] = false;
        });
      }
    }
  }

  Widget _buildPermissionItem(PermissionStatus status) {
    final theme = Theme.of(context);
    final isRequesting = _isRequesting[status.type] == true;

    return Column(
      children: [
        ListTile(
          leading: Icon(
            status.type == PermissionType.overlay
                ? Icons.picture_in_picture
                : Icons.accessibility_new,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          title: Text(status.title),
          subtitle: Text(
            status.isGranted ? status.grantedText : status.notGrantedText,
            style: TextStyle(
              color: status.isGranted ? Colors.green : Colors.grey[600],
            ),
          ),
          trailing: !status.isGranted
              ? isRequesting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => _requestPermission(status.type),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        status.type == PermissionType.overlay ? '授权' : '设置',
                      ),
                    )
              : Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 28,
                ),
        ),
        if (widget.permissions.last != status) Divider(color: Colors.grey[200]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        children: widget.permissions.map(_buildPermissionItem).toList(),
      ),
    );
  }
}
