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
    private val MIN_WINDOW_CHANGE_INTERVAL = 100L // 最小窗口变化间隔(ms)

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "AccessibilityService created")
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

    private fun handleWindowStateChange(event: AccessibilityEvent) {
        val currentPackage = event.packageName?.toString()
        val currentActivity = event.className?.toString()
        val currentTime = System.currentTimeMillis()

        // 检查是否需要更新（防止短时间内重复触发）
        if (currentTime - lastWindowChangeTime < MIN_WINDOW_CHANGE_INTERVAL) {
            return
        }

        // 检查状态是否真的发生变化
        if (currentPackage != lastPackage || currentActivity != lastActivity) {
            lastWindowChangeTime = currentTime
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

    private fun handleContentChange(event: AccessibilityEvent) {
        // 仅处理当前应用的内容变化
        if (event.packageName?.toString() != lastPackage) return
        
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastWindowChangeTime < MIN_WINDOW_CHANGE_INTERVAL) {
            return
        }

        lastWindowChangeTime = currentTime
        
        // 发送内容变化事件
        sendWindowEvent(
            type = "WINDOW_CONTENT_CHANGED",
            packageName = lastPackage,
            activityName = lastActivity,
            contentChanged = true
        )
    }

    private fun handleViewScroll(event: AccessibilityEvent) {
        // 处理滚动事件，可能影响元素位置
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastWindowChangeTime < MIN_WINDOW_CHANGE_INTERVAL) {
            return
        }

        lastWindowChangeTime = currentTime
        
        sendWindowEvent(
            type = "VIEW_SCROLLED",
            packageName = lastPackage,
            activityName = lastActivity,
            contentChanged = true
        )
    }

    // 元素查找功能
    fun findElementByUiSelector(selectorCode: String): AccessibilityNodeInfo? {
        try {
            val rootNode = rootInActiveWindow ?: return null
            return UiAutomatorHelper.findNodeBySelector(rootNode, selectorCode)
        } catch (e: Exception) {
            Log.e(TAG, "Find element failed: $e")
            return null
        }
    }

    // 批量查找元素
    fun findElements(selectorCodes: List<String>): List<ElementResult> {
        return selectorCodes.map { code ->
            try {
                val node = findElementByUiSelector(code)
                if (node != null) {
                    val bounds = Rect()
                    node.getBoundsInScreen(bounds)
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
                    ElementResult(success = false, message = "Element not found")
                }
            } catch (e: Exception) {
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

        MainActivity.getMethodChannel()?.invokeMethod("onWindowEvent", event.toString())
    }

    override fun onInterrupt() {
        Log.d(TAG, "AccessibilityService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "AccessibilityService destroyed")
    }

    override fun onUnbind(intent: Intent?): Boolean {
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
}

// UiAutomator选择器辅助类
object UiAutomatorHelper {
    fun findNodeBySelector(rootNode: AccessibilityNodeInfo, selectorCode: String): AccessibilityNodeInfo? {
        // 解析UiSelector代码并查找元素
        // 这里需要实现UiSelector代码的解析和执行
        // 例如: "new UiSelector().text("测试")"
        
        return when {
            selectorCode.contains(".text(") -> {
                val text = extractSelectorValue(selectorCode, "text")
                findNodeByText(rootNode, text)
            }
            selectorCode.contains(".description(") -> {
                val desc = extractSelectorValue(selectorCode, "description")
                findNodeByDescription(rootNode, desc)
            }
            selectorCode.contains(".resourceId(") -> {
                val id = extractSelectorValue(selectorCode, "resourceId")
                findNodeById(rootNode, id)
            }
            else -> null
        }
    }

    private fun extractSelectorValue(code: String, type: String): String {
        val regex = """.$type\("([^"]+)"\)""".toRegex()
        return regex.find(code)?.groupValues?.get(1) ?: ""
    }

    private fun findNodeByText(rootNode: AccessibilityNodeInfo, text: String): AccessibilityNodeInfo? {
        val nodes = rootNode.findAccessibilityNodeInfosByText(text)
        return nodes.firstOrNull()
    }

    private fun findNodeByDescription(rootNode: AccessibilityNodeInfo, description: String): AccessibilityNodeInfo? {
        if (rootNode.contentDescription?.toString() == description) {
            return rootNode
        }
        for (i in 0 until rootNode.childCount) {
            val child = rootNode.getChild(i)
            val result = child?.let { findNodeByDescription(it, description) }
            if (result != null) {
                return result
            }
        }
        return null
    }

    private fun findNodeById(rootNode: AccessibilityNodeInfo, id: String): AccessibilityNodeInfo? {
        val nodes = rootNode.findAccessibilityNodeInfosByViewId(id)
        return nodes.firstOrNull()
    }
} 