package com.tursinalabs.quranoffline.notifications

import android.content.Context
import org.json.JSONArray

/**
 * flutter_local_notifications stores pending alarms as JSON.
 * +35 used exact modes; Play policy later dropped USE_EXACT_ALARM.
 * On MY_PACKAGE_REPLACED the plugin reschedules, throws, and deletes the row
 * before Dart [WeeklyReminderService] can run.
 */
internal object PluginScheduledNotificationCache {
    const val PREFS_NAME = "scheduled_notifications"
    const val PREFS_KEY = "scheduled_notifications"
    const val INEXACT_ALLOW_WHILE_IDLE = "inexactAllowWhileIdle"

    private val exactModes = setOf("exact", "exactAllowWhileIdle", "alarmClock")

    fun downgradeExactModes(json: String?): String? {
        if (json == null) return null
        val array = JSONArray(json)
        for (i in 0 until array.length()) {
            val item = array.optJSONObject(i) ?: continue
            val mode = when {
                item.has("scheduleMode") -> item.opt("scheduleMode")
                item.has("allowWhileIdle") -> item.opt("allowWhileIdle")
                else -> null
            }
            if (mode is Boolean || (mode is String && mode in exactModes)) {
                item.put("scheduleMode", INEXACT_ALLOW_WHILE_IDLE)
            }
        }
        return array.toString()
    }

    fun containsNotificationId(json: String?, id: Int): Boolean {
        if (json == null) return false
        val array = JSONArray(json)
        for (i in 0 until array.length()) {
            val item = array.optJSONObject(i) ?: continue
            if (item.optInt("id", Int.MIN_VALUE) == id) return true
        }
        return false
    }

    fun applyDowngrade(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val original = prefs.getString(PREFS_KEY, null) ?: return false
        val rewritten = downgradeExactModes(original) ?: return false
        if (rewritten == original) return false
        return prefs.edit().putString(PREFS_KEY, rewritten).commit()
    }
}
