package com.virelon.spent_time_focus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.virelon.spent_time_focus.R

class CalendarWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.calendar_widget_layout).apply {
                val day = widgetData.getString("calendar_day", "30") ?: "30"
                val month = widgetData.getString("calendar_month", "ARALIK") ?: "ARALIK"
                val weekday = widgetData.getString("calendar_weekday", "Salı") ?: "Salı"
                
                setTextViewText(R.id.calendar_day, day)
                setTextViewText(R.id.calendar_month, month)
                setTextViewText(R.id.calendar_weekday, weekday)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
