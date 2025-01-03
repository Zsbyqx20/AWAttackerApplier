package com.mobilellm.awattackapplier

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.graphics.Rect
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import org.json.JSONObject

class AWAccessibilityService : AccessibilityService() {
    companion object {
        private const val TAG = "AWAccessibilityService"
        private var instance: AWAccessibilityService? = null
        
        fun getInstance(): AWAccessibilityService? = instance
    }

    private var lastPackage: String? = null
    private var lastActivity: String? = null
    private var lastWindowChangeTime: Long = 0
    private var lastEventHash: Int = 0
    private val MIN_WINDOW_CHANGE_INTERVAL = 100L // 最小窗口变化间隔(ms)

    private val IGNORED_PACKAGES = listOf(
        "com.android.systemui",
        "com.android.settings",
        "com.google.android.apps.nexuslauncher",
        "com.android.launcher",
        "com.android.launcher2",
        "com.android.launcher3",
        "com.google.android.googlequicksearchbox",
        "com.mobilellm.awattackapplier"
    )

    private fun getRelativeActivityName(fullName: String?, packageName: String?): String? {
        if (fullName == null || packageName == null) return fullName
        
        // 如果活动名以包名开头，移除包名部分但保留点号
        return if (fullName.startsWith(packageName)) {
            fullName.substring(packageName.length)  // 保留开头的点号
        } else {
            // 如果不是以包名开头，在最后一个点号前加上点号
            "." + fullName.substringAfterLast('.')
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "AccessibilityService created")
        
        // 初始化 WindowManagerHelper
        WindowManagerHelper.initialize(this)
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        // 只有在服务真正连接时才配置
        if (instance != null) {
            configureService()
        }
    }

    private fun configureService() {
        val config = AccessibilityServiceInfo().apply {
            // 设置需要监听的事件类型
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or 
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                        AccessibilityEvent.TYPE_VIEW_SCROLLED

            // 设置反馈类型
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC

            // 设置功能标志
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS

            // 设置通知超时
            notificationTimeout = 100
        }
        
        serviceInfo = config
        Log.d(TAG, "AccessibilityService configured")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                handleWindowStateChange(event)
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                handleContentChange(event)
            }
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> {
                handleViewScroll(event)
            }
        }
    }

    private fun calculateEventHash(
        type: String,
        packageName: String?,
        activityName: String?,
        contentChanged: Boolean
    ): Int {
        return "$type:$packageName:$activityName:$contentChanged".hashCode()
    }

    private fun shouldProcessEvent(
        type: String,
        packageName: String?,
        activityName: String?,
        contentChanged: Boolean
    ): Boolean {
        val currentTime = System.currentTimeMillis()
        val eventHash = calculateEventHash(type, packageName, activityName, contentChanged)
        
        // 检查时间间隔和事件哈希值
        if (currentTime - lastWindowChangeTime < MIN_WINDOW_CHANGE_INTERVAL && 
            eventHash == lastEventHash) {
            Log.d(TAG, "忽略重复事件: $type")
            return false
        }

        lastWindowChangeTime = currentTime
        lastEventHash = eventHash
        return true
    }

    private fun handleWindowStateChange(event: AccessibilityEvent) {
        val currentPackage = event.packageName?.toString()
        val currentActivity = event.className?.toString()

        // 忽略系统UI、设置和启动器等系统应用的变化
        if (currentPackage == null || 
            IGNORED_PACKAGES.any { currentPackage.startsWith(it) } ||
            currentPackage == "android") {
            Log.d(TAG, "忽略系统应用事件: $currentPackage")
            return
        }

        // 检查状态是否真的发生变化
        if (currentPackage != lastPackage || currentActivity != lastActivity) {
            if (shouldProcessEvent("WINDOW_STATE_CHANGED", currentPackage, currentActivity, false)) {
                lastPackage = currentPackage
                lastActivity = currentActivity

                // 发送窗口状态变化事件
                sendWindowEvent(
                    type = "WINDOW_STATE_CHANGED",
                    packageName = currentPackage,
                    activityName = currentActivity,
                    contentChanged = false
                )
            }
        }
    }

    private fun handleContentChange(event: AccessibilityEvent) {
        // 仅处理当前应用的内容变化
        if (event.packageName?.toString() != lastPackage) return

        if (shouldProcessEvent("WINDOW_CONTENT_CHANGED", lastPackage, lastActivity, true)) {
            // 发送内容变化事件
            sendWindowEvent(
                type = "WINDOW_CONTENT_CHANGED",
                packageName = lastPackage,
                activityName = getRelativeActivityName(lastActivity, lastPackage),
                contentChanged = true
            )
        }
    }

    private fun handleViewScroll(event: AccessibilityEvent) {
        if (shouldProcessEvent("VIEW_SCROLLED", lastPackage, lastActivity, true)) {
            sendWindowEvent(
                type = "VIEW_SCROLLED",
                packageName = lastPackage,
                activityName = getRelativeActivityName(lastActivity, lastPackage),
                contentChanged = true
            )
        }
    }

    // 元素查找功能
    fun findElementByUiSelector(selectorCode: String): AccessibilityNodeInfo? {
        var retryCount = 0
        val maxRetries = 3
        val retryDelay = 100L // 100ms

        while (retryCount < maxRetries) {
            try {
                val rootNode = rootInActiveWindow
                if (rootNode == null) {
                    Log.d(TAG, "rootInActiveWindow is null, retry: ${retryCount + 1}/$maxRetries")
                    Thread.sleep(retryDelay)
                    retryCount++
                    continue
                }

                val node = UiAutomatorHelper.findNodeBySelector(rootNode, selectorCode)
                if (node == null) {
                    Log.d(TAG, "Node not found with selector: $selectorCode, retry: ${retryCount + 1}/$maxRetries")
                    Thread.sleep(retryDelay)
                    retryCount++
                    continue
                }

                return node
            } catch (e: Exception) {
                Log.e(TAG, "Find element failed: $e")
                retryCount++
                if (retryCount < maxRetries) {
                    Thread.sleep(retryDelay)
                }
            }
        }

        Log.e(TAG, "Failed to find element after $maxRetries retries")
        return null
    }

    // 批量查找元素
    fun findElements(selectorCodes: List<String>): List<ElementResult> {
        Log.d(TAG, "开始批量查找元素，共 ${selectorCodes.size} 个选择器")
        return selectorCodes.mapIndexed { index, code ->
            Log.d(TAG, "查找第 ${index + 1} 个元素: $code")
            try {
                val node = findElementByUiSelector(code)
                if (node != null) {
                    val bounds = Rect()
                    node.getBoundsInScreen(bounds)
                    Log.d(TAG, "找到元素 ${index + 1}，位置: (${bounds.left}, ${bounds.top}), 大小: ${bounds.width()}x${bounds.height()}")
                    ElementResult(
                        success = true,
                        coordinates = mapOf(
                            "x" to bounds.left,
                            "y" to bounds.top
                        ),
                        size = mapOf(
                            "width" to bounds.width(),
                            "height" to bounds.height()
                        ),
                        visible = node.isVisibleToUser
                    )
                } else {
                    Log.d(TAG, "未找到元素 ${index + 1}")
                    ElementResult(success = false, message = "Element not found")
                }
            } catch (e: Exception) {
                Log.e(TAG, "查找元素 ${index + 1} 时发生错误: ${e.message}")
                ElementResult(success = false, message = e.message ?: "Unknown error")
            }
        }
    }

    private fun sendWindowEvent(
        type: String,
        packageName: String?,
        activityName: String?,
        contentChanged: Boolean
    ) {
        val event = JSONObject().apply {
            put("type", type)
            put("package_name", packageName)
            put("activity_name", activityName)
            put("timestamp", System.currentTimeMillis())
            put("content_changed", contentChanged)
        }

        MainActivity.getMethodChannel()?.let {
            it.invokeMethod("onWindowEvent", event.toString())
        } ?: Log.e(TAG, "MethodChannel不可用，无法发送事件")
    }

    override fun onInterrupt() {
        Log.d(TAG, "AccessibilityService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        WindowManagerHelper.destroyInstance()
        instance = null
        Log.d(TAG, "AccessibilityService destroyed")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        WindowManagerHelper.destroyInstance()
        instance = null
        Log.d(TAG, "AccessibilityService unbound")
        return super.onUnbind(intent)
    }

    data class ElementResult(
        val success: Boolean,
        val coordinates: Map<String, Int>? = null,
        val size: Map<String, Int>? = null,
        val visible: Boolean = false,
        val message: String? = null
    ) {
        fun toMapResult(): Map<String, Any?> {
            return mapOf(
                "success" to success,
                "coordinates" to coordinates,
                "size" to size,
                "visible" to visible,
                "message" to message
            )
        }
    }

    fun getWindowManagerHelper(): WindowManagerHelper = WindowManagerHelper.getInstance(this)
}

// UiAutomator选择器辅助类
object UiAutomatorHelper {
    private const val TAG = "UiAutomatorHelper"

    fun findNodeBySelector(rootNode: AccessibilityNodeInfo, selectorCode: String): AccessibilityNodeInfo? {
        Log.d(TAG, "解析选择器: $selectorCode")
        
        return when {
            selectorCode.contains(".text(") -> {
                val text = extractSelectorValue(selectorCode, "text")
                Log.d(TAG, "使用文本查找: '$text'")
                findNodeByText(rootNode, text)
            }
            selectorCode.contains(".description(") -> {
                val desc = extractSelectorValue(selectorCode, "description")
                Log.d(TAG, "使用描述查找: '$desc'")
                findNodeByDescription(rootNode, desc)
            }
            selectorCode.contains(".resourceId(") -> {
                val id = extractSelectorValue(selectorCode, "resourceId")
                Log.d(TAG, "使用资源ID查找: '$id'")
                findNodeById(rootNode, id)
            }
            else -> {
                Log.e(TAG, "不支持的选择器类型: $selectorCode")
                null
            }
        }
    }

    private fun extractSelectorValue(code: String, type: String): String {
        val regex = """.$type\("([^"]+)"\)""".toRegex()
        val value = regex.find(code)?.groupValues?.get(1) ?: ""
        Log.d(TAG, "提取 $type 值: '$value'")
        return value
    }

    private fun findNodeByText(rootNode: AccessibilityNodeInfo, text: String): AccessibilityNodeInfo? {
        try {
            val nodes = rootNode.findAccessibilityNodeInfosByText(text)
            Log.d(TAG, "通过文本查找到 ${nodes.size} 个节点")
            return nodes.firstOrNull()?.also {
                val bounds = Rect()
                it.getBoundsInScreen(bounds)
                Log.d(TAG, "选中第一个节点，位置: $bounds")
            }
        } catch (e: Exception) {
            Log.e(TAG, "通过文本查找节点时出错: ${e.message}")
            return null
        }
    }

    private fun findNodeByDescription(rootNode: AccessibilityNodeInfo, description: String): AccessibilityNodeInfo? {
        try {
            if (rootNode.contentDescription?.toString() == description) {
                Log.d(TAG, "在根节点找到匹配的描述")
                return rootNode
            }
            
            var result: AccessibilityNodeInfo? = null
            for (i in 0 until rootNode.childCount) {
                val child = rootNode.getChild(i)
                result = child?.let { findNodeByDescription(it, description) }
                if (result != null) {
                    Log.d(TAG, "在子节点中找到匹配的描述")
                    break
                }
            }
            return result
        } catch (e: Exception) {
            Log.e(TAG, "通过描述查找节点时出错: ${e.message}")
            return null
        }
    }

    private fun findNodeById(rootNode: AccessibilityNodeInfo, id: String): AccessibilityNodeInfo? {
        try {
            val nodes = rootNode.findAccessibilityNodeInfosByViewId(id)
            Log.d(TAG, "通过ID查找到 ${nodes.size} 个节点")
            return nodes.firstOrNull()?.also {
                val bounds = Rect()
                it.getBoundsInScreen(bounds)
                Log.d(TAG, "选中第一个节点，位置: $bounds")
            }
        } catch (e: Exception) {
            Log.e(TAG, "通过ID查找节点时出错: ${e.message}")
            return null
        }
    }
} 