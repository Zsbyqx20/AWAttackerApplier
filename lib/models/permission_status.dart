import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// 权限类型枚举
enum PermissionType {
  overlay,
  accessibility,
}

/// 权限状态模型
class PermissionStatus {
  final PermissionType type;
  final bool isGranted;
  final String title;
  final String grantedText;
  final String notGrantedText;

  const PermissionStatus({
    required this.type,
    required this.isGranted,
    required this.title,
    required this.grantedText,
    required this.notGrantedText,
  });

  factory PermissionStatus.overlay({
    required bool isGranted,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return PermissionStatus(
      type: PermissionType.overlay,
      isGranted: isGranted,
      title: l10n.overlayPermissionStatus,
      grantedText: l10n.permissionGranted,
      notGrantedText: l10n.permissionNotGranted,
    );
  }

  factory PermissionStatus.accessibility({
    required bool isGranted,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return PermissionStatus(
      type: PermissionType.accessibility,
      isGranted: isGranted,
      title: l10n.accessibilityPermissionStatus,
      grantedText: l10n.permissionGranted,
      notGrantedText: l10n.permissionNotGranted,
    );
  }
}
