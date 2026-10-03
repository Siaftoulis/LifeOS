package com.lifeos.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.RectF
import android.view.View
import android.widget.RemoteViews
import com.lifeos.app.lifeos_client.MainActivity
import com.lifeos.app.lifeos_client.MediaActionReceiver
import com.lifeos.app.lifeos_client.R
import java.io.File
import java.net.URL

class LifeOSWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_UPDATE_WIDGET -> {
                val title = intent.getStringExtra("track_title") ?: ""
                val artist = intent.getStringExtra("track_artist") ?: ""
                val thumbnail = intent.getStringExtra("thumbnail_url") ?: ""
                val isPlaying = intent.getBooleanExtra("is_playing", false)
                updateWidget(context, title, artist, thumbnail, isPlaying)
            }
            ACTION_CONFIG_CHANGED -> {
                refreshAllWidgets(context)
            }
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val title = prefs.getString(KEY_TRACK_TITLE, "No track playing") ?: "No track playing"
        val artist = prefs.getString(KEY_TRACK_ARTIST, "Tap to open LifeOS") ?: "Tap to open LifeOS"
        val thumbnail = prefs.getString(KEY_THUMBNAIL_URL, "") ?: ""
        val isPlaying = prefs.getBoolean(KEY_IS_PLAYING, false)

        for (appWidgetId in ids) {
            renderWidget(context, manager, appWidgetId, title, artist, thumbnail, isPlaying)
        }
    }

    companion object {
        const val ACTION_PLAY_PAUSE = "com.lifeos.app.ACTION_PLAY_PAUSE"
        const val ACTION_NEXT = "com.lifeos.app.ACTION_NEXT"
        const val ACTION_PREV = "com.lifeos.app.ACTION_PREV"
        const val ACTION_LIKE = "com.lifeos.app.ACTION_LIKE"
        const val ACTION_UPDATE_WIDGET = "com.lifeos.app.UPDATE_WIDGET"
        const val ACTION_CONFIG_CHANGED = "com.lifeos.app.CONFIG_CHANGED"

        const val PREFS_NAME = "LifeOSWidgetPrefs"
        const val KEY_TRACK_TITLE = "track_title"
        const val KEY_TRACK_ARTIST = "track_artist"
        const val KEY_THUMBNAIL_URL = "thumbnail_url"
        const val KEY_IS_PLAYING = "is_playing"
        const val KEY_SHOW_ARTWORK = "show_artwork"
        const val KEY_BG_OPACITY = "bg_opacity"
        const val KEY_THEME_STYLE = "theme_style"
        const val KEY_TARGET_TAB = "target_tab"
        const val KEY_WIDGET_TYPE = "widget_type"
        const val ACTION_OPEN_TAB = "com.lifeos.app.ACTION_OPEN_TAB"

        fun updateWidget(
            context: Context,
            title: String,
            artist: String,
            thumbnail: String,
            isPlaying: Boolean
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putString(KEY_TRACK_TITLE, title)
                .putString(KEY_TRACK_ARTIST, artist)
                .putString(KEY_THUMBNAIL_URL, thumbnail)
                .putBoolean(KEY_IS_PLAYING, isPlaying)
                .apply()

            val manager = AppWidgetManager.getInstance(context) ?: return
            val componentName = ComponentName(context, LifeOSWidgetProvider::class.java)
            val appWidgetIds = manager.getAppWidgetIds(componentName)
            if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                for (widgetId in appWidgetIds) {
                    renderWidget(context, manager, widgetId, title, artist, thumbnail, isPlaying)
                }
            }
        }

        fun updateConfig(
            context: Context,
            showArtwork: Boolean,
            opacity: Int,
            themeStyle: String,
            targetTab: String = "music_player",
            widgetType: String = "standard"
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putBoolean(KEY_SHOW_ARTWORK, showArtwork)
                .putInt(KEY_BG_OPACITY, opacity.coerceIn(0, 100))
                .putString(KEY_THEME_STYLE, themeStyle)
                .putString(KEY_TARGET_TAB, targetTab)
                .putString(KEY_WIDGET_TYPE, widgetType)
                .apply()

            refreshAllWidgets(context)
        }

        fun refreshAllWidgets(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val title = prefs.getString(KEY_TRACK_TITLE, "No track playing") ?: "No track playing"
            val artist = prefs.getString(KEY_TRACK_ARTIST, "Tap to open LifeOS") ?: "Tap to open LifeOS"
            val thumbnail = prefs.getString(KEY_THUMBNAIL_URL, "") ?: ""
            val isPlaying = prefs.getBoolean(KEY_IS_PLAYING, false)

            val manager = AppWidgetManager.getInstance(context) ?: return
            val componentName = ComponentName(context, LifeOSWidgetProvider::class.java)
            val appWidgetIds = manager.getAppWidgetIds(componentName)
            if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                for (widgetId in appWidgetIds) {
                    renderWidget(context, manager, widgetId, title, artist, thumbnail, isPlaying)
                }
            }
        }

        fun renderWidget(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int,
            title: String,
            artist: String,
            thumbnail: String,
            isPlaying: Boolean
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val showArtwork = prefs.getBoolean(KEY_SHOW_ARTWORK, true)
            val opacity = prefs.getInt(KEY_BG_OPACITY, 90).coerceIn(0, 100)
            val targetTab = prefs.getString(KEY_TARGET_TAB, "music_player") ?: "music_player"
            val widgetType = prefs.getString(KEY_WIDGET_TYPE, "standard") ?: "standard"
            val themeStyle = prefs.getString(KEY_THEME_STYLE, "glass") ?: "glass"

            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            // Preserve rounded corners & borders with themed drawables
            val bgRes = when (themeStyle) {
                "oled" -> R.drawable.widget_background_oled
                "accent" -> R.drawable.widget_background_accent
                "border" -> R.drawable.widget_background_border
                else -> R.drawable.widget_background_glass
            }
            views.setInt(R.id.widget_root, "setBackgroundResource", bgRes)

            val displayTitle = if (title.isNotEmpty()) title else "No track playing"
            val displayArtist = if (artist.isNotEmpty()) artist else "Tap to open LifeOS"
            views.setTextViewText(R.id.widget_track_title, displayTitle)
            views.setTextViewText(R.id.widget_track_artist, displayArtist)

            // Compact vs standard controls visibility
            if (widgetType == "compact") {
                views.setViewVisibility(R.id.widget_btn_prev, View.GONE)
                views.setViewVisibility(R.id.widget_btn_next, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_btn_prev, View.VISIBLE)
                views.setViewVisibility(R.id.widget_btn_next, View.VISIBLE)
            }

            val playPauseIcon = if (isPlaying) R.drawable.ic_music_pause else R.drawable.ic_music_play
            views.setImageViewResource(R.id.widget_btn_play_pause, playPauseIcon)

            // Tap root / info -> opens MainActivity with deep link into configured tab & Now Playing
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                action = ACTION_OPEN_TAB
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("target_tab", targetTab)
                putExtra("open_now_playing", targetTab == "music_player")
                data = android.net.Uri.parse("lifeos://tab/$targetTab")
            }
            val pLaunch = PendingIntent.getActivity(
                context,
                widgetId,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pLaunch)
            views.setOnClickPendingIntent(R.id.widget_info_container, pLaunch)

            // Previous button PendingIntent
            val prevIntent = Intent(context, MediaActionReceiver::class.java).apply {
                action = ACTION_PREV
            }
            val pPrev = PendingIntent.getBroadcast(
                context,
                100 + widgetId,
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
                200 + widgetId,
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
                300 + widgetId,
                nextIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_next, pNext)

            // Initial synchronous update for instant text & control feedback
            if (!showArtwork) {
                views.setViewVisibility(R.id.widget_album_art, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_album_art, View.VISIBLE)
                views.setImageViewResource(R.id.widget_album_art, R.drawable.ic_music_play)
            }
            manager.updateAppWidget(widgetId, views)

            // Asynchronous album artwork decoding with downsampling (Binder limit safe)
            if (showArtwork && thumbnail.isNotEmpty()) {
                Thread {
                    try {
                        val bmp = decodeAndScaleBitmap(context, thumbnail, 256)
                        if (bmp != null) {
                            val rounded = getRoundedCornerBitmap(bmp, 16)
                            views.setImageViewBitmap(R.id.widget_album_art, rounded)
                        } else {
                            views.setImageViewResource(R.id.widget_album_art, R.drawable.ic_music_play)
                        }
                        manager.updateAppWidget(widgetId, views)
                    } catch (_: Exception) {
                        views.setImageViewResource(R.id.widget_album_art, R.drawable.ic_music_play)
                        manager.updateAppWidget(widgetId, views)
                    }
                }.start()
            }
        }

        fun decodeAndScaleBitmap(context: Context, thumbnail: String, maxDim: Int = 256): Bitmap? {
            try {
                val cleanPath = thumbnail.removePrefix("file://")
                val lower = cleanPath.lowercase()
                var rawBmp: Bitmap? = null

                if (thumbnail.startsWith("http://") || thumbnail.startsWith("https://")) {
                    val url = URL(thumbnail)
                    val conn = url.openConnection()
                    conn.connectTimeout = 4000
                    conn.readTimeout = 4000
                    conn.getInputStream().use { stream ->
                        rawBmp = BitmapFactory.decodeStream(stream)
                    }
                } else if (File(cleanPath).exists()) {
                    if (lower.endsWith(".mp3") || lower.endsWith(".m4a") || lower.endsWith(".flac") || lower.endsWith(".wav") || lower.endsWith(".ogg") || lower.endsWith(".opus") || lower.endsWith(".aac")) {
                        try {
                            val mmr = android.media.MediaMetadataRetriever()
                            mmr.setDataSource(cleanPath)
                            val art = mmr.embeddedPicture
                            mmr.release()
                            if (art != null && art.isNotEmpty()) {
                                rawBmp = BitmapFactory.decodeByteArray(art, 0, art.size)
                            }
                        } catch (_: Exception) {}
                    } else {
                        rawBmp = BitmapFactory.decodeFile(cleanPath)
                    }
                } else if (thumbnail.startsWith("phone_")) {
                    val songId = thumbnail.removePrefix("phone_").toLongOrNull()
                    if (songId != null) {
                        try {
                            val uri = android.content.ContentUris.withAppendedId(
                                android.net.Uri.parse("content://media/external/audio/media"),
                                songId
                            )
                            val pfd = context.contentResolver.openFileDescriptor(uri, "r")
                            if (pfd != null) {
                                val mmr = android.media.MediaMetadataRetriever()
                                mmr.setDataSource(pfd.fileDescriptor)
                                val art = mmr.embeddedPicture
                                mmr.release()
                                pfd.close()
                                if (art != null && art.isNotEmpty()) {
                                    rawBmp = BitmapFactory.decodeByteArray(art, 0, art.size)
                                }
                            }
                        } catch (_: Exception) {}
                    }
                }

                if (rawBmp == null) return null

                val w = rawBmp!!.width
                val h = rawBmp!!.height
                return if (w > maxDim || h > maxDim) {
                    val scale = maxDim.toFloat() / maxOf(w, h)
                    val sw = (w * scale).toInt().coerceAtLeast(1)
                    val sh = (h * scale).toInt().coerceAtLeast(1)
                    val scaled = Bitmap.createScaledBitmap(rawBmp!!, sw, sh, true)
                    if (scaled != rawBmp) rawBmp!!.recycle()
                    scaled
                } else {
                    rawBmp
                }
            } catch (_: Exception) {
                return null
            }
        }

        private fun getRoundedCornerBitmap(bitmap: Bitmap, cornerRadius: Int): Bitmap {
            val output = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(output)
            val paint = Paint()
            val rect = Rect(0, 0, bitmap.width, bitmap.height)
            val rectF = RectF(rect)

            paint.isAntiAlias = true
            canvas.drawARGB(0, 0, 0, 0)
            paint.color = Color.BLACK
            canvas.drawRoundRect(rectF, cornerRadius.toFloat(), cornerRadius.toFloat(), paint)

            paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
            canvas.drawBitmap(bitmap, rect, rect, paint)

            return output
        }
    }
}
