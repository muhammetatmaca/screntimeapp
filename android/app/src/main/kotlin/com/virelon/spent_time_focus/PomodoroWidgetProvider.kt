package com.virelon.spent_time_focus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.virelon.spent_time_focus.R

class PomodoroWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.pomodoro_widget_layout).apply {
                val timer = widgetData.getString("pomodoro_timer", "25:00") ?: "25:00"
                val status = widgetData.getString("pomodoro_status", "ODAKLANMA") ?: "ODAKLANMA"
                val sessions = widgetData.getString("pomodoro_sessions", "Seans: 0/4") ?: "Seans: 0/4"
                
                setTextViewText(R.id.pomodoro_timer, timer)
                setTextViewText(R.id.pomodoro_status, status)
                setTextViewText(R.id.pomodoro_sessions, sessions)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
