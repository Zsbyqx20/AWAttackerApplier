import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/foundation.dart';

class BackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'awattacker_service',
        initialNotificationTitle: 'AWAttacker Service',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // 更新前台服务通知
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "AWAttacker Service",
        content: "Service is running",
      );
    }

    if (kDebugMode) {
      print('Background service started');
    }

    // 定期发送心跳以保持服务活跃
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "AWAttacker Service",
          content: "Running for ${timer.tick} seconds",
        );
      }

      // 发送状态更新到主应用
      service.invoke(
        'update',
        {
          'current_tick': timer.tick,
          'status': 'running',
        },
      );
    });
  }
}
