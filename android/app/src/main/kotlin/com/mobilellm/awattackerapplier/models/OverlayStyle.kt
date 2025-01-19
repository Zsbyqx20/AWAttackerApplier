package com.mobilellm.awattackerapplier.models

import android.graphics.Color
import android.view.Gravity

data class OverlayStyle(
    val x: Double = 0.0,
    val y: Double = 0.0,
    val width: Double = 0.0,
    val height: Double = 0.0,
    val text: String = "",
    val fontSize: Double = 14.0,
    val backgroundColor: Int = Color.WHITE,
    val textColor: Int = Color.BLACK,
    val horizontalAlign: Int = Gravity.START,
    val verticalAlign: Int = Gravity.CENTER,
    val uiAutomatorCode: String = "",
    val padding: Padding = Padding()
) {
    data class Padding(
        val left: Double = 0.0,
        val top: Double = 0.0,
        val right: Double = 0.0,
        val bottom: Double = 0.0
    )

    companion object {
        fun fromMap(map: Map<String, Any?>): OverlayStyle {
            val paddingMap = (map["padding"] as? Map<String, Any>) ?: emptyMap()
            
            return OverlayStyle(
                x = (map["x"] as? Number)?.toDouble() ?: 0.0,
                y = (map["y"] as? Number)?.toDouble() ?: 0.0,
                width = (map["width"] as? Number)?.toDouble() ?: 0.0,
                height = (map["height"] as? Number)?.toDouble() ?: 0.0,
                text = (map["text"] as? String) ?: "",
                fontSize = (map["fontSize"] as? Number)?.toDouble() ?: 14.0,
                backgroundColor = parseColor(map["backgroundColor"] as? String, Color.WHITE),
                textColor = parseColor(map["textColor"] as? String, Color.BLACK),
                horizontalAlign = parseTextAlign(map["horizontalAlign"] as? String, true),
                verticalAlign = parseTextAlign(map["verticalAlign"] as? String, false),
                uiAutomatorCode = (map["uiAutomatorCode"] as? String) ?: "",
                padding = Padding(
                    left = (paddingMap["left"] as? Number)?.toDouble() ?: 0.0,
                    top = (paddingMap["top"] as? Number)?.toDouble() ?: 0.0,
                    right = (paddingMap["right"] as? Number)?.toDouble() ?: 0.0,
                    bottom = (paddingMap["bottom"] as? Number)?.toDouble() ?: 0.0
                )
            )
        }

        private fun parseColor(colorString: String?, defaultColor: Int): Int {
            if (colorString == null) return defaultColor
            return try {
                Color.parseColor(colorString)
            } catch (e: Exception) {
                defaultColor
            }
        }

        private fun parseTextAlign(align: String?, isHorizontal: Boolean): Int {
            return when (align?.toLowerCase()) {
                "left", "start" -> if (isHorizontal) Gravity.START else Gravity.TOP
                "center" -> Gravity.CENTER
                "right", "end" -> if (isHorizontal) Gravity.END else Gravity.BOTTOM
                else -> if (isHorizontal) Gravity.START else Gravity.CENTER
            }
        }
    }
}