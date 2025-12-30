package com.virelon.spent_time_focus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.virelon.spent_time_focus.R

class BillWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.bill_widget_layout).apply {
                setTextViewText(R.id.bill_item_1, widgetData.getString("bill_item_1", "Sosyal Medya: 2s") ?: "Sosyal Medya: 2s")
                setTextViewText(R.id.bill_total, widgetData.getString("bill_total", "TOPLAM: 4s 15dk") ?: "TOPLAM: 4s 15dk")
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
