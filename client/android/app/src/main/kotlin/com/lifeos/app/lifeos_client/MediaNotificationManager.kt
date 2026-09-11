package com.lifeos.app.lifeos_client

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.lifeos.app.LifeOSWidgetProvider

object MediaNotificationManager {
    private const val CHANNEL_ID = "lifeos_playback_channel"
    private const val NOTIFICATION_ID = 4040

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
        isPlaying: Boolean
    ) {
        if (title.isEmpty()) {
            cancelNotification(context)
            return
        }

        createNotificationChannel(context)

        // Tapping the notification brings the app / music player to the foreground
        val contentIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pContent = PendingIntent.getActivity(
            context,
            10,
            contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Previous Action
        val prevIntent = Intent(context, MediaActionReceiver::class.java).apply {
            action = LifeOSWidgetProvider.ACTION_PREV
        }
        val pPrev = PendingIntent.getBroadcast(
            context,
            11,
            prevIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Play/Pause Action
        val playPauseIntent = Intent(context, MediaActionReceiver::class.java).apply {
            action = LifeOSWidgetProvider.ACTION_PLAY_PAUSE
        }
        val pPlayPause = PendingIntent.getBroadcast(
            context,
            12,
            playPauseIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Next Action
        val nextIntent = Intent(context, MediaActionReceiver::class.java).apply {
            action = LifeOSWidgetProvider.ACTION_NEXT
        }
        val pNext = PendingIntent.getBroadcast(
            context,
            13,
            nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val playPauseIcon = if (isPlaying) R.drawable.ic_music_pause else R.drawable.ic_music_play
        val playPauseTitle = if (isPlaying) "Pause" else "Play"

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_music_play)
            .setContentTitle(title)
            .setContentText(if (artist.isNotEmpty()) artist else "LifeOS Music")
            .setContentIntent(pContent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOnlyAlertOnce(true)
            .setOngoing(isPlaying)
            .addAction(R.drawable.ic_music_prev, "Previous", pPrev)
            .addAction(playPauseIcon, playPauseTitle, pPlayPause)
            .addAction(R.drawable.ic_music_next, "Next", pNext)
            .setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setShowActionsInCompactView(0, 1, 2)
            )

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        try {
            notificationManager.notify(NOTIFICATION_ID, builder.build())
        } catch (e: Throwable) {
            android.util.Log.w("MediaNotificationMgr", "Failed to post media notification: ${e.message}")
        }
    }

    fun cancelNotification(context: Context) {
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(NOTIFICATION_ID)
    }
}
