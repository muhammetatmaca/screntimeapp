package com.virelon.spent_time_focus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.virelon.spent_time_focus.R

class DetoxWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.detox_widget_layout).apply {
                setTextViewText(R.id.detox_status, widgetData.getString("detox_status", "AKTİF") ?: "AKTİF")
                setTextViewText(R.id.detox_desc, widgetData.getString("detox_desc", "Detoks zamanı") ?: "Detoks zamanı")
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
