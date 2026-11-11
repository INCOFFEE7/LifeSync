package com.example.lifesync_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class BentoWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_bento)

            // Click root to open app
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val launchPi = PendingIntent.getActivity(
                context, 301, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.bento_root, launchPi)

            // Click "+ Catat" button
            val addNoteIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("lifesync://add_note")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val addNotePi = PendingIntent.getActivity(
                context, 302, addNoteIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.bento_add_note_btn, addNotePi)

            // Refresh button
            val refreshIntent = Intent(context, BentoWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            }
            val refreshPi = PendingIntent.getBroadcast(
                context, 303, refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.bento_refresh_btn, refreshPi)

            // Populate data
            val dateStr = widgetData.getString("bento_date", "Hari Ini") ?: "Hari Ini"
            val expenseStr = widgetData.getString("bento_expense", "Rp 0") ?: "Rp 0"
            val incomeStr = widgetData.getString("bento_income", "+ Masuk Rp 0") ?: "+ Masuk Rp 0"

            views.setTextViewText(R.id.bento_date, dateStr)
            views.setTextViewText(R.id.bento_expense, expenseStr)
            views.setTextViewText(R.id.bento_income, incomeStr)

            // Target data
            val hasTarget = widgetData.getBoolean("bento_has_target", false)
            if (hasTarget) {
                views.setTextViewText(R.id.bento_target_title, widgetData.getString("bento_target_title", "Target Nabung"))
                views.setTextViewText(R.id.bento_target_pct, widgetData.getString("bento_target_pct", "0%"))
                views.setProgressBar(R.id.bento_target_bar, 100, widgetData.getInt("bento_target_progress", 0), false)
                views.setTextViewText(R.id.bento_target_days, widgetData.getString("bento_target_days", ""))
            } else {
                views.setTextViewText(R.id.bento_target_title, "Target Nabung")
                views.setTextViewText(R.id.bento_target_pct, "")
                views.setProgressBar(R.id.bento_target_bar, 100, 0, false)
                views.setTextViewText(R.id.bento_target_days, "Pin target di WhatToDo")
            }

            // Reminder data
            val hasReminder = widgetData.getBoolean("bento_has_reminder", false)
            if (hasReminder) {
                views.setTextViewText(R.id.bento_reminder_title, widgetData.getString("bento_reminder_title", "Pengingat"))
                views.setTextViewText(R.id.bento_reminder_time, widgetData.getString("bento_reminder_time", ""))
                views.setTextViewText(R.id.bento_reminder_date, widgetData.getString("bento_reminder_date", ""))
            } else {
                views.setTextViewText(R.id.bento_reminder_title, "Pengingat")
                views.setTextViewText(R.id.bento_reminder_time, "")
                views.setTextViewText(R.id.bento_reminder_date, "Pin pengingat di WhatToDo")
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
