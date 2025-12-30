package com.virelon.spent_time_focus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.virelon.spent_time_focus.R

class ScrollWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.scroll_widget_layout).apply {
                val distance = widgetData.getString("scroll_distance", "0 m") ?: "0 m"
                setTextViewText(R.id.widget_scroll_value, distance)
                
                val comparison = widgetData.getString("scroll_comparison", "Henüz yolun başındasın") ?: "Henüz yolun başındasın"
                setTextViewText(R.id.widget_scroll_desc, comparison)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
