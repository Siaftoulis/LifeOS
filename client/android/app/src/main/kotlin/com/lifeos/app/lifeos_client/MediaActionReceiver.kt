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
                MainActivity.dispatchMediaAction("playPause")
            }
            LifeOSWidgetProvider.ACTION_NEXT -> {
                MainActivity.dispatchMediaAction("next")
            }
            LifeOSWidgetProvider.ACTION_PREV -> {
                MainActivity.dispatchMediaAction("previous")
            }
        }
    }
}
