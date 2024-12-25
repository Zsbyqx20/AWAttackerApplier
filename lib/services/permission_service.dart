import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class PermissionService {
  static Future<bool> checkOverlayPermission() async {
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestOverlayPermission() async {
    try {
      final result = await FlutterOverlayWindow.requestPermission();
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
