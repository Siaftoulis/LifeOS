package com.lifeos.app.lifeos_client

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import com.lifeos.app.LifeOSWidgetProvider
import java.io.File
import java.net.URL
import kotlin.concurrent.thread

object MediaNotificationManager {
    private const val CHANNEL_ID = "lifeos_playback_channel"
    private const val NOTIFICATION_ID = 4040
    private var mediaSession: MediaSessionCompat? = null

    fun getOrCreateMediaSession(context: Context): MediaSessionCompat {
        if (mediaSession == null) {
            mediaSession = MediaSessionCompat(context.applicationContext, "LifeOSMediaSession").apply {
                setCallback(object : MediaSessionCompat.Callback() {
                    override fun onPlay() {
                        MainActivity.dispatchMediaAction("play")
                    }

                    override fun onPause() {
                        MainActivity.dispatchMediaAction("pause")
                    }

                    override fun onSkipToNext() {
                        MainActivity.dispatchMediaAction("next")
                    }

                    override fun onSkipToPrevious() {
                        MainActivity.dispatchMediaAction("previous")
                    }

                    override fun onSeekTo(pos: Long) {
                        MainActivity.dispatchSeekTo(pos)
                    }

                    override fun onCustomAction(action: String?, extras: Bundle?) {
                        if (action == "ACTION_LIKE") {
                            MainActivity.dispatchMediaAction("toggleLike")
                        }
                    }
                })
                setFlags(
                    MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS or
                    MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS
                )
                isActive = true
            }
        }
        return mediaSession!!
    }

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "LifeOS Music Playback"
            val descriptionText = "Persistent playback controls and media notifications"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun showPlaybackNotification(
        context: Context,
        title: String,
        artist: String,
        album: String = "",
        thumbnail: String = "",
        isPlaying: Boolean,
        positionMs: Long = 0L,
        durationMs: Long = 0L,
        isLiked: Boolean = false
    ) {
        if (title.isEmpty()) {
            cancelNotification(context)
            return
        }

        createNotificationChannel(context)
        val session = getOrCreateMediaSession(context)
        session.isActive = true

        // 1. Update PlaybackStateCompat on MediaSession (powers Android 13+ Quick Settings player)
        val playbackActions = PlaybackStateCompat.ACTION_PLAY or
            PlaybackStateCompat.ACTION_PAUSE or
            PlaybackStateCompat.ACTION_PLAY_PAUSE or
            PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
            PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
            PlaybackStateCompat.ACTION_SEEK_TO

        val stateBuilder = PlaybackStateCompat.Builder()
            .setActions(playbackActions)
            .setState(
                if (isPlaying) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED,
                positionMs,
                if (isPlaying) 1.0f else 0.0f
            )

        val likeIcon = if (isLiked) R.drawable.ic_heart_filled else R.drawable.ic_heart_outline
        val likeTitle = if (isLiked) "Unlike" else "Like"
        stateBuilder.addCustomAction(
            PlaybackStateCompat.CustomAction.Builder("ACTION_LIKE", likeTitle, likeIcon).build()
        )
        session.setPlaybackState(stateBuilder.build())

        // 2. Pending Intents
        val contentIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("target_tab", "music_player")
            putExtra("open_now_playing", true)
        }
        val pContent = PendingIntent.getActivity(
            context,
            10,
            contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val prevIntent = Intent(context, MediaActionReceiver::class.java).apply {
            action = LifeOSWidgetProvider.ACTION_PREV
        }
        val pPrev = PendingIntent.getBroadcast(
            context,
            11,
            prevIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val playPauseIntent = Intent(context, MediaActionReceiver::class.java).apply {
            action = LifeOSWidgetProvider.ACTION_PLAY_PAUSE
        }
        val pPlayPause = PendingIntent.getBroadcast(
            context,
            12,
            playPauseIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val nextIntent = Intent(context, MediaActionReceiver::class.java).apply {
            action = LifeOSWidgetProvider.ACTION_NEXT
        }
        val pNext = PendingIntent.getBroadcast(
            context,
            13,
            nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val likeIntent = Intent(context, MediaActionReceiver::class.java).apply {
            action = LifeOSWidgetProvider.ACTION_LIKE
        }
        val pLike = PendingIntent.getBroadcast(
            context,
            14,
            likeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val playPauseIcon = if (isPlaying) R.drawable.ic_music_pause else R.drawable.ic_music_play
        val playPauseBtnTitle = if (isPlaying) "Pause" else "Play"

        fun updateNotificationAndMetadata(largeIcon: Bitmap? = null) {
            // Update MediaMetadata on session so Android 13+ quick settings card shows title, artist, duration & blurred artwork
            val metaBuilder = MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, if (artist.isNotEmpty()) artist else "LifeOS Music")
                .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, album)
                .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, title)
                .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, artist)
                .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, durationMs)

            if (largeIcon != null) {
                metaBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, largeIcon)
                metaBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ART, largeIcon)
                metaBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON, largeIcon)
            }
            session.setMetadata(metaBuilder.build())

            val mediaStyle = androidx.media.app.NotificationCompat.MediaStyle()
                .setMediaSession(session.sessionToken)
                .setShowActionsInCompactView(0, 1, 2)

            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_music_play)
                .setContentTitle(title)
                .setContentText(if (artist.isNotEmpty()) artist else "LifeOS Music")
                .setSubText(album.ifEmpty { "LifeOS" })
                .setContentIntent(pContent)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOnlyAlertOnce(true)
                .setOngoing(isPlaying)
                .addAction(R.drawable.ic_music_prev, "Previous", pPrev)
                .addAction(playPauseIcon, playPauseBtnTitle, pPlayPause)
                .addAction(R.drawable.ic_music_next, "Next", pNext)
                .addAction(likeIcon, likeTitle, pLike)
                .setStyle(mediaStyle)

            if (largeIcon != null) {
                builder.setLargeIcon(largeIcon)
            }

            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            try {
                notificationManager.notify(NOTIFICATION_ID, builder.build())
            } catch (e: Throwable) {
                android.util.Log.w("MediaNotificationMgr", "Failed to post media notification: ${e.message}")
            }
        }

        // Post immediately
        updateNotificationAndMetadata(null)

        // Load thumbnail asynchronously
        if (thumbnail.isNotEmpty()) {
            thread {
                try {
                    val clean = thumbnail.removePrefix("file://")
                    val bmp = if (thumbnail.startsWith("http://") || thumbnail.startsWith("https://")) {
                        BitmapFactory.decodeStream(URL(thumbnail).openStream())
                    } else if (File(clean).exists()) {
                        BitmapFactory.decodeFile(clean)
                    } else null

                    if (bmp != null) {
                        updateNotificationAndMetadata(bmp)
                    }
                } catch (_: Exception) {}
            }
        }
    }

    fun cancelNotification(context: Context) {
        mediaSession?.let {
            val state = PlaybackStateCompat.Builder()
                .setState(PlaybackStateCompat.STATE_STOPPED, 0L, 0.0f)
                .build()
            it.setPlaybackState(state)
            it.isActive = false
        }
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(NOTIFICATION_ID)
    }
}
