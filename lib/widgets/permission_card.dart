import 'package:flutter/material.dart';

class PermissionCard extends StatefulWidget {
  final bool hasPermission;
  final VoidCallback onRequestPermission;

  const PermissionCard({
    super.key,
    required this.hasPermission,
    required this.onRequestPermission,
  });

  @override
  State<PermissionCard> createState() => _PermissionCardState();
}

class _PermissionCardState extends State<PermissionCard> {
  bool _isCheckingPermission = false;

  Future<void> _requestPermission() async {
    if (_isCheckingPermission) return;

    setState(() {
      _isCheckingPermission = true;
    });

    try {
      widget.onRequestPermission();
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPermission = false;
        });
      }
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
      child: ListTile(
        leading: Icon(
          Icons.picture_in_picture,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        title: const Text('悬浮窗权限'),
        subtitle: Text(
          widget.hasPermission ? '已授权' : '未授权',
          style: TextStyle(
            color: widget.hasPermission ? Colors.green : Colors.grey[600],
          ),
        ),
        trailing: !widget.hasPermission
            ? _isCheckingPermission
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
                    onPressed: _requestPermission,
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
                    child: const Text('授权'),
                  )
            : Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
      ),
    );
  }
}
