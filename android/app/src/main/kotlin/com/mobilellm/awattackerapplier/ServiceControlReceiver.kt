package com.mobilellm.awattackerapplier

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.os.Handler
import android.os.Looper
import org.json.JSONObject
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class ServiceControlReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "ServiceControlReceiver"
        const val ACTION_START_SERVICE = "com.mobilellm.awattackerapplier.START_SERVICE"
        const val ACTION_STOP_SERVICE = "com.mobilellm.awattackerapplier.STOP_SERVICE"
        const val ACTION_SET_GRPC_CONFIG = "com.mobilellm.awattackerapplier.SET_GRPC_CONFIG"
        const val ACTION_CLEAR_RULES = "com.mobilellm.awattackerapplier.CLEAR_RULES"
        
        // 结果码
        const val RESULT_SUCCESS = 1           // 成功通知 Flutter
        const val RESULT_PERMISSION_DENIED = 2 // 权限不足
        const val RESULT_INVALID_STATE = 3     // 服务状态不适合执行操作
        const val RESULT_ERROR = 4             // 其他错误
        const val RESULT_INVALID_PARAMS = 5    // 参数无效
        
        private const val TIMEOUT_MS = 10000L  // 10秒超时
    }

    init {
        Log.i(TAG, "ServiceControlReceiver 已初始化")
    }

    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        
        // 创建一个新的协程作用域
        val scope = CoroutineScope(Dispatchers.Main + Job())
        
        scope.launch {
            try {
                Log.i(TAG, "收到广播: ${intent.action}")
                
                // 1. 获取 MainActivity 实例
                val mainActivity = context as? MainActivity
                if (mainActivity == null) {
                    Log.w(TAG, "无法获取 MainActivity 实例")
                    pendingResult.setResult(RESULT_ERROR, "No MainActivity instance", null)
                    return@launch
                }

                // 2. 检查权限
                val hasOverlayPermission = mainActivity.checkOverlayPermission()
                val hasAccessibilityPermission = mainActivity.checkAccessibilityPermission()
                
                if (!hasOverlayPermission || !hasAccessibilityPermission) {
                    Log.w(TAG, "权限不足，无法执行服务操作: overlay=$hasOverlayPermission, accessibility=$hasAccessibilityPermission")
                    pendingResult.setResult(RESULT_PERMISSION_DENIED, "Insufficient permissions", null)
                    return@launch
                }

                // 3. 检查服务状态并执行操作
                val service = AWAccessibilityService.getInstance()
                val isServiceRunning = service?.isDetectionEnabled() == true
                
                when (intent.action) {
                    ACTION_START_SERVICE -> {
                        if (isServiceRunning) {
                            Log.i(TAG, "服务已在运行，忽略启动命令")
                            pendingResult.setResult(RESULT_INVALID_STATE, "Service is already running", null)
                            return@launch
                        }
                        
                        try {
                            withTimeout(TIMEOUT_MS) {
                                val result = invokeMethodWithResult(
                                    "handleServiceCommand",
                                    mapOf("command" to "START_SERVICE")
                                )
                                
                                val success = result["success"] as? Boolean ?: false
                                val error = result["error"] as? String
                                
                                if (success) {
                                    pendingResult.setResult(RESULT_SUCCESS, "Service started successfully", null)
                                } else {
                                    pendingResult.setResult(RESULT_ERROR, error ?: "Unknown error", null)
                                }
                            }
                        } catch (e: TimeoutCancellationException) {
                            Log.e(TAG, "启动服务超时")
                            pendingResult.setResult(RESULT_ERROR, "Service start timeout", null)
                        } catch (e: Exception) {
                            Log.e(TAG, "启动服务失败", e)
                            pendingResult.setResult(RESULT_ERROR, "Failed to start service: ${e.message}", null)
                        }
                    }
                    ACTION_STOP_SERVICE -> {
                        if (!isServiceRunning) {
                            Log.i(TAG, "服务未运行，忽略停止命令")
                            pendingResult.setResult(RESULT_INVALID_STATE, "Service is not running", null)
                            return@launch
                        }
                        
                        try {
                            withTimeout(TIMEOUT_MS) {
                                val result = invokeMethodWithResult(
                                    "handleServiceCommand",
                                    mapOf("command" to "STOP_SERVICE")
                                )
                                
                                val success = result["success"] as? Boolean ?: false
                                val error = result["error"] as? String
                                
                                if (success) {
                                    pendingResult.setResult(RESULT_SUCCESS, "Service stopped successfully", null)
                                } else {
                                    pendingResult.setResult(RESULT_ERROR, error ?: "Unknown error", null)
                                }
                            }
                        } catch (e: TimeoutCancellationException) {
                            Log.e(TAG, "停止服务超时")
                            pendingResult.setResult(RESULT_ERROR, "Service stop timeout", null)
                        } catch (e: Exception) {
                            Log.e(TAG, "停止服务失败", e)
                            pendingResult.setResult(RESULT_ERROR, "Failed to stop service: ${e.message}", null)
                        }
                    }
                    ACTION_SET_GRPC_CONFIG -> {
                        val host = intent.getStringExtra("host")
                        val port = intent.getIntExtra("port", -1)
                        
                        if (host == null || port == -1) {
                            Log.w(TAG, "无效的gRPC配置参数: host=$host, port=$port")
                            pendingResult.setResult(RESULT_INVALID_PARAMS, "Invalid gRPC configuration parameters", null)
                            return@launch
                        }
                        
                        try {
                            withTimeout(TIMEOUT_MS) {
                                val result = invokeMethodWithResult(
                                    "handleServiceCommand",
                                    mapOf(
                                        "command" to "SET_GRPC_CONFIG",
                                        "host" to host,
                                        "port" to port
                                    )
                                )
                                
                                val success = result["success"] as? Boolean ?: false
                                val error = result["error"] as? String
                                
                                if (success) {
                                    pendingResult.setResult(RESULT_SUCCESS, "gRPC configuration updated successfully", null)
                                } else {
                                    pendingResult.setResult(RESULT_ERROR, error ?: "Failed to update gRPC configuration", null)
                                }
                            }
                        } catch (e: TimeoutCancellationException) {
                            Log.e(TAG, "更新gRPC配置超时")
                            pendingResult.setResult(RESULT_ERROR, "Update gRPC configuration timeout", null)
                        } catch (e: Exception) {
                            Log.e(TAG, "更新gRPC配置失败", e)
                            pendingResult.setResult(RESULT_ERROR, "Failed to update gRPC configuration: ${e.message}", null)
                        }
                    }
                    ACTION_CLEAR_RULES -> {
                        Log.i(TAG, "收到清空规则命令")
                        
                        // 检查服务状态
                        val service = AWAccessibilityService.getInstance()
                        val isServiceRunning = service?.isDetectionEnabled() == true
                        
                        if (isServiceRunning) {
                            Log.w(TAG, "服务正在运行，无法清空规则")
                            pendingResult.setResult(RESULT_INVALID_STATE, "Cannot clear rules while service is running", null)
                            return@launch
                        }
                        
                        try {
                            withTimeout(TIMEOUT_MS) {
                                val result = invokeMethodWithResult(
                                    "handleServiceCommand",
                                    mapOf("command" to "CLEAR_RULES")
                                )
                                
                                val success = result["success"] as? Boolean ?: false
                                val error = result["error"] as? String
                                
                                if (success) {
                                    pendingResult.setResult(RESULT_SUCCESS, "Rules cleared successfully", null)
                                } else {
                                    pendingResult.setResult(RESULT_ERROR, error ?: "Failed to clear rules", null)
                                }
                            }
                        } catch (e: TimeoutCancellationException) {
                            Log.e(TAG, "清空规则超时")
                            pendingResult.setResult(RESULT_ERROR, "Clear rules timeout", null)
                        } catch (e: Exception) {
                            Log.e(TAG, "清空规则失败", e)
                            pendingResult.setResult(RESULT_ERROR, "Failed to clear rules: ${e.message}", null)
                        }
                    }
                    else -> {
                        Log.w(TAG, "未知的广播命令: ${intent.action}")
                        pendingResult.setResult(RESULT_ERROR, "Unknown command", null)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "处理广播时发生错误", e)
                pendingResult.setResult(RESULT_ERROR, "Error: ${e.message}", null)
            } finally {
                pendingResult.finish()
                scope.cancel()
            }
        }
    }

    private suspend fun invokeMethodWithResult(method: String, arguments: Any?): Map<String, Any?> = suspendCoroutine { continuation ->
        Handler(Looper.getMainLooper()).post {
            MainActivity.getConnectionChannel()?.invokeMethod(
                method,
                arguments,
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        when (result) {
                            is Map<*, *> -> {
                                @Suppress("UNCHECKED_CAST")
                                continuation.resume(result as Map<String, Any?>)
                            }
                            else -> {
                                continuation.resume(mapOf(
                                    "success" to false,
                                    "error" to "Invalid response format"
                                ))
                            }
                        }
                    }

                    override fun error(code: String, message: String?, details: Any?) {
                        continuation.resume(mapOf(
                            "success" to false,
                            "error" to (message ?: "Unknown error")
                        ))
                    }

                    override fun notImplemented() {
                        continuation.resume(mapOf(
                            "success" to false,
                            "error" to "Method not implemented"
                        ))
                    }
                }
            )
        }
    }
} 