/// 悬浮窗操作异常
class OverlayException implements Exception {
  /// 错误代码
  final String code;

  /// 错误消息
  final String message;

  /// 详细信息
  final dynamic details;

  const OverlayException(this.code, this.message, [this.details]);

  /// 预定义错误代码：权限错误
  static const String PERMISSION_DENIED = 'PERMISSION_DENIED';

  /// 预定义错误代码：悬浮窗不存在
  static const String OVERLAY_NOT_FOUND = 'OVERLAY_NOT_FOUND';

  /// 预定义错误代码：创建失败
  static const String CREATE_FAILED = 'CREATE_FAILED';

  /// 预定义错误代码：更新失败
  static const String UPDATE_FAILED = 'UPDATE_FAILED';

  /// 预定义错误代码：移除失败
  static const String REMOVE_FAILED = 'REMOVE_FAILED';

  /// 创建权限错误异常
  factory OverlayException.permissionDenied([String? details]) {
    return OverlayException(
      PERMISSION_DENIED,
      '悬浮窗权限未授予',
      details,
    );
  }

  /// 创建悬浮窗不存在异常
  factory OverlayException.overlayNotFound(String id) {
    return OverlayException(
      OVERLAY_NOT_FOUND,
      '悬浮窗不存在: $id',
    );
  }

  /// 创建悬浮窗创建失败异常
  factory OverlayException.createFailed(String message, [dynamic details]) {
    return OverlayException(
      CREATE_FAILED,
      '创建悬浮窗失败: $message',
      details,
    );
  }

  /// 创建悬浮窗更新失败异常
  factory OverlayException.updateFailed(String message, [dynamic details]) {
    return OverlayException(
      UPDATE_FAILED,
      '更新悬浮窗失败: $message',
      details,
    );
  }

  /// 创建悬浮窗移除失败异常
  factory OverlayException.removeFailed(String message, [dynamic details]) {
    return OverlayException(
      REMOVE_FAILED,
      '移除悬浮窗失败: $message',
      details,
    );
  }

  @override
  String toString() {
    if (details != null) {
      return 'OverlayException: [$code] $message\nDetails: $details';
    }
    return 'OverlayException: [$code] $message';
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'message': message,
      if (details != null) 'details': details,
    };
  }
}
