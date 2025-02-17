package com.mobilellm.awattackerapplier

import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class ConditionChecker {
    companion object {
        private const val TAG = "ConditionChecker"
        private const val CACHE_DURATION_MS = 1000L // 缓存有效期为1秒
    }

    // 缓存检查结果
    private val conditionCache = mutableMapOf<String, CachedResult>()

    data class CachedResult(
        val result: Boolean,
        val timestamp: Long
    )

    // 检查单个条件
    suspend fun checkCondition(
        rootNode: AccessibilityNodeInfo,
        condition: String,
        isAllowCondition: Boolean
    ): Boolean = withContext(Dispatchers.Default) {
        try {
            // 检查缓存
            val cacheKey = "${condition}_${isAllowCondition}"
            val cachedResult = conditionCache[cacheKey]
            val currentTime = System.currentTimeMillis()

            if (cachedResult != null && (currentTime - cachedResult.timestamp) < CACHE_DURATION_MS) {
                Log.d(TAG, "使用缓存结果: condition=$condition, result=${cachedResult.result}")
                return@withContext cachedResult.result
            }

            // 执行实际的条件检查
            val result = UiAutomatorHelper.findNodeBySelector(rootNode, condition) != null
            
            // 更新缓存
            conditionCache[cacheKey] = CachedResult(result, currentTime)
            
            Log.d(TAG, "条件检查结果: condition=$condition, result=$result")
            result
        } catch (e: Exception) {
            Log.e(TAG, "条件检查失败: ${e.message}")
            false
        }
    }

    // 并行检查多个条件
    suspend fun checkConditions(
        rootNode: AccessibilityNodeInfo,
        allowConditions: List<String>?,
        denyConditions: List<String>?
    ): Boolean = coroutineScope {
        try {
            // 如果没有任何条件，返回 true
            if (allowConditions.isNullOrEmpty() && denyConditions.isNullOrEmpty()) {
                return@coroutineScope true
            }

            // 并行检查 allow 条件
            val allowResults = allowConditions?.map { condition ->
                async {
                    checkCondition(rootNode, condition, true)
                }
            }

            // 并行检查 deny 条件
            val denyResults = denyConditions?.map { condition ->
                async {
                    checkCondition(rootNode, condition, false)
                }
            }

            // 等待所有 allow 条件的结果
            val allowMatches = allowResults?.map { it.await() } ?: emptyList()
            // 如果有 allow 条件但没有一个匹配，返回 false
            if (allowConditions?.isNotEmpty() == true && !allowMatches.any { it }) {
                Log.d(TAG, "Allow 条件检查失败")
                return@coroutineScope false
            }

            // 等待所有 deny 条件的结果
            val denyMatches = denyResults?.map { it.await() } ?: emptyList()
            // 如果有任何一个 deny 条件匹配，返回 false
            if (denyMatches.any { it }) {
                Log.d(TAG, "Deny 条件检查失败")
                return@coroutineScope false
            }

            // 所有条件都满足
            true
        } catch (e: Exception) {
            Log.e(TAG, "条件检查过程中发生错误: ${e.message}")
            false
        }
    }

    // 清除缓存
    fun clearCache() {
        conditionCache.clear()
        Log.d(TAG, "条件检查缓存已清除")
    }
} 