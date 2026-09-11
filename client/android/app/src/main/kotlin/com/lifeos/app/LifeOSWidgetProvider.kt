package com.lifeos.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.lifeos.app.lifeos_client.MainActivity
import com.lifeos.app.lifeos_client.MediaActionReceiver
import com.lifeos.app.lifeos_client.R

class LifeOSWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_UPDATE_WIDGET) {
            val title = intent.getStringExtra("track_title") ?: ""
            val artist = intent.getStringExtra("track_artist") ?: ""
            val isPlaying = intent.getBooleanExtra("is_playing", false)
            updateWidget(context, title, artist, isPlaying)
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val title = prefs.getString(KEY_TRACK_TITLE, "No track playing") ?: "No track playing"
        val artist = prefs.getString(KEY_TRACK_ARTIST, "Tap to open LifeOS") ?: "Tap to open LifeOS"
        val isPlaying = prefs.getBoolean(KEY_IS_PLAYING, false)

        for (appWidgetId in ids) {
            renderWidget(context, manager, appWidgetId, title, artist, isPlaying)
        }
    }

    companion object {
        const val ACTION_PLAY_PAUSE = "com.lifeos.app.ACTION_PLAY_PAUSE"
        const val ACTION_NEXT = "com.lifeos.app.ACTION_NEXT"
        const val ACTION_PREV = "com.lifeos.app.ACTION_PREV"
        const val ACTION_UPDATE_WIDGET = "com.lifeos.app.UPDATE_WIDGET"
        const val PREFS_NAME = "LifeOSWidgetPrefs"
        const val KEY_TRACK_TITLE = "track_title"
        const val KEY_TRACK_ARTIST = "track_artist"
        const val KEY_IS_PLAYING = "is_playing"

        fun updateWidget(context: Context, title: String, artist: String, isPlaying: Boolean) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putString(KEY_TRACK_TITLE, title)
                .putString(KEY_TRACK_ARTIST, artist)
                .putBoolean(KEY_IS_PLAYING, isPlaying)
                .apply()

            val manager = AppWidgetManager.getInstance(context) ?: return
            val componentName = ComponentName(context, LifeOSWidgetProvider::class.java)
            val appWidgetIds = manager.getAppWidgetIds(componentName)
            if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                for (widgetId in appWidgetIds) {
                    renderWidget(context, manager, widgetId, title, artist, isPlaying)
                }
            }
        }

        fun renderWidget(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int,
            title: String,
            artist: String,
            isPlaying: Boolean
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val displayTitle = if (title.isNotEmpty()) title else "No track playing"
            val displayArtist = if (artist.isNotEmpty()) artist else "Tap to open LifeOS"
            views.setTextViewText(R.id.widget_track_title, displayTitle)
            views.setTextViewText(R.id.widget_track_artist, displayArtist)

            val playPauseIcon = if (isPlaying) R.drawable.ic_music_pause else R.drawable.ic_music_play
            views.setImageViewResource(R.id.widget_btn_play_pause, playPauseIcon)

            // Tap root / info -> opens MainActivity
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pLaunch = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pLaunch)

            // Previous button PendingIntent
            val prevIntent = Intent(context, MediaActionReceiver::class.java).apply {
                action = ACTION_PREV
            }
            val pPrev = PendingIntent.getBroadcast(
                context,
                1,
                prevIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_prev, pPrev)

            // Play/Pause button PendingIntent
            val playPauseIntent = Intent(context, MediaActionReceiver::class.java).apply {
                action = ACTION_PLAY_PAUSE
            }
            val pPlayPause = PendingIntent.getBroadcast(
                context,
                2,
                playPauseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_play_pause, pPlayPause)

            // Next button PendingIntent
            val nextIntent = Intent(context, MediaActionReceiver::class.java).apply {
                action = ACTION_NEXT
            }
            val pNext = PendingIntent.getBroadcast(
                context,
                3,
                nextIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_next, pNext)

            manager.updateAppWidget(widgetId, views)
        }
    }
}
