package com.mobilellm.awattackerapplier

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import android.graphics.Rect
import kotlinx.coroutines.*
import kotlin.coroutines.CoroutineContext
import android.content.IntentFilter
import com.mobilellm.awattackerapplier.models.OverlayStyle

class MainActivity : FlutterActivity(), CoroutineScope {
    private val job = SupervisorJob()
    override val coroutineContext: CoroutineContext
        get() = Dispatchers.Main + job

    companion object {
        private const val TAG = "MainActivity"
        private const val OVERLAY_PERMISSION_REQUEST_CODE = 1
        private const val CREATE_FILE_REQUEST_CODE = 2
        private const val OPEN_FILE_REQUEST_CODE = 3
        private const val CHANNEL = "com.mobilellm.awattackerapplier/overlay_service"
        private const val CONNECTION_CHANNEL = "com.mobilellm.awattackerapplier/connection"
        
        private var methodChannel: MethodChannel? = null
        private var connectionChannel: MethodChannel? = null

        fun getMethodChannel(): MethodChannel? = methodChannel
        fun getConnectionChannel(): MethodChannel? = connectionChannel
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingFileContent: String? = null
    private lateinit var channel: MethodChannel
    private lateinit var connChannel: MethodChannel

    private val serviceReceiver = ServiceControlReceiver()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 设置主channel
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel
        
        // 设置连接channel
        connChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONNECTION_CHANNEL)
        connectionChannel = connChannel

        // 主channel的方法处理
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    result.success(checkOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    pendingResult = result
                    requestOverlayPermission()
                }
                "checkAccessibilityPermission" -> {
                    result.success(checkAccessibilityPermission())
                }
                "requestAccessibilityPermission" -> {
                    pendingResult = result
                    requestAccessibilityPermission()
                }
                "checkAllPermissions" -> {
                    val permissions = JSONObject().apply {
                        put("overlay", checkOverlayPermission())
                        put("accessibility", checkAccessibilityPermission())
                    }
                    result.success(permissions.toString())
                }
                "startDetection" -> {
                    val service = AWAccessibilityService.getInstance()
                    if (service != null) {
                        service.startDetection()
                        result.success(true)
                    } else {
                        result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                    }
                }
                "stopDetection" -> {
                    val service = AWAccessibilityService.getInstance()
                    if (service != null) {
                        service.stopDetection()
                        result.success(true)
                    } else {
                        result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                    }
                }
                "onWindowEvent" -> {
                    // 窗口事件不需要返回结果
                    result.success(null)
                }
                "createOverlay" -> {
                    createOverlay(call, result)
                }
                "updateOverlay" -> {
                    try {
                        val id = call.argument<String>("id")
                        val style = call.argument<Map<String, Any>>("style")
                        if (id != null && style != null) {
                            val windowHelper = WindowManagerHelper.getInstance(this)
                            windowHelper.updateOverlay(id, style)
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
                            val windowHelper = WindowManagerHelper.getInstance(this)
                            val removed = windowHelper.removeOverlay(id)
                            if (removed) {
                                result.success(true)
                            } else {
                                result.error("REMOVE_FAILED", "Failed to remove overlay", null)
                            }
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
                        val windowHelper = WindowManagerHelper.getInstance(this)
                        val removed = windowHelper.removeAllOverlays()
                        if (removed) {
                            result.success(true)
                        } else {
                            result.error("REMOVE_ALL_FAILED", "Failed to remove all overlays", null)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "移除所有悬浮窗时发生错误", e)
                        result.error("REMOVE_ALL_FAILED", e.message, null)
                    }
                }
                "findElements" -> {
                    handleFindElements(call, result)
                }
                "findElement" -> {
                    handleFindElement(call, result)
                }
                "saveFile" -> {
                    handleSaveFile(call, result)
                }
                "openFile" -> {
                    handleOpenFile(result)
                }
                "updateRuleMatchStatus" -> {
                    val hasMatch = call.argument<Boolean>("hasMatch") ?: false
                    AWAccessibilityService.getInstance()?.updateRuleMatchStatus(hasMatch)
                    result.success(null)
                }
                "getLatestState" -> {
                    launch {
                        try {
                            val service = AWAccessibilityService.getInstance()
                            if (service != null) {
                                val state = service.getLatestState()
                                if (state != null) {
                                    result.success(state)
                                } else {
                                    result.error("NO_STATE", "No accessibility state available", null)
                                }
                            } else {
                                result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                            }
                        } catch (e: Exception) {
                            result.error("GET_STATE_ERROR", e.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 服务控制channel的方法处理
        connChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "handleBroadcastCommand" -> {
                    val command = call.argument<String>("command")
                    when (command) {
                        "START_SERVICE" -> {
                            try {
                                val intent = Intent(this, OverlayService::class.java)
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                    startForegroundService(intent)
                                } else {
                                    startService(intent)
                                }
                                result.success(true)
                            } catch (e: Exception) {
                                Log.e(TAG, "启动服务失败", e)
                                result.error("START_SERVICE_FAILED", e.message, null)
                            }
                        }
                        "STOP_SERVICE" -> {
                            try {
                                val intent = Intent(this, OverlayService::class.java)
                                stopService(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                Log.e(TAG, "停止服务失败", e)
                                result.error("STOP_SERVICE_FAILED", e.message, null)
                            }
                        }
                        "SET_GRPC_CONFIG" -> {
                            try {
                                val host = call.argument<String>("host")
                                val port = call.argument<Int>("port")
                                if (host == null || port == null) {
                                    result.error("INVALID_ARGUMENTS", "Invalid gRPC configuration parameters", null)
                                    return@setMethodCallHandler
                                }
                                // 返回与其他命令一致的格式
                                result.success(mapOf(
                                    "success" to true,
                                    "error" to null
                                ))
                            } catch (e: Exception) {
                                Log.e(TAG, "设置gRPC配置失败", e)
                                result.error("SET_GRPC_CONFIG_FAILED", e.message, null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                }
                "startService" -> {
                    try {
                        val intent = Intent(this, OverlayService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "启动服务失败", e)
                        result.error("START_SERVICE_FAILED", e.message, null)
                    }
                }
                "stopService" -> {
                    try {
                        val intent = Intent(this, OverlayService::class.java)
                        stopService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "停止服务失败", e)
                        result.error("STOP_SERVICE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 注册广播接收器
        val filter = IntentFilter().apply {
            addAction(ServiceControlReceiver.ACTION_START_SERVICE)
            addAction(ServiceControlReceiver.ACTION_STOP_SERVICE)
            addAction(ServiceControlReceiver.ACTION_SET_GRPC_CONFIG)
        }
        registerReceiver(serviceReceiver, filter)
    }

    override fun onResume() {
        super.onResume()
        // 每次回到前台时检查权限状态并广播
        val permissions = JSONObject().apply {
            put("overlay", checkOverlayPermission())
            put("accessibility", checkAccessibilityPermission())
        }
        if (::channel.isInitialized) {
            Log.d(TAG, "Broadcasting permission status: ${permissions}")
            channel.invokeMethod("onPermissionChanged", permissions.toString())
        }
    }

    fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    fun checkAccessibilityPermission(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_GENERIC)
        val isEnabled = enabledServices.any { it.id.contains(packageName) }
        Log.d(TAG, "Accessibility permission check: $isEnabled")
        return isEnabled
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

    private fun requestAccessibilityPermission() {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            startActivity(intent)
            pendingResult?.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Request accessibility permission failed", e)
            pendingResult?.error("PERMISSION_REQUEST_FAILED", e.message, null)
        } finally {
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        when (requestCode) {
            CREATE_FILE_REQUEST_CODE -> {
                if (resultCode == RESULT_OK && data != null) {
                    val uri = data.data
                    if (uri != null) {
                        try {
                            contentResolver.openOutputStream(uri)?.use { outputStream ->
                                outputStream.write(pendingFileContent?.toByteArray() ?: ByteArray(0))
                                pendingResult?.success(true)
                            }
                        } catch (e: Exception) {
                            pendingResult?.error("SAVE_FILE_ERROR", e.message, null)
                        }
                    } else {
                        pendingResult?.error("SAVE_FILE_ERROR", "Failed to get file URI", null)
                    }
                } else {
                    pendingResult?.success(false)
                }
                pendingResult = null
                pendingFileContent = null
            }
            OPEN_FILE_REQUEST_CODE -> {
                if (resultCode == RESULT_OK && data != null) {
                    val uri = data.data
                    if (uri != null) {
                        try {
                            contentResolver.openInputStream(uri)?.use { inputStream ->
                                val content = inputStream.bufferedReader().use { it.readText() }
                                pendingResult?.success(content)
                            }
                        } catch (e: Exception) {
                            pendingResult?.error("OPEN_FILE_ERROR", e.message, null)
                        }
                    } else {
                        pendingResult?.error("OPEN_FILE_ERROR", "Failed to get file URI", null)
                    }
                } else {
                    pendingResult?.success(null)
                }
                pendingResult = null
            }
            OVERLAY_PERMISSION_REQUEST_CODE -> {
                pendingResult?.success(Settings.canDrawOverlays(this))
                pendingResult = null
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        job.cancel()
        // 注销广播接收器
        unregisterReceiver(serviceReceiver)
        methodChannel = null
        connectionChannel = null
    }

    private fun handleFindElements(call: MethodCall, result: MethodChannel.Result) {
        launch {
            try {
                val rawStyles = call.argument<List<Map<String, Any>>>("styles")
                if (rawStyles == null) {
                    result.error("INVALID_ARGUMENT", "Styles cannot be null", null)
                    return@launch
                }

                val styles = rawStyles.map { OverlayStyle.fromMap(it) }

                val service = AWAccessibilityService.getInstance()
                if (service == null) {
                    result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                    return@launch
                }

                val elements = service.findElements(styles)
                result.success(elements.map { it.toMapResult() })
            } catch (e: Exception) {
                result.error("FIND_ERROR", e.message, null)
            }
        }
    }

    private fun handleFindElement(call: MethodCall, result: MethodChannel.Result) {
        launch {
            try {
                val rawStyle = call.argument<Map<String, Any>>("style")
                if (rawStyle == null) {
                    result.error("INVALID_ARGUMENT", "Style cannot be null", null)
                    return@launch
                }

                val style = OverlayStyle.fromMap(rawStyle)

                val service = AWAccessibilityService.getInstance()
                if (service == null) {
                    result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                    return@launch
                }

                val element = service.findElementByUiSelector(style)?.let {
                    val bounds = Rect()
                    it.getBoundsInScreen(bounds)
                    AWAccessibilityService.ElementResult(
                        success = true,
                        coordinates = mapOf(
                            "x" to bounds.left,
                            "y" to bounds.top
                        ),
                        size = mapOf(
                            "width" to bounds.width(),
                            "height" to bounds.height()
                        ),
                        visible = it.isVisibleToUser
                    )
                } ?: AWAccessibilityService.ElementResult(
                    success = false,
                    message = "Element not found"
                )

                result.success(element.toMapResult())
            } catch (e: Exception) {
                result.error("FIND_ERROR", e.message, null)
            }
        }
    }

    private fun createOverlay(call: MethodCall, result: MethodChannel.Result) {
        launch {
            try {
                val id = call.argument<String>("id") ?: throw IllegalArgumentException("Missing id")
                val style = call.argument<Map<String, Any>>("style")
                    ?: throw IllegalArgumentException("Missing style")
                
                // 使用 AccessibilityService 的实例创建悬浮窗
                val accessibilityService = AWAccessibilityService.getInstance()
                if (accessibilityService == null) {
                    result.error("SERVICE_NOT_RUNNING", "AccessibilityService is not running", null)
                    return@launch
                }
                
                val windowHelper = WindowManagerHelper.getInstance(this@MainActivity)
                windowHelper.createOverlay(id, style)
                result.success(mapOf("success" to true))
            } catch (e: Exception) {
                Log.e(TAG, "创建悬浮窗时发生错误", e)
                result.error("CREATE_FAILED", e.message, null)
            }
        }
    }

    private fun handleSaveFile(call: MethodCall, result: MethodChannel.Result) {
        launch {
            try {
                val content = call.argument<String>("content")
                    ?: throw IllegalArgumentException("Missing content")
                val fileName = call.argument<String>("fileName") ?: "rules.json"
                
                pendingResult = result
                pendingFileContent = content
                
                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "application/json"
                    putExtra(Intent.EXTRA_TITLE, fileName)
                }
                
                startActivityForResult(intent, CREATE_FILE_REQUEST_CODE)
            } catch (e: Exception) {
                result.error("SAVE_FILE_ERROR", e.message, null)
            }
        }
    }

    private fun handleOpenFile(result: MethodChannel.Result) {
        launch {
            try {
                pendingResult = result
                
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "application/json"
                }
                
                startActivityForResult(intent, OPEN_FILE_REQUEST_CODE)
            } catch (e: Exception) {
                result.error("OPEN_FILE_ERROR", e.message, null)
            }
        }
    }
}
