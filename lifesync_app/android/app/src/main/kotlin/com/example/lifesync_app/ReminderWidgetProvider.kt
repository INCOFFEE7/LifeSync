package com.example.lifesync_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar

class ReminderWidgetProvider : HomeWidgetProvider() {

    companion object {
        const val ACTION_UPDATE_CLOCK = "com.example.lifesync_app.ACTION_UPDATE_REMINDER_CLOCK"
        private const val REQUEST_CODE_ALARM = 7001
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            updateWidgetViews(context, appWidgetManager, widgetId, widgetData)
        }
        // Schedule per-minute refresh so countdown updates
        scheduleMinuteRefresh(context, appWidgetIds)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        // Already handled in onUpdate
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelMinuteRefresh(context)
    }

    private fun updateWidgetViews(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int, widgetData: SharedPreferences) {
        val views = RemoteViews(context.packageName, R.layout.widget_reminder)

        // Click root to open app
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val launchPi = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, launchPi)

        // Refresh button — triggers onUpdate immediately
        val refreshIntent = Intent(context, ReminderWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId))
        }
        val refreshPi = PendingIntent.getBroadcast(
            context, 2, refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.r_refresh_btn, refreshPi)

        // Slot data
        val slotIds = listOf(
            listOf(R.id.rslot0, R.id.r0_title, R.id.r0_date, R.id.r0_time),
            listOf(R.id.rslot1, R.id.r1_title, R.id.r1_date, R.id.r1_time),
            listOf(R.id.rslot2, R.id.r2_title, R.id.r2_date, R.id.r2_time)
        )
        val dividerIds = listOf(R.id.rdivider0, R.id.rdivider1)

        var anyVisible = false
        for (i in 0..2) {
            val isVisible = widgetData.getBoolean("r${i}_visible", false)
            val ids = slotIds[i]

            if (isVisible) {
                anyVisible = true
                views.setViewVisibility(ids[0], View.VISIBLE)
                views.setTextViewText(ids[1], widgetData.getString("r${i}_title", "") ?: "")
                views.setTextViewText(ids[2], widgetData.getString("r${i}_date", "") ?: "")

                // Recalculate countdown dynamically from stored epoch
                val targetEpoch = widgetData.getLong("r${i}_target_epoch", -1L)
                val countdownText = if (targetEpoch > 0) {
                    computeCountdown(targetEpoch)
                } else {
                    widgetData.getString("r${i}_time", "") ?: ""
                }
                views.setTextViewText(ids[3], countdownText)
            } else {
                views.setViewVisibility(ids[0], View.GONE)
            }
        }

        for (i in 0..1) {
            val thisVisible = widgetData.getBoolean("r${i}_visible", false)
            val nextVisible = widgetData.getBoolean("r${i + 1}_visible", false)
            views.setViewVisibility(dividerIds[i], if (thisVisible && nextVisible) View.VISIBLE else View.GONE)
        }

        views.setViewVisibility(R.id.r_empty_text, if (anyVisible) View.GONE else View.VISIBLE)
        appWidgetManager.updateAppWidget(widgetId, views)
    }

    /** Schedule AlarmManager to fire every minute to refresh countdown safely */
    private fun scheduleMinuteRefresh(context: Context, appWidgetIds: IntArray) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ReminderWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
        }
        val pi = PendingIntent.getBroadcast(
            context, REQUEST_CODE_ALARM, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val cal = Calendar.getInstance().apply {
            add(Calendar.MINUTE, 1)
            set(Calendar.SECOND, 0)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pi)
                } else {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pi)
                }
            } else {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pi)
            }
        } catch (e: Exception) {
            try {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pi)
            } catch (_: Exception) {
                // Ignore SecurityException safely so widget update never crashes
            }
        }
    }

    private fun cancelMinuteRefresh(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ReminderWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }
        val pi = PendingIntent.getBroadcast(
            context, REQUEST_CODE_ALARM, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pi)
    }

    /** Compute a human-readable countdown string from a target epoch timestamp */
    private fun computeCountdown(targetEpoch: Long): String {
        val now = System.currentTimeMillis()
        val diff = targetEpoch - now
        if (diff <= 0) return "Sudah lewat"

        val totalMinutes = diff / 60000
        val days = totalMinutes / (24 * 60)
        val hours = (totalMinutes % (24 * 60)) / 60
        val minutes = totalMinutes % 60

        return when {
            days > 0 -> "${days}h ${hours}j ${minutes}m lagi"
            hours > 0 -> "${hours}j ${minutes}m lagi"
            else -> "${minutes}m lagi"
        }
    }
}
