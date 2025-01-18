package com.mobilellm.awattackerapplier

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
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.util.concurrent.atomic.AtomicBoolean
import java.util.Objects
import java.util.LinkedList
import com.mobilellm.awattackerapplier.proto.Accessibility.AccessibilityTree
import com.mobilellm.awattackerapplier.proto.Accessibility.AccessibilityNode
import com.mobilellm.awattackerapplier.proto.Accessibility.BoundingBox
import com.mobilellm.awattackerapplier.models.OverlayStyle
class AWAccessibilityService : AccessibilityService(), CoroutineScope {
    private val job = SupervisorJob()
    override val coroutineContext: CoroutineContext
        get() = Dispatchers.Main + job

    // 当前搜索的协程作用域
    private var searchScope: CoroutineScope? = null
    
    // 添加绘制锁
    private val drawingLock = AtomicBoolean(true)
    
    // 添加规则匹配状态标志
    private var hasMatchedRule = false

    // 添加获取绘制锁状态的方法
    fun isDrawingAllowed(): Boolean = drawingLock.get()

    companion object {
        private const val TAG = "AWAccessibilityService"
        private var instance: AWAccessibilityService? = null
        private var isFirstConnect = true
        
        // 添加状态保持变量
        private var savedPackage: String? = null
        private var savedActivity: String? = null
        private var savedWindowHash: Int = 0

        fun getInstance(): AWAccessibilityService? = instance
    }

    private var lastWindowHash: Int = 0
    private var lastPackage: String? = null
    private var lastActivity: String? = null
    private var isDetectionEnabled = false
    
    // 添加公有getter
    fun isDetectionEnabled(): Boolean = isDetectionEnabled

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
        "com.mobilellm.awattackerapplier"
    )

    // 添加标记当前是否正在查找的变量
    private var isSearching = false
    private var shouldCancelSearch = false

    private var pendingEvents = mutableListOf<Triple<String, String?, String?>>()
    private var retryJob: Job? = null

    // 状态队列
    private val stateQueue = LinkedList<ByteArray>()
    private val maxQueueSize = 10
    private val queueLock = Mutex()

    private fun cancelSearch() {
        searchScope?.cancel()
        searchScope = null
        drawingLock.set(false)  // 禁止绘制
        Log.d(TAG, "取消当前的查找操作，已禁止绘制")
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "AccessibilityService created")
        WindowManagerHelper.initialize(this)
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        configureService()
        
        if (isFirstConnect) {
            isFirstConnect = false
            isDetectionEnabled = false
            Log.d(TAG, "AccessibilityService 首次连接")
            sendWindowEvent(
                type = "SERVICE_CONNECTED",
                isFirstConnect = true
            )
        } else {
            if (!isDetectionEnabled) {
                isDetectionEnabled = true
                Log.d(TAG, "重连时重新启用检测功能")
            }
            Log.d(TAG, "AccessibilityService 重新连接")
            sendWindowEvent(
                type = "SERVICE_CONNECTED",
                isFirstConnect = false
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
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                handleWindowEvent(event)
            }
        }
    }

    private fun handleWindowEvent(event: AccessibilityEvent) {
        val currentTime = System.currentTimeMillis()
        val currentPackage = event.packageName?.toString()
        val currentActivity = event.className?.toString()
        
        // 检查是否需要忽略此事件
        if (currentTime - lastEventTime < EVENT_THROTTLE_TIME &&
            currentPackage == lastEventPackage &&
            currentActivity == lastEventActivity) {
            Log.d(TAG, "忽略重复的窗口事件")
            return
        }
        
        // 检查是否是需要忽略的包名
        if (currentPackage != null && 
            IGNORED_PACKAGES.any { currentPackage.startsWith(it) }) {
            Log.d(TAG, "忽略系统应用的窗口变化: $currentPackage")
            return
        }

        // 更新事件信息
        lastEventTime = currentTime
        lastEventPackage = currentPackage
        lastEventActivity = currentActivity
        
        if (currentPackage != null) {
            // 清理之前的节点记录
            WindowManagerHelper.getInstance(this).clearModifiedNodes()
            
            // 获取根节点
            val rootNode = rootInActiveWindow ?: return
            
            // 保存当前状态
            launch {
                Log.d(TAG, "窗口事件触发，保存当前状态")
                saveCurrentState(rootNode)
            }
            
            // 发送窗口事件通知，触发规则匹配和元素查找
            sendWindowEvent(type = "WINDOW_EVENT")
        }
    }

    // 在元素查找完成后调用此方法保存状态
    suspend fun saveStateAfterSearch(rootNode: AccessibilityNodeInfo?) {
        if (rootNode == null) {
            Log.d(TAG, "Root node is null, skip saving state")
            return
        }
        saveCurrentState(rootNode)
        // 清理节点记录
        WindowManagerHelper.getInstance(this).clearModifiedNodes()
    }

    private fun buildAccessibilityNode(node: AccessibilityNodeInfo): AccessibilityNode {
        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        
        val windowHelper = WindowManagerHelper.getInstance(this)
        // 检查节点是否被修改过
        val text = if (windowHelper.isNodeModified(node)) {
            windowHelper.getModifiedText(node) ?: node.text?.toString() ?: ""
        } else {
            node.text?.toString() ?: ""
        }
        
        val builder = AccessibilityNode.newBuilder()
            .setText(text)  // 使用可能被修改的文本
            .setContentDescription(node.contentDescription?.toString() ?: "")
            .setClassName(node.className?.toString() ?: "")
            .setPackageName(node.packageName?.toString() ?: "")
            .setResourceId(node.viewIdResourceName ?: "")
            
            // 设置边界
            .setBbox(BoundingBox.newBuilder()
                .setLeft(bounds.left)
                .setTop(bounds.top)
                .setRight(bounds.right)
                .setBottom(bounds.bottom)
                .build())
            
            // 设置状态标志
            .setIsCheckable(node.isCheckable)
            .setIsChecked(node.isChecked)
            // 为节点默认设置为可点击
            .setIsClickable(true)
            .setIsEditable(node.isEditable)
            .setIsEnabled(node.isEnabled)
            .setIsFocused(node.isFocused)
            .setIsFocusable(node.isFocusable)
            .setIsLongClickable(node.isLongClickable)
            .setIsScrollable(node.isScrollable)
            .setIsSelected(node.isSelected)
            .setIsVisible(node.isVisibleToUser)

        // 递归处理子节点
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { childNode ->
                builder.addChildren(buildAccessibilityNode(childNode))
                childNode.recycle()
            }
        }
        
        return builder.build()
    }

    // 获取最新状态
    suspend fun getLatestState(): ByteArray? {
        return queueLock.withLock {
            stateQueue.firstOrNull()
        }
    }

    private suspend fun saveCurrentState(rootNode: AccessibilityNodeInfo) {
        try {
            // 构建无障碍树
            val tree = AccessibilityTree.newBuilder()
                .setRoot(buildAccessibilityNode(rootNode))
                .setTimestamp(System.currentTimeMillis())
                .build()

            // 序列化并保存
            val bytes = tree.toByteArray()
            queueLock.withLock {
                stateQueue.addFirst(bytes)
                if (stateQueue.size > maxQueueSize) {
                    stateQueue.removeLast()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save state", e)
        }
    }

    // 元素查找功能
    suspend fun findElementByUiSelector(style: OverlayStyle): AccessibilityNodeInfo? = withContext(Dispatchers.Default) {
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

                val node = UiAutomatorHelper.findNodeBySelector(rootNode, style.uiAutomatorCode)
                if (node == null) {
                    Log.d(TAG, "Node not found with selector: ${style.uiAutomatorCode}, retry: ${retryCount + 1}/$maxRetries")
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
                    WindowManagerHelper.getInstance(this@AWAccessibilityService)
                        .addModifiedNode(node, style.text)
                    Log.d(TAG, "Found matching node, recorded with modified text: ${style.text}")
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
    suspend fun findElements(styles: List<OverlayStyle>): List<ElementResult> = withContext(Dispatchers.Default) {
        if (hasMatchedRule) {
            Log.d(TAG, "开始批量查找元素，允许绘制")
            drawingLock.set(true)  // 允许绘制
        } else {
            Log.d(TAG, "当前窗口没有匹配规则，保持禁止绘制状态")
            return@withContext styles.map { 
                ElementResult(success = false, message = "No matching rule for current window") 
            }
        }
        
        // 创建新的搜索作用域
        searchScope?.cancel()
        searchScope = CoroutineScope(coroutineContext + Job())
        
        try {
            val results = searchScope?.let { scope ->
                styles.mapIndexed { index, style ->
                    scope.async {
                        Log.d(TAG, "查找第 ${index + 1} 个元素: ${style.uiAutomatorCode}")
                        try {
                            val node = findElementByUiSelector(style)
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

            // 在所有元素查找完成后保存状态
            val rootNode = rootInActiveWindow
            saveStateAfterSearch(rootNode)
            rootNode?.recycle()  // 记得回收根节点

            return@withContext results
        } catch (e: CancellationException) {
            Log.d(TAG, "搜索操作被取消")
            styles.map { 
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
                        sendWindowEvent(type, false)
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
        isFirstConnect: Boolean = false
    ) {
        val event = JSONObject().apply {
            put("type", type)
            put("timestamp", System.currentTimeMillis())
            put("is_first_connect", isFirstConnect)
        }

        MainActivity.getMethodChannel()?.let {
            it.invokeMethod("onWindowEvent", event.toString())
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "AccessibilityService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        job.cancel()
        retryJob?.cancel()
        lastEventSource?.recycle()
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

    // 添加更新规则匹配状态的方法
    fun updateRuleMatchStatus(hasMatch: Boolean) {
        hasMatchedRule = hasMatch
        if (!hasMatch) {
            drawingLock.set(false)
            getWindowManagerHelper().removeAllOverlays()
        }
        Log.d(TAG, "更新规则匹配状态: hasMatch=$hasMatch")
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

    public fun extractSelectorValue(code: String, type: String): String {
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