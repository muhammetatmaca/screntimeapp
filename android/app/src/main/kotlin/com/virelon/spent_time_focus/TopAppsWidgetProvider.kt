package com.virelon.spent_time_focus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.virelon.spent_time_focus.R

class TopAppsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.top_apps_widget_layout).apply {
                setTextViewText(R.id.top_app_1, widgetData.getString("top_app_1", "1. Boş") ?: "1. Boş")
                setTextViewText(R.id.top_app_2, widgetData.getString("top_app_2", "2. Boş") ?: "2. Boş")
                setTextViewText(R.id.top_app_3, widgetData.getString("top_app_3", "3. Boş") ?: "3. Boş")
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
