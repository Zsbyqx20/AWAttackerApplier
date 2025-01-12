package com.mobilellm.awattackerapplier

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.os.Handler
import android.os.Looper

class ServiceControlReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "ServiceControlReceiver"
        const val ACTION_START_SERVICE = "com.mobilellm.awattackerapplier.START_SERVICE"
        const val ACTION_STOP_SERVICE = "com.mobilellm.awattackerapplier.STOP_SERVICE"
        
        // 结果码
        const val RESULT_SUCCESS = 1           // 成功通知 Flutter
        const val RESULT_PERMISSION_DENIED = 2 // 权限不足
        const val RESULT_INVALID_STATE = 3     // 服务状态不适合执行操作
        const val RESULT_ERROR = 4             // 其他错误
    }

    init {
        Log.i(TAG, "ServiceControlReceiver 已初始化")
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.i(TAG, "收到广播: ${intent.action}")
        
        // 1. 获取 MainActivity 实例
        val mainActivity = context as? MainActivity
        if (mainActivity == null) {
            Log.w(TAG, "无法获取 MainActivity 实例")
            setResult(RESULT_ERROR, "No MainActivity instance", null)
            return
        }

        // 2. 检查权限
        val hasOverlayPermission = mainActivity.checkOverlayPermission()
        val hasAccessibilityPermission = mainActivity.checkAccessibilityPermission()
        
        if (!hasOverlayPermission || !hasAccessibilityPermission) {
            Log.w(TAG, "权限不足，无法执行服务操作: overlay=$hasOverlayPermission, accessibility=$hasAccessibilityPermission")
            setResult(RESULT_PERMISSION_DENIED, "Insufficient permissions", null)
            return
        }

        // 3. 检查服务状态并执行操作
        val service = AWAccessibilityService.getInstance()
        val isServiceRunning = service?.isDetectionEnabled() == true
        
        when (intent.action) {
            ACTION_START_SERVICE -> {
                if (isServiceRunning) {
                    Log.i(TAG, "服务已在运行，忽略启动命令")
                    setResult(RESULT_INVALID_STATE, "Service is already running", null)
                    return
                }
                try {
                    Handler(Looper.getMainLooper()).post {
                        MainActivity.getConnectionChannel()?.invokeMethod(
                            "handleServiceCommand",
                            mapOf("command" to "START_SERVICE")
                        )
                    }
                    setResult(RESULT_SUCCESS, "Service start command sent", null)
                    Log.i(TAG, "启动服务命令已发送")
                } catch (e: Exception) {
                    Log.e(TAG, "启动服务失败", e)
                    setResult(RESULT_ERROR, "Failed to start service: ${e.message}", null)
                }
            }
            ACTION_STOP_SERVICE -> {
                if (!isServiceRunning) {
                    Log.i(TAG, "服务未运行，忽略停止命令")
                    setResult(RESULT_INVALID_STATE, "Service is not running", null)
                    return
                }
                try {
                    Handler(Looper.getMainLooper()).post {
                        MainActivity.getConnectionChannel()?.invokeMethod(
                            "handleServiceCommand",
                            mapOf("command" to "STOP_SERVICE")
                        )
                    }
                    setResult(RESULT_SUCCESS, "Service stop command sent", null)
                    Log.i(TAG, "停止服务命令已发送")
                } catch (e: Exception) {
                    Log.e(TAG, "停止服务失败", e)
                    setResult(RESULT_ERROR, "Failed to stop service: ${e.message}", null)
                }
            }
            else -> {
                Log.w(TAG, "未知的广播命令: ${intent.action}")
                setResult(RESULT_ERROR, "Unknown command", null)
            }
        }
    }
} 