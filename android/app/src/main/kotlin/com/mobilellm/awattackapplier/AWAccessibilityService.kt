package com.mobilellm.awattackapplier

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.graphics.Rect
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import org.json.JSONObject
import kotlinx.coroutines.*
import kotlin.coroutines.CoroutineContext

class AWAccessibilityService : AccessibilityService(), CoroutineScope {
    private val job = SupervisorJob()
    override val coroutineContext: CoroutineContext
        get() = Dispatchers.Main + job

    // 当前搜索的协程作用域
    private var searchScope: CoroutineScope? = null

    companion object {
        private const val TAG = "AWAccessibilityService"
        private var instance: AWAccessibilityService? = null
        
        fun getInstance(): AWAccessibilityService? = instance
    }

    private var lastWindowHash: Int = 0
    private var lastPackage: String? = null
    private var lastActivity: String? = null
    private var isDetectionEnabled = false
    
    // 添加去重相关的变量
    private var lastEventTime: Long = 0
    private val EVENT_THROTTLE_TIME = 500L  // 500ms 内的相同事件将被忽略
    
    // 添加上一次事件的信息
    private var lastEventPackage: String? = null
    private var lastEventActivity: String? = null
    private var lastEventChangeTypes: Int = 0
    private var lastEventSource: AccessibilityNodeInfo? = null

    private val IGNORED_PACKAGES = listOf(
        // "com.android.systemui",
        // "com.android.settings",
        // "com.google.android.apps.nexuslauncher",
        // "com.android.launcher",
        // "com.android.launcher2",
        // "com.android.launcher3",
        "com.google.android.googlequicksearchbox",
        "com.mobilellm.awattackapplier"
    )

    // 添加标记当前是否正在查找的变量
    private var isSearching = false
    private var shouldCancelSearch = false

    private var pendingEvents = mutableListOf<Triple<String, String?, String?>>()
    private var retryJob: Job? = null

    private fun cancelSearch() {
        searchScope?.cancel()
        searchScope = null
        Log.d(TAG, "取消当前的查找操作")
    }

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
            // 服务连接后发送一个初始事件
            sendWindowEvent(
                type = "SERVICE_CONNECTED",
                packageName = null,
                activityName = null,
                contentChanged = false
            )
        }
    }

    private fun configureService() {
        val config = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED

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
        if (!isDetectionEnabled) {
            return
        }

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                handleContentChanged(event)
            }
            
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val currentHash = calculateWindowHash()
                Log.d(TAG, "窗口状态变化: currentHash=$currentHash, lastHash=$lastWindowHash")
                if (currentHash != lastWindowHash) {
                    lastWindowHash = currentHash
                    handleWindowStateChanged(event)
                } else {
                    Log.d(TAG, "接收到状态变化信号，但哈希值未改变，忽略事件")
                }
            }
        }
    }

    private fun calculateWindowHash(): Int {
        val rootNode = rootInActiveWindow ?: return 0
        val hashBuilder = StringBuilder()
        
        fun traverseNode(node: AccessibilityNodeInfo) {
            // 检查是否是状态栏
            if (node.packageName?.toString() == "com.android.systemui" && 
                (node.className?.toString()?.contains("StatusBar") == true || 
                 node.viewIdResourceName?.contains("status_bar") == true)) {
                return
            }
            
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
        // 取消当前正在进行的查找操作
        cancelSearch()

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

    private fun handleContentChanged(event: AccessibilityEvent) {
        val currentTime = System.currentTimeMillis()
        val currentPackage = event.packageName?.toString()
        val currentActivity = event.className?.toString()
        val currentChangeTypes = event.contentChangeTypes
        val currentSource = event.source
        
        // 检查是否需要忽略此事件
        if (currentTime - lastEventTime < EVENT_THROTTLE_TIME &&
            currentPackage == lastEventPackage &&
            currentActivity == lastEventActivity &&
            currentChangeTypes == lastEventChangeTypes &&
            currentSource?.equals(lastEventSource) == true) {
            Log.d(TAG, "忽略完全相同的内容变化事件")
            return
        }
        
        // 更新事件信息
        lastEventTime = currentTime
        lastEventPackage = currentPackage
        lastEventActivity = currentActivity
        lastEventChangeTypes = currentChangeTypes
        lastEventSource?.recycle()  // 回收旧的 source
        lastEventSource = currentSource?.let { AccessibilityNodeInfo.obtain(it) }  // 保存新的 source 的副本
        
        // 记录内容变化的类型
        Log.d(TAG, "检测到内容变化: package=$currentPackage, activity=$currentActivity, changeTypes=$currentChangeTypes")
        
        // 使用当前保存的包名和活动名
        if (lastPackage != null && 
            !IGNORED_PACKAGES.any { lastPackage!!.startsWith(it) }) {
            
            sendWindowEvent(
                type = "CONTENT_CHANGED",
                packageName = lastPackage,
                activityName = getRelativeActivityName(lastActivity, lastPackage),
                contentChanged = true
            )
        }
    }

    // 元素查找功能
    suspend fun findElementByUiSelector(selectorCode: String): AccessibilityNodeInfo? = withContext(Dispatchers.Default) {
        var retryCount = 0
        val maxRetries = 5
        val retryDelay = 200L
        var lastBounds: Rect? = null

        while (retryCount < maxRetries && isActive) {
            try {
                val rootNode = rootInActiveWindow
                if (rootNode == null) {
                    Log.d(TAG, "rootInActiveWindow is null, retry: ${retryCount + 1}/$maxRetries")
                    delay(retryDelay)
                    retryCount++
                    continue
                }

                val node = UiAutomatorHelper.findNodeBySelector(rootNode, selectorCode)
                if (node == null) {
                    Log.d(TAG, "Node not found with selector: $selectorCode, retry: ${retryCount + 1}/$maxRetries")
                    delay(retryDelay)
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
                    delay(retryDelay)
                    retryCount++
                    continue
                }

                // 比较位置是否稳定
                if (bounds == lastBounds) {
                    Log.d(TAG, "元素位置稳定，最终位置: $boundsStr")
                    return@withContext node
                } else {
                    // 位置不稳定，更新记录并继续等待
                    Log.d(TAG, "元素位置变化: ${lastBounds} -> $boundsStr，继续等待...")
                    lastBounds = Rect(bounds)
                    delay(retryDelay)
                    retryCount++
                    continue
                }

            } catch (e: Exception) {
                Log.e(TAG, "查找元素时发生错误: $e")
                retryCount++
                if (retryCount < maxRetries) {
                    delay(retryDelay)
                }
            }
        }

        Log.e(TAG, "在 $maxRetries 次重试后仍未找到稳定的元素位置")
        null
    }

    // 批量查找元素
    suspend fun findElements(selectorCodes: List<String>): List<ElementResult> = withContext(Dispatchers.Default) {
        Log.d(TAG, "开始批量查找元素，共 ${selectorCodes.size} 个选择器")
        
        // 创建新的搜索作用域
        searchScope?.cancel()
        searchScope = CoroutineScope(coroutineContext + Job())
        
        try {
            searchScope?.let { scope ->
                selectorCodes.mapIndexed { index, code ->
                    scope.async {
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
                }.awaitAll()
            } ?: emptyList()
        } catch (e: CancellationException) {
            Log.d(TAG, "搜索操作被取消")
            selectorCodes.map { 
                ElementResult(success = false, message = "Search cancelled") 
            }
        } finally {
            searchScope = null
        }
    }

    private fun startEventRetry() {
        retryJob?.cancel()
        retryJob = launch {
            while (isActive && pendingEvents.isNotEmpty()) {
                val channel = MainActivity.getMethodChannel()
                if (channel != null) {
                    pendingEvents.toList().forEach { (type, packageName, activityName) ->
                        sendWindowEvent(type, packageName, activityName, false)
                    }
                    pendingEvents.clear()
                    retryJob?.cancel()
                    break
                }
                delay(500) // 每500毫秒重试一次
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
        } ?: run {
            Log.d(TAG, "MethodChannel不可用，将事件加入重试队列")
            pendingEvents.add(Triple(type, packageName, activityName))
            startEventRetry()
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "AccessibilityService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        job.cancel() // 取消所有协程
        retryJob?.cancel() // 取消重试任务
        lastEventSource?.recycle()  // 清理资源
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

    fun startDetection() {
        Log.d(TAG, "🎯 开启界面检测")
        isDetectionEnabled = true
    }

    fun stopDetection() {
        Log.d(TAG, "⏹️ 停止界面检测")
        isDetectionEnabled = false
        // 重置状态
        lastWindowHash = 0
        lastPackage = null
        lastActivity = null
    }
}

// UiAutomator选择器辅助类
object UiAutomatorHelper {
    private const val TAG = "UiAutomatorHelper"

    fun findNodeBySelector(rootNode: AccessibilityNodeInfo, selectorCode: String): AccessibilityNodeInfo? {
        val instanceIdx = extractInstanceIndex(selectorCode)
        val baseSelector = removeInstanceSelector(selectorCode)
        
        return when {
            baseSelector.contains(".text(") -> {
                val text = extractSelectorValue(baseSelector, "text")
                Log.d(TAG, "使用文本查找: '$text', 实例索引: $instanceIdx")
                findNodeByText(rootNode, text, instanceIdx)
            }
            baseSelector.contains(".description(") -> {
                val desc = extractSelectorValue(baseSelector, "description")
                Log.d(TAG, "使用描述查找: '$desc', 实例索引: $instanceIdx")
                findNodeByDescription(rootNode, desc, instanceIdx)
            }
            baseSelector.contains(".resourceId(") -> {
                val id = extractSelectorValue(baseSelector, "resourceId")
                Log.d(TAG, "使用资源ID查找: '$id', 实例索引: $instanceIdx")
                findNodeById(rootNode, id, instanceIdx)
            }
            baseSelector.contains(".className(") -> {
                val className = extractSelectorValue(baseSelector, "className")
                Log.d(TAG, "使用类名查找: '$className', 实例索引: $instanceIdx")
                findNodeByClassName(rootNode, className, instanceIdx)
            }
            else -> {
                Log.e(TAG, "不支持的选择器类型: $selectorCode")
                null
            }
        }
    }

    private fun extractInstanceIndex(code: String): Int {
        val regex = """.instance\((-?\d+)\)""".toRegex()
        return regex.find(code)?.groupValues?.get(1)?.toIntOrNull() ?: 0
    }

    private fun removeInstanceSelector(code: String): String {
        return code.replace(""".instance\(\d+\)""".toRegex(), "")
    }

    private fun extractSelectorValue(code: String, type: String): String {
        val regex = """.$type\("([^"]+)"\)""".toRegex()
        val value = regex.find(code)?.groupValues?.get(1) ?: ""
        return value
    }

    private fun getActualIndex(index: Int, size: Int): Int {
        return when {
            size == 0 -> -1
            index >= 0 -> index
            -index <= size -> size + index
            else -> -1
        }
    }

    private fun findNodeByText(rootNode: AccessibilityNodeInfo, text: String, instanceIdx: Int = 0): AccessibilityNodeInfo? {
        try {
            val nodes = rootNode.findAccessibilityNodeInfosByText(text)
            val actualIdx = getActualIndex(instanceIdx, nodes.size)
            if (actualIdx == -1) {
                Log.d(TAG, "文本节点索引越界: index=$instanceIdx, size=${nodes.size}")
                nodes.forEach { it.recycle() }
                return null
            }
            
            val result = nodes[actualIdx].also {
                val bounds = Rect()
                it.getBoundsInScreen(bounds)
                Log.d(TAG, "找到文本节点 [${actualIdx + 1}/${nodes.size}]: '$text'")
            }
            // 回收未使用的节点
            nodes.forEachIndexed { index, node ->
                if (index != actualIdx) {
                    node.recycle()
                }
            }
            return result
        } catch (e: Exception) {
            Log.e(TAG, "通过文本查找节点时出错: ${e.message}")
            return null
        }
    }

    private fun findNodeById(rootNode: AccessibilityNodeInfo, id: String, instanceIdx: Int = 0): AccessibilityNodeInfo? {
        try {
            val nodes = rootNode.findAccessibilityNodeInfosByViewId(id)
            val actualIdx = getActualIndex(instanceIdx, nodes.size)
            if (actualIdx == -1) {
                Log.d(TAG, "ID节点索引越界: index=$instanceIdx, size=${nodes.size}")
                nodes.forEach { it.recycle() }
                return null
            }
            
            val result = nodes[actualIdx].also {
                val bounds = Rect()
                it.getBoundsInScreen(bounds)
                Log.d(TAG, "找到ID节点 [${actualIdx + 1}/${nodes.size}]: '$id'")
            }
            // 回收未使用的节点
            nodes.forEachIndexed { index, node ->
                if (index != actualIdx) {
                    node.recycle()
                }
            }
            return result
        } catch (e: Exception) {
            Log.e(TAG, "通过ID查找节点时出错: ${e.message}")
            return null
        }
    }

    private fun findNodeByClassName(rootNode: AccessibilityNodeInfo, className: String, instanceIdx: Int = 0): AccessibilityNodeInfo? {
        val nodes = mutableListOf<AccessibilityNodeInfo>()
        try {
            fun collectNodes(node: AccessibilityNodeInfo) {
                if (node.className?.toString() == className) {
                    nodes.add(node)
                }
                
                for (i in 0 until node.childCount) {
                    node.getChild(i)?.let { child ->
                        collectNodes(child)
                        // 如果不是目标节点，立即回收
                        if (child.className?.toString() != className) {
                            child.recycle()
                        }
                    }
                }
            }
            
            collectNodes(rootNode)
            
            val actualIdx = getActualIndex(instanceIdx, nodes.size)
            if (actualIdx == -1) {
                Log.d(TAG, "类名节点索引越界: index=$instanceIdx, size=${nodes.size}")
                nodes.forEach { it.recycle() }
                return null
            }
            
            val result = nodes[actualIdx].also {
                Log.d(TAG, "找到类名节点 [${actualIdx + 1}/${nodes.size}]: '$className'")
            }
            
            // 回收未使用的节点
            nodes.forEachIndexed { index, node ->
                if (index != actualIdx) {
                    node.recycle()
                }
            }
            
            return result
        } catch (e: Exception) {
            Log.e(TAG, "通过类名查找节点时出错: ${e.message}")
            // 确保异常情况下也能回收所有节点
            nodes.forEach { it.recycle() }
            return null
        }
    }

    private fun findNodeByDescription(rootNode: AccessibilityNodeInfo, description: String, instanceIdx: Int = 0): AccessibilityNodeInfo? {
        val nodes = mutableListOf<AccessibilityNodeInfo>()
        try {
            fun collectNodes(node: AccessibilityNodeInfo) {
                if (node.contentDescription?.toString() == description) {
                    nodes.add(node)
                }
                
                for (i in 0 until node.childCount) {
                    node.getChild(i)?.let { child ->
                        collectNodes(child)
                        // 如果不是目标节点，立即回收
                        if (child.contentDescription?.toString() != description) {
                            child.recycle()
                        }
                    }
                }
            }
            
            collectNodes(rootNode)
            
            val actualIdx = getActualIndex(instanceIdx, nodes.size)
            if (actualIdx == -1) {
                Log.d(TAG, "描述节点索引越界: index=$instanceIdx, size=${nodes.size}")
                nodes.forEach { it.recycle() }
                return null
            }
            
            val result = nodes[actualIdx].also {
                Log.d(TAG, "找到描述节点 [${actualIdx + 1}/${nodes.size}]: '$description'")
            }
            
            // 回收未使用的节点
            nodes.forEachIndexed { index, node ->
                if (index != actualIdx) {
                    node.recycle()
                }
            }
            
            return result
        } catch (e: Exception) {
            Log.e(TAG, "通过描述查找节点时出错: ${e.message}")
            // 确保异常情况下也能回收所有节点
            nodes.forEach { it.recycle() }
            return null
        }
    }
} 