package com.lifeos.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.lifeos.app.R


class LifeOSWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // Decouple data stream: Intercept background JSON sync from Flutter
        if (intent.action == "com.lifeos.app.UPDATE_WIDGET") {
            val payload = intent.getStringExtra("metrics_json") ?: ""
            val prefs = context.getSharedPreferences("LifeOSPrefs", Context.MODE_PRIVATE)
            prefs.edit().putString("latest_metrics", payload).apply()
            
            // Note: A real implementation would query ComponentName to acquire widgetIds here 
            // and manually trigger the AppWidgetManager.updateAppWidget loop.
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        // Read directly from SharedPreferences. Ensures the widget renders instantly 
        // even if the heavy Flutter engine process is fully suspended by the Android OS.
        val prefs = context.getSharedPreferences("LifeOSPrefs", Context.MODE_PRIVATE)
        val data = prefs.getString("latest_metrics", "No data synced yet")
        
        for (appWidgetId in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            views.setTextViewText(R.id.widget_content, data)
            manager.updateAppWidget(appWidgetId, views)
        }
    }
}
