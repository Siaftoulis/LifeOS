package com.lifeos.app.lifeos_client

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.lifeos.app.LifeOSWidgetProvider

class MediaActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        when (action) {
            LifeOSWidgetProvider.ACTION_PLAY_PAUSE -> {
                val prefs = context.getSharedPreferences(LifeOSWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
                val currentPlaying = prefs.getBoolean(LifeOSWidgetProvider.KEY_IS_PLAYING, false)
                prefs.edit().putBoolean(LifeOSWidgetProvider.KEY_IS_PLAYING, !currentPlaying).apply()
                LifeOSWidgetProvider.refreshAllWidgets(context)

                MainActivity.dispatchMediaAction("playPause", context)
            }
            LifeOSWidgetProvider.ACTION_NEXT -> {
                MainActivity.dispatchMediaAction("next", context)
            }
            LifeOSWidgetProvider.ACTION_PREV -> {
                MainActivity.dispatchMediaAction("previous", context)
            }
            LifeOSWidgetProvider.ACTION_LIKE -> {
                MainActivity.dispatchMediaAction("toggleLike", context)
            }
        }
    }
}
