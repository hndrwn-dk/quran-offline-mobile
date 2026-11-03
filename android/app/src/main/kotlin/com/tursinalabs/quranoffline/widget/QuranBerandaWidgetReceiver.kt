package com.tursinalabs.quranoffline.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class QuranBerandaWidgetReceiver : HomeWidgetGlanceWidgetReceiver<QuranBerandaWidget>() {
    override val glanceAppWidget = QuranBerandaWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        QuranWidgetRefreshWorker.schedule(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        // KEEP policy: a no-op when already scheduled; restores it after an app update.
        QuranWidgetRefreshWorker.schedule(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        QuranWidgetRefreshWorker.cancel(context)
    }
}
