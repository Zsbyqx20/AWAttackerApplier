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

    private var lastWindowHash: Int = 0
    private var lastPackage: String? = null
    private var lastActivity: String? = null

    private val IGNORED_PACKAGES = listOf(
        // "com.android.systemui",
        // "com.android.settings",
        // "com.google.android.apps.nexuslauncher",
        // "com.android.launcher",
        // "com.android.launcher2",
        // "com.android.launcher3",
        // "com.google.android.googlequicksearchbox",
        "com.mobilellm.awattackapplier"
    )

    private fun getRelativeActivityName(fullName: String?, packageName: String?): String? {
        if (fullName == null || packageName == null) return fullName
        
        // 如果活动名以包名开头，移除包名部分并确保以点号开头
        return if (fullName.startsWith(packageName)) {
            val remaining = fullName.substring(packageName.length)
            if (remaining.startsWith('.')) remaining else ".$remaining"
        } else {
            // 如果不是以包名开头，确保以点号开头
            if (fullName.startsWith('.')) fullName else ".$fullName"
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "AccessibilityService created")
        WindowManagerHelper.initialize(this)
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        if (instance != null) {
            configureService()
        }
    }

    private fun configureService() {
        val config = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                        AccessibilityEvent.TYPE_VIEW_CLICKED or
                        AccessibilityEvent.TYPE_VIEW_LONG_CLICKED or
                        AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED

            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC

            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS

            notificationTimeout = 100
        }
        
        serviceInfo = config
        Log.d(TAG, "AccessibilityService configured")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        when (event.eventType) {
            // 用户交互事件直接触发
            AccessibilityEvent.TYPE_VIEW_CLICKED,
            AccessibilityEvent.TYPE_VIEW_LONG_CLICKED,
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> {
                handleUserInteraction(event)
            }
            
            // 窗口状态变化需要检查哈希值
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val currentHash = calculateWindowHash()
                Log.d(TAG, "窗口状态变化: currentHash=$currentHash, lastHash=$lastWindowHash")
                if (currentHash != lastWindowHash) {
                    lastWindowHash = currentHash
                    handleWindowStateChanged(event)
                } else {
                    Log.d(TAG, "窗口状态变化但界面内容未变化，忽略事件")
                }
            }
        }
    }

    private fun calculateWindowHash(): Int {
        val rootNode = rootInActiveWindow ?: return 0
        val hashBuilder = StringBuilder()
        
        fun traverseNode(node: AccessibilityNodeInfo) {
            hashBuilder.append(node.className)
            hashBuilder.append(node.text)
            hashBuilder.append(node.contentDescription)
            
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { 
                    traverseNode(it)
                    it.recycle()
                }
            }
        }
        
        try {
            traverseNode(rootNode)
            val hash = hashBuilder.toString().hashCode()
            Log.d(TAG, "计算界面哈希值: $hash")
            return hash
        } finally {
            rootNode.recycle()
        }
    }

    private fun handleWindowStateChanged(event: AccessibilityEvent) {
        val currentPackage = event.packageName?.toString()
        val currentActivity = event.className?.toString()
        
        if (currentPackage != null && 
            !IGNORED_PACKAGES.any { currentPackage.startsWith(it) }) {
            Log.d(TAG, "检测到窗口变化: package=$currentPackage, activity=$currentActivity")
            lastPackage = currentPackage
            lastActivity = currentActivity
            
            sendWindowEvent(
                type = "WINDOW_STATE_CHANGED",
                packageName = currentPackage,
                activityName = getRelativeActivityName(currentActivity, currentPackage),
                contentChanged = true
            )
        } else {
            Log.d(TAG, "忽略系统应用的窗口变化: $currentPackage")
        }
    }

    private fun handleUserInteraction(event: AccessibilityEvent) {
        val eventType = getEventTypeName(event.eventType)
        Log.d(TAG, "检测到用户交互: type=$eventType, package=$lastPackage, activity=$lastActivity")
        
        if (lastPackage != null && 
            !IGNORED_PACKAGES.any { lastPackage!!.startsWith(it) }) {
            sendWindowEvent(
                type = eventType,
                packageName = lastPackage,
                activityName = getRelativeActivityName(lastActivity, lastPackage),
                contentChanged = false
            )
        } else {
            Log.d(TAG, "忽略系统应用的用户交互")
        }
    }

    // 元素查找功能
    fun findElementByUiSelector(selectorCode: String): AccessibilityNodeInfo? {
        var retryCount = 0
        val maxRetries = 5  // 增加重试次数
        val retryDelay = 200L  // 增加延迟时间
        var lastBounds: Rect? = null

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

                // 获取当前位置
                val bounds = Rect()
                node.getBoundsInScreen(bounds)
                
                // 记录位置信息用于日志
                val boundsStr = "[$bounds]"

                // 如果是第一次找到元素，记录位置并继续等待
                if (lastBounds == null) {
                    Log.d(TAG, "首次找到元素，位置: $boundsStr，等待位置稳定...")
                    lastBounds = Rect(bounds)
                    Thread.sleep(retryDelay)
                    retryCount++
                    continue
                }

                // 比较位置是否稳定
                if (bounds == lastBounds) {
                    Log.d(TAG, "元素位置稳定，最终位置: $boundsStr")
                    return node  // 位置稳定，返回节点
                } else {
                    // 位置不稳定，更新记录并继续等待
                    Log.d(TAG, "元素位置变化: ${lastBounds} -> $boundsStr，继续等待...")
                    lastBounds = Rect(bounds)
                    Thread.sleep(retryDelay)
                    retryCount++
                    continue
                }

            } catch (e: Exception) {
                Log.e(TAG, "查找元素时发生错误: $e")
                retryCount++
                if (retryCount < maxRetries) {
                    Thread.sleep(retryDelay)
                }
            }
        }

        Log.e(TAG, "在 $maxRetries 次重试后仍未找到稳定的元素位置")
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

    private fun getEventTypeName(eventType: Int): String {
        return when (eventType) {
            AccessibilityEvent.TYPE_VIEW_CLICKED -> "VIEW_CLICKED"
            AccessibilityEvent.TYPE_VIEW_LONG_CLICKED -> "VIEW_LONG_CLICKED"
            AccessibilityEvent.TYPE_VIEW_SELECTED -> "VIEW_SELECTED"
            AccessibilityEvent.TYPE_VIEW_FOCUSED -> "VIEW_FOCUSED"
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> "VIEW_TEXT_CHANGED"
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> "WINDOW_STATE_CHANGED"
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> "WINDOW_CONTENT_CHANGED"
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> "VIEW_SCROLLED"
            AccessibilityEvent.TYPE_TOUCH_INTERACTION_START -> "TOUCH_INTERACTION_START"
            AccessibilityEvent.TYPE_TOUCH_INTERACTION_END -> "TOUCH_INTERACTION_END"
            else -> "UNKNOWN_EVENT_TYPE($eventType)"
        }
    }
}

// UiAutomator选择器辅助类
object UiAutomatorHelper {
    private const val TAG = "UiAutomatorHelper"

    fun findNodeBySelector(rootNode: AccessibilityNodeInfo, selectorCode: String): AccessibilityNodeInfo? {
        
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
        return value
    }

    private fun findNodeByText(rootNode: AccessibilityNodeInfo, text: String): AccessibilityNodeInfo? {
        try {
            val nodes = rootNode.findAccessibilityNodeInfosByText(text)
            return nodes.firstOrNull()?.also {
                val bounds = Rect()
                it.getBoundsInScreen(bounds)
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
            return nodes.firstOrNull()?.also {
                val bounds = Rect()
                it.getBoundsInScreen(bounds)
            }
        } catch (e: Exception) {
            Log.e(TAG, "通过ID查找节点时出错: ${e.message}")
            return null
        }
    }
} 