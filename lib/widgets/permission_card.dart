import 'package:flutter/material.dart';

import 'package:awattackerapplier/l10n/app_localizations.dart';

import '../models/permission_status.dart';

class PermissionCard extends StatefulWidget {
  const PermissionCard({
    super.key,
    required this.permissions,
    required this.onRequestPermission,
  });
  static const double _iconSize = 28.0;
  static const double _progressSize = 24.0;
  static const double _progressStrokeWidth = 2.0;
  static const double _buttonPaddingHorizontal = 24.0;
  static const double _buttonPaddingVertical = 12.0;
  static const double _buttonRadius = 6.0;
  static const double _cardRadius = 12.0;
  static const double _cardElevation = 1.0;

  final List<PermissionStatus> permissions;
  final Future<void> Function(PermissionType) onRequestPermission;

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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      debugPrint('Error: AppLocalizations not found');

      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ListTile(
          leading: Icon(
            status.type == PermissionType.overlay
                ? Icons.picture_in_picture
                : Icons.accessibility_new,
            color: theme.colorScheme.primary,
            size: PermissionCard._iconSize,
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
                      width: PermissionCard._progressSize,
                      height: PermissionCard._progressSize,
                      child: CircularProgressIndicator(
                        strokeWidth: PermissionCard._progressStrokeWidth,
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
                          horizontal: PermissionCard._buttonPaddingHorizontal,
                          vertical: PermissionCard._buttonPaddingVertical,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(PermissionCard._buttonRadius),
                          ),
                        ),
                      ),
                      child: Text(
                        l10n.grantPermission,
                      ),
                    )
              : Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: PermissionCard._iconSize,
                ),
        ),
        if (widget.permissions.last != status) Divider(color: Colors.grey[200]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: PermissionCard._cardElevation,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            const BorderRadius.all(Radius.circular(PermissionCard._cardRadius)),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: widget.permissions.map(_buildPermissionItem).toList(),
      ),
    );
  }
}
