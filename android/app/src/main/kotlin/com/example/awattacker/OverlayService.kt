package com.example.awattacker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint
import org.json.JSONObject

class OverlayService : Service() {
    private var windowManagerHelper: WindowManagerHelper? = null
    private var methodChannel: MethodChannel? = null
    private var flutterEngine: FlutterEngine? = null

    companion object {
        private const val TAG = "OverlayService"
        private const val CHANNEL_ID = "overlay_service_channel"
        private const val NOTIFICATION_ID = 1
        private const val METHOD_CHANNEL_NAME = "com.example.awattacker/overlay_service"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate")
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        
        // 初始化WindowManager
        windowManagerHelper = WindowManagerHelper(this)
        
        // 初始化Flutter引擎
        initializeFlutterEngine()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Overlay Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("AWAttacker")
        .setContentText("悬浮窗服务运行中")
        .setSmallIcon(android.R.drawable.ic_dialog_info)
        .build()

    private fun initializeFlutterEngine() {
        flutterEngine = FlutterEngine(this).apply {
            dartExecutor.executeDartEntrypoint(
                DartEntrypoint.createDefault()
            )
            setupMethodChannel()
        }
    }

    private fun setupMethodChannel() {
        val messenger = flutterEngine?.dartExecutor?.binaryMessenger
        if (messenger != null) {
            methodChannel = MethodChannel(messenger, METHOD_CHANNEL_NAME).apply {
                setMethodCallHandler { call, result ->
                    try {
                        when (call.method) {
                            "createOverlay" -> {
                                val id = call.argument<String>("id")
                                val style = call.argument<Map<String, Any>>("style")
                                if (id != null && style != null) {
                                    windowManagerHelper?.createOverlay(id, style)
                                    result.success(mapOf(
                                        "success" to true
                                    ))
                                } else {
                                    result.error("INVALID_ARGUMENTS", "Invalid arguments", null)
                                }
                            }
                            "updateOverlay" -> {
                                val id = call.argument<String>("id")
                                val style = call.argument<Map<String, Any>>("style")
                                if (id != null && style != null) {
                                    windowManagerHelper?.updateOverlay(id, style)
                                    result.success(mapOf(
                                        "success" to true
                                    ))
                                } else {
                                    result.error("INVALID_ARGUMENTS", "Invalid arguments", null)
                                }
                            }
                            "removeOverlay" -> {
                                val id = call.argument<String>("id")
                                if (id != null) {
                                    windowManagerHelper?.removeOverlay(id)
                                    result.success(true)
                                } else {
                                    result.error("INVALID_ARGUMENTS", "Invalid arguments", null)
                                }
                            }
                            "removeAllOverlays" -> {
                                windowManagerHelper?.removeAllOverlays()
                                result.success(true)
                            }
                            else -> result.notImplemented()
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "处理Method Channel调用时发生错误", e)
                        result.error("OPERATION_FAILED", e.message, null)
                    }
                }
            }
        } else {
            Log.e(TAG, "Failed to initialize MethodChannel: BinaryMessenger is null")
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.d(TAG, "onDestroy")
        super.onDestroy()
        windowManagerHelper?.removeAllOverlays()
        flutterEngine?.destroy()
        methodChannel?.setMethodCallHandler(null)
    }
} 