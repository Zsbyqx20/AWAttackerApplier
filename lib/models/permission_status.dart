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

  factory PermissionStatus.overlay({required bool isGranted}) {
    return PermissionStatus(
      type: PermissionType.overlay,
      isGranted: isGranted,
      title: '悬浮窗权限',
      grantedText: '已授权',
      notGrantedText: '未授权',
    );
  }

  factory PermissionStatus.accessibility({required bool isGranted}) {
    return PermissionStatus(
      type: PermissionType.accessibility,
      isGranted: isGranted,
      title: '无障碍服务',
      grantedText: '已启用',
      notGrantedText: '未启用',
    );
  }
}
