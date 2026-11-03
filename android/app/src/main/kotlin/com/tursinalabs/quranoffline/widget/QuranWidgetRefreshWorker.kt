package com.tursinalabs.quranoffline.widget

import android.content.Context
import android.net.Uri
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import java.util.concurrent.TimeUnit

/**
 * Once a day, asks Flutter (home_widget's headless engine) to rebuild the
 * widget payload so the weekly reflection and its ayah image roll over
 * without the app being opened. Flutter's `homeWidgetBackgroundCallback`
 * handles [REFRESH_URI].
 */
class QuranWidgetRefreshWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            HomeWidgetBackgroundIntent.getBroadcast(applicationContext, Uri.parse(REFRESH_URI)).send()
            Result.success()
        } catch (_: Exception) {
            Result.retry()
        }
    }

    companion object {
        const val REFRESH_URI = "quranoffline://widget/refresh"
        private const val WORK_NAME = "quran_widget_daily_refresh"

        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<QuranWidgetRefreshWorker>(1, TimeUnit.DAYS).build()
            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, request)
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}
