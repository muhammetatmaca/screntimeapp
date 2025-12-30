package com.virelon.spent_time_focus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.virelon.spent_time_focus.R

class BatteryWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.battery_widget_layout).apply {
                val percentage = widgetData.getString("battery_percentage", "%100") ?: "%100"
                setTextViewText(R.id.widget_battery_text, percentage)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
