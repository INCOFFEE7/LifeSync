package com.example.lifesync_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TargetWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_target)

            // Click root to open app
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val launchPi = PendingIntent.getActivity(
                context, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, launchPi)

            // Refresh button
            val refreshIntent = Intent(context, TargetWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            }
            val refreshPi = PendingIntent.getBroadcast(
                context, 1, refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.refresh_btn, refreshPi)

            // Slot data
            val slotIds = listOf(
                listOf(R.id.slot0, R.id.t0_title, R.id.t0_pct, R.id.t0_bar, R.id.t0_days, R.id.t0_today),
                listOf(R.id.slot1, R.id.t1_title, R.id.t1_pct, R.id.t1_bar, R.id.t1_days, R.id.t1_today),
                listOf(R.id.slot2, R.id.t2_title, R.id.t2_pct, R.id.t2_bar, R.id.t2_days, R.id.t2_today)
            )
            val dividerIds = listOf(R.id.divider0, R.id.divider1)

            var anyVisible = false
            for (i in 0..2) {
                val isVisible = widgetData.getBoolean("t${i}_visible", false)
                val ids = slotIds[i]

                if (isVisible) {
                    anyVisible = true
                    views.setViewVisibility(ids[0], View.VISIBLE)
                    views.setTextViewText(ids[1], widgetData.getString("t${i}_title", "") ?: "")
                    views.setTextViewText(ids[2], widgetData.getString("t${i}_pct", "") ?: "")
                    views.setProgressBar(ids[3], 100, widgetData.getInt("t${i}_progress", 0), false)
                    views.setTextViewText(ids[4], widgetData.getString("t${i}_days", "") ?: "")
                    views.setTextViewText(ids[5], widgetData.getString("t${i}_today", "") ?: "")
                } else {
                    views.setViewVisibility(ids[0], View.GONE)
                }
            }

            for (i in 0..1) {
                val thisVisible = widgetData.getBoolean("t${i}_visible", false)
                val nextVisible = widgetData.getBoolean("t${i + 1}_visible", false)
                views.setViewVisibility(dividerIds[i], if (thisVisible && nextVisible) View.VISIBLE else View.GONE)
            }

            views.setViewVisibility(R.id.empty_text, if (anyVisible) View.GONE else View.VISIBLE)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
