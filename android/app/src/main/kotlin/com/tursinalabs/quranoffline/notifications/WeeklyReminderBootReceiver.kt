package com.tursinalabs.quranoffline.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver

/**
 * Runs before plugin reschedule on boot/upgrade so exact +35 rows are not wiped.
 */
class WeeklyReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action !in handledActions) return
        PluginScheduledNotificationCache.applyDowngrade(context)
        ScheduledNotificationBootReceiver().onReceive(context, intent)
    }

    companion object {
        private val handledActions = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
        )
    }
}
