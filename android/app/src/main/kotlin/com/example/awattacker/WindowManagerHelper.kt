package com.example.awattacker

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.view.Gravity
import android.view.WindowManager
import android.widget.TextView
import android.util.TypedValue

class WindowManagerHelper(private val context: Context) {
    private val windowManager: WindowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val activeWindows = mutableMapOf<String, TextView>()
    
    private fun parseColor(colorValue: Number): Int {
        // 将颜色值转换为 Long 以避免溢出
        val longValue = colorValue.toLong() and 0xFFFFFFFFL
        
        // 提取 ARGB 分量
        val alpha = ((longValue shr 24) and 0xFFL).toInt()
        val red = ((longValue shr 16) and 0xFFL).toInt()
        val green = ((longValue shr 8) and 0xFFL).toInt()
        val blue = (longValue and 0xFFL).toInt()
        
        android.util.Log.d("WindowManagerHelper", "Parsing color - Long value: ${String.format("0x%08X", longValue)}")
        android.util.Log.d("WindowManagerHelper", "Parsing color - A:$alpha R:$red G:$green B:$blue")
        
        // 使用 Color.argb 创建颜色值
        return Color.argb(alpha, red, green, blue)
    }
    
    fun createOverlay(id: String, params: Map<String, Any>) {
        // 如果已存在，先移除
        removeOverlay(id)
        
        // 创建TextView并应用样式
        val textView = TextView(context).apply {
            // 设置文本内容
            text = params["text"] as? String ?: ""
            
            // 设置字体大小
            textSize = (params["fontSize"] as? Double)?.toFloat() ?: 14f
            
            // 设置颜色
            val textColorValue = params["textColor"] as? Number ?: Color.BLACK
            val backgroundColorValue = params["backgroundColor"] as? Number ?: Color.WHITE
            
            android.util.Log.d("WindowManagerHelper", "Raw Text Color Value: $textColorValue")
            android.util.Log.d("WindowManagerHelper", "Raw Background Color Value: $backgroundColorValue")
            
            val finalTextColor = parseColor(textColorValue)
            val finalBackgroundColor = parseColor(backgroundColorValue)
            
            android.util.Log.d("WindowManagerHelper", "Final Text Color: ${String.format("#%08X", finalTextColor)}")
            android.util.Log.d("WindowManagerHelper", "Final Background Color: ${String.format("#%08X", finalBackgroundColor)}")
            
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
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun createLayoutParams(params: Map<String, Any>): WindowManager.LayoutParams {
        return WindowManager.LayoutParams().apply {
            // 设置窗口类型
            type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            }
            
            // 设置窗口标志
            flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
            
            // 设置窗口格式
            format = PixelFormat.TRANSLUCENT
            
            // 设置位置和大小
            x = (params["x"] as? Double)?.toInt() ?: 0
            y = (params["y"] as? Double)?.toInt() ?: 0
            width = (params["width"] as? Double)?.toInt() ?: WindowManager.LayoutParams.WRAP_CONTENT
            height = (params["height"] as? Double)?.toInt() ?: WindowManager.LayoutParams.WRAP_CONTENT
            
            // 设置重力
            gravity = Gravity.TOP or Gravity.START
        }
    }
    
    fun updateOverlay(id: String, params: Map<String, Any>) {
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
    
    fun removeOverlay(id: String) {
        activeWindows[id]?.let { textView ->
            try {
                windowManager.removeView(textView)
                activeWindows.remove(id)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    fun removeAllOverlays() {
        activeWindows.keys.toList().forEach { id ->
            removeOverlay(id)
        }
    }
} 