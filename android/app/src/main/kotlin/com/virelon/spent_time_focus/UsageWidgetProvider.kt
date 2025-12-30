package com.virelon.spent_time_focus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.virelon.spent_time_focus.R

class UsageWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.usage_widget_layout).apply {
                val usageTime = widgetData.getString("usage_time", "0s 0dk") ?: "0s 0dk"
                setTextViewText(R.id.widget_usage_time, usageTime)
                
                val status = widgetData.getString("widget_status", "Spent: Odaklandın") ?: "Spent: Odaklandın"
                setTextViewText(R.id.widget_status, status)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
