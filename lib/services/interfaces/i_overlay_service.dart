import '../../models/overlay_style.dart';
import '../../models/overlay_result.dart';
import '../../exceptions/overlay_exception.dart';

/// 悬浮窗服务接口
/// 定义了所有悬浮窗操作的基本方法
abstract class IOverlayService {
  /// 检查悬浮窗权限
  ///
  /// 返回true表示已获得权限，false表示未获得权限
  Future<bool> checkPermission();

  /// 请求悬浮窗权限
  ///
  /// 返回true表示成功获取权限，false表示获取失败
  Future<bool> requestPermission();

  /// 创建新的悬浮窗
  ///
  /// [id] 悬浮窗的唯一标识符
  /// [style] 悬浮窗的样式配置
  ///
  /// 返回创建结果，包含是否成功和错误信息
  Future<OverlayResult> createOverlay(String id, OverlayStyle style);

  /// 更新已存在的悬浮窗
  ///
  /// [id] 要更新的悬浮窗的唯一标识符
  /// [style] 新的样式配置
  ///
  /// 如果悬浮窗不存在，将抛出 [OverlayException]
  Future<OverlayResult> updateOverlay(String id, OverlayStyle style);

  /// 移除指定的悬浮窗
  ///
  /// [id] 要移除的悬浮窗的唯一标识符
  ///
  /// 如果悬浮窗不存在，将返回false
  Future<bool> removeOverlay(String id);

  /// 移除所有悬浮窗
  Future<void> removeAllOverlays();

  /// 获取当前显示的所有悬浮窗ID
  List<String> getActiveOverlayIds();

  /// 检查指定ID的悬浮窗是否存在
  ///
  /// [id] 要检查的悬浮窗的唯一标识符
  bool hasOverlay(String id);
}
