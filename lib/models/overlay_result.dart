/// 悬浮窗操作结果
class OverlayResult {
  /// 操作是否成功
  final bool success;

  /// 错误信息，当操作失败时提供
  final String? error;

  /// 额外的数据信息
  final Map<String, dynamic>? data;

  const OverlayResult({
    required this.success,
    this.error,
    this.data,
  });

  /// 创建成功结果
  factory OverlayResult.success([Map<String, dynamic>? data]) {
    return OverlayResult(
      success: true,
      data: data,
    );
  }

  /// 创建失败结果
  factory OverlayResult.failure(String error, [Map<String, dynamic>? data]) {
    return OverlayResult(
      success: false,
      error: error,
      data: data,
    );
  }

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (error != null) 'error': error,
      if (data != null) 'data': data,
    };
  }

  /// 从JSON格式创建实例
  factory OverlayResult.fromJson(Map<String, dynamic> json) {
    return OverlayResult(
      success: json['success'] as bool,
      error: json['error'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'OverlayResult{success: $success, error: $error, data: $data}';
  }
}
