package com.mobilellm.awattackerapplier

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import android.graphics.drawable.ColorDrawable
import android.util.Log
import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityNodeInfo

// 简化的数据类，只记录节点和修改后的文本
data class ModifiedNode(
    val node: AccessibilityNodeInfo,
    val modifiedText: String
)

class WindowManagerHelper private constructor(private val context: Context) {
    companion object {
        private const val TAG = "WindowManagerHelper"
        
        @Volatile
        private var instance: WindowManagerHelper? = null
        
        fun getInstance(context: Context): WindowManagerHelper {
            return instance ?: synchronized(this) {
                instance ?: WindowManagerHelper(context).also { instance = it }
            }
        }
        
        fun hasInstance(): Boolean = instance != null
        
        fun initialize(context: AccessibilityService) {
            if (instance == null) {
                synchronized(this) {
                    if (instance == null) {
                        instance = WindowManagerHelper(context)
                        Log.d(TAG, "WindowManagerHelper initialized with AccessibilityService context")
                    }
                }
            }
        }
        
        fun destroyInstance() {
            instance?.let { helper ->
                helper.removeAllOverlays()
                instance = null
                Log.d(TAG, "WindowManagerHelper instance destroyed")
            }
        }
    }

    private val windowManager: WindowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val activeWindows = mutableMapOf<String, TextView>()
    // 记录匹配到的节点和它们的新文本
    private val modifiedNodes = mutableListOf<ModifiedNode>()

    // 新增：记录匹配到的节点
    fun addModifiedNode(node: AccessibilityNodeInfo, newText: String) {
        // 移除之前可能存在的相同节点的记录
        modifiedNodes.removeAll { it.node == node }
        // 添加新记录
        modifiedNodes.add(ModifiedNode(node, newText))
    }

    // 新增：清除所有记录的节点
    fun clearModifiedNodes() {
        modifiedNodes.forEach { it.node.recycle() }
        modifiedNodes.clear()
    }

    // 新增：获取节点的修改后文本
    fun getModifiedText(node: AccessibilityNodeInfo): String? {
        return modifiedNodes.find { it.node == node }?.modifiedText
    }

    // 新增：判断节点是否被修改
    fun isNodeModified(node: AccessibilityNodeInfo): Boolean {
        return modifiedNodes.any { it.node == node }
    }

    // 新增：获取所有修改过的节点信息
    fun getAllModifiedNodes(): List<ModifiedNode> {
        return modifiedNodes.toList()
    }

    // 新增：移除单个修改过的节点
    fun removeModifiedNode(node: AccessibilityNodeInfo) {
        modifiedNodes.find { it.node == node }?.let {
            it.node.recycle()
            modifiedNodes.remove(it)
        }
    }

    private fun parseColor(colorValue: Number): Int {
        // 将颜色值转换为 Long 以避免溢出
        val longValue = colorValue.toLong() and 0xFFFFFFFFL
        
        // 提取 ARGB 分量
        val alpha = ((longValue shr 24) and 0xFFL).toInt()
        val red = ((longValue shr 16) and 0xFFL).toInt()
        val green = ((longValue shr 8) and 0xFFL).toInt()
        val blue = (longValue and 0xFFL).toInt()
        
        Log.d(TAG, "Parsing color - Long value: ${String.format("0x%08X", longValue)}")
        Log.d(TAG, "Parsing color - A:$alpha R:$red G:$green B:$blue")
        
        // 使用 Color.argb 创建颜色值
        return Color.argb(alpha, red, green, blue)
    }
    
    private fun getStatusBarHeight(): Int {
        val resourceId = context.resources.getIdentifier("status_bar_height", "dimen", "android")
        val height = if (resourceId > 0) {
            context.resources.getDimensionPixelSize(resourceId)
        } else {
            0
        }
        Log.d(TAG, "Status bar height: $height")
        return height
    }

    private fun createLayoutParams(params: Map<String, Any>): WindowManager.LayoutParams {
        val posX = (params["x"] as? Double)?.toInt() ?: 0
        val posY = (params["y"] as? Double)?.toInt() ?: 0
        
        Log.d(TAG, "Original coordinates: x=$posX, y=$posY")
        
        return WindowManager.LayoutParams().apply {
            type = if (context is AccessibilityService) {
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            }
            
            flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
            
            format = PixelFormat.TRANSLUCENT
            
            x = posX
            y = posY
            width = (params["width"] as? Double)?.toInt() ?: WindowManager.LayoutParams.WRAP_CONTENT
            height = (params["height"] as? Double)?.toInt() ?: WindowManager.LayoutParams.WRAP_CONTENT
            
            gravity = Gravity.TOP or Gravity.START
        }
    }

    fun createOverlay(id: String, params: Map<String, Any>) {
        try {
            // 添加绘制检查
            if (context is AWAccessibilityService && !context.isDrawingAllowed()) {
                Log.d(TAG, "当前不允许绘制，忽略创建悬浮窗请求: $id")
                return
            }

            // 如果已存在，先移除
            removeOverlay(id)
            
            // 使用正确的 context 创建 TextView
            val textView = TextView(if (context is AccessibilityService) context else context.applicationContext).apply {
                // 设置文本内容
                text = params["text"] as? String ?: ""
                
                // 设置字体大小
                textSize = (params["fontSize"] as? Double)?.toFloat() ?: 14f
                
                // 设置颜色
                val textColorValue = params["textColor"] as? Number ?: Color.BLACK
                val backgroundColorValue = params["backgroundColor"] as? Number ?: Color.WHITE
                
                Log.d(TAG, "Raw Text Color Value: $textColorValue")
                Log.d(TAG, "Raw Background Color Value: $backgroundColorValue")
                
                val finalTextColor = parseColor(textColorValue)
                val finalBackgroundColor = parseColor(backgroundColorValue)
                
                Log.d(TAG, "Final Text Color: ${String.format("#%08X", finalTextColor)}")
                Log.d(TAG, "Final Background Color: ${String.format("#%08X", finalBackgroundColor)}")
                
                setTextColor(finalTextColor)
                background = android.graphics.drawable.ColorDrawable(finalBackgroundColor)
                
                // 设置对齐方式
                gravity = when (params["horizontalAlign"] as? Int) {
                    1 -> Gravity.CENTER_HORIZONTAL
                    2 -> Gravity.END
                    else -> Gravity.START
                } or when (params["verticalAlign"] as? Int) {
                    1 -> Gravity.CENTER_VERTICAL
                    2 -> Gravity.BOTTOM
                    else -> Gravity.TOP
                }
                
                // 设置内边距
                val padding = params["padding"] as? Map<String, Any>
                setPadding(
                    padding?.get("left")?.toString()?.toFloat()?.toInt() ?: 0,
                    padding?.get("top")?.toString()?.toFloat()?.toInt() ?: 0,
                    padding?.get("right")?.toString()?.toFloat()?.toInt() ?: 0,
                    padding?.get("bottom")?.toString()?.toFloat()?.toInt() ?: 0
                )
            }
            
            // 创建并应用布局参数
            val layoutParams = createLayoutParams(params)
            
            try {
                windowManager.addView(textView, layoutParams)
                activeWindows[id] = textView
                Log.d(TAG, "Successfully created overlay: $id")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to add overlay view: $e")
                e.printStackTrace()
                throw e
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error creating overlay: $e")
            e.printStackTrace()
            throw e
        }
    }
    
    fun updateOverlay(id: String, params: Map<String, Any>) {
        // 添加绘制检查
        if (context is AWAccessibilityService && !context.isDrawingAllowed()) {
            Log.d(TAG, "当前不允许绘制，忽略更新悬浮窗请求: $id")
            return
        }

        activeWindows[id]?.let { textView ->
            // 更新TextView属性
            textView.apply {
                text = params["text"] as? String ?: text
                if (params.containsKey("fontSize")) {
                    textSize = (params["fontSize"] as? Double)?.toFloat() ?: textSize
                }
                if (params.containsKey("textColor")) {
                    val textColorValue = params["textColor"] as? Number ?: currentTextColor
                    android.util.Log.d("WindowManagerHelper", "Raw Update Text Color Value: $textColorValue")
                    val finalTextColor = parseColor(textColorValue)
                    android.util.Log.d("WindowManagerHelper", "Final Update Text Color: ${String.format("#%08X", finalTextColor)}")
                    setTextColor(finalTextColor)
                }
                if (params.containsKey("backgroundColor")) {
                    val backgroundColorValue = params["backgroundColor"] as? Number ?: Color.WHITE
                    android.util.Log.d("WindowManagerHelper", "Raw Update Background Color Value: $backgroundColorValue")
                    val finalBackgroundColor = parseColor(backgroundColorValue)
                    android.util.Log.d("WindowManagerHelper", "Final Update Background Color: ${String.format("#%08X", finalBackgroundColor)}")
                    background = android.graphics.drawable.ColorDrawable(finalBackgroundColor)
                }
            }
            
            // 更新布局参数
            val layoutParams = createLayoutParams(params)
            try {
                windowManager.updateViewLayout(textView, layoutParams)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    fun removeOverlay(id: String): Boolean {
        return try {
            activeWindows[id]?.let { textView ->
                try {
                    windowManager.removeView(textView)
                    activeWindows.remove(id)
                    Log.d(TAG, "Successfully removed overlay: $id")
                    true
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to remove overlay view: $e")
                    e.printStackTrace()
                    // 如果是 IllegalArgumentException，说明 view 已经被移除
                    if (e is IllegalArgumentException) {
                        activeWindows.remove(id)
                        true
                    } else {
                        false
                    }
                }
            } ?: run {
                Log.d(TAG, "Overlay not found: $id")
                true // 如果悬浮窗不存在，视为移除成功
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error removing overlay: $e")
            e.printStackTrace()
            false
        }
    }
    
    fun removeAllOverlays(): Boolean {
        var success = true
        val ids = activeWindows.keys.toList() // 创建副本以避免并发修改
        
        Log.d(TAG, "Removing all overlays. Active overlays: ${ids.joinToString()}")
        
        for (id in ids) {
            if (!removeOverlay(id)) {
                success = false
                Log.e(TAG, "Failed to remove overlay: $id")
            }
        }
        
        // 即使部分失败也清空列表，因为可能有些已经成功移除
        if (activeWindows.isNotEmpty()) {
            Log.w(TAG, "Forcing clear of active windows map")
            activeWindows.clear()
        }
        
        return success
    }
} 