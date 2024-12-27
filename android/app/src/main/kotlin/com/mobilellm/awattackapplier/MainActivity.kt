package com.mobilellm.awattackapplier

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val OVERLAY_PERMISSION_REQUEST_CODE = 1
        private const val CHANNEL = "com.mobilellm.awattackapplier/overlay_service"
    }

    private var pendingResult: MethodChannel.Result? = null
    private lateinit var channel: MethodChannel
    private var windowManagerHelper: WindowManagerHelper? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        windowManagerHelper = WindowManagerHelper(this)
        
        val messenger = flutterEngine?.dartExecutor?.binaryMessenger
        if (messenger != null) {
            channel = MethodChannel(messenger, CHANNEL)
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkOverlayPermission" -> {
                        result.success(checkOverlayPermission())
                    }
                    "requestOverlayPermission" -> {
                        pendingResult = result
                        requestOverlayPermission()
                    }
                    "createOverlay" -> {
                        try {
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
                        } catch (e: Exception) {
                            Log.e(TAG, "创建悬浮窗时发生错误", e)
                            result.error("CREATE_FAILED", e.message, null)
                        }
                    }
                    "updateOverlay" -> {
                        try {
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
                        } catch (e: Exception) {
                            Log.e(TAG, "更新悬浮窗时发生错误", e)
                            result.error("UPDATE_FAILED", e.message, null)
                        }
                    }
                    "removeOverlay" -> {
                        try {
                            val id = call.argument<String>("id")
                            if (id != null) {
                                windowManagerHelper?.removeOverlay(id)
                                result.success(true)
                            } else {
                                result.error("INVALID_ARGUMENTS", "Invalid arguments", null)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "移除悬浮窗时发生错误", e)
                            result.error("REMOVE_FAILED", e.message, null)
                        }
                    }
                    "removeAllOverlays" -> {
                        try {
                            windowManagerHelper?.removeAllOverlays()
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "移除所有悬浮窗时发生错误", e)
                            result.error("REMOVE_ALL_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        } else {
            Log.e(TAG, "Failed to initialize MethodChannel: BinaryMessenger is null")
        }
    }

    override fun onResume() {
        super.onResume()
        // 每次回到前台时检查权限状态并广播
        val hasPermission = checkOverlayPermission()
        if (::channel.isInitialized) {
            channel.invokeMethod("onPermissionChanged", hasPermission)
        }
    }

    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            try {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
            } catch (e: Exception) {
                Log.e(TAG, "请求悬浮窗权限时发生错误", e)
                pendingResult?.error("PERMISSION_REQUEST_FAILED", e.message, null)
                pendingResult = null
            }
        } else {
            pendingResult?.success(true)
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == OVERLAY_PERMISSION_REQUEST_CODE) {
            val hasPermission = checkOverlayPermission()
            // 通知权限结果
            pendingResult?.success(hasPermission)
            pendingResult = null
            // 广播权限变化
            if (::channel.isInitialized) {
                channel.invokeMethod("onPermissionChanged", hasPermission)
            }
            
            // 如果获得了权限，启动悬浮窗服务
            if (hasPermission) {
                startService(Intent(this, OverlayService::class.java))
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        windowManagerHelper?.removeAllOverlays()
        windowManagerHelper = null
    }
}
