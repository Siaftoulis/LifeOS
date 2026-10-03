package com.lifeos.app.lifeos_client

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import androidx.core.content.FileProvider
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.lifeos.app.LifeOSWidgetProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.lifeos.app/ota_installer"
    private var pendingLaunchArgs: Map<String, Any>? = null
    private var pendingMediaAction: String? = null

    companion object {
        private const val MEDIA_CHANNEL = "com.lifeos.app/media_session"
        private var mediaMethodChannel: MethodChannel? = null
        private var activityInstance: MainActivity? = null

        fun dispatchMediaAction(action: String, context: Context? = null) {
            val inst = activityInstance
            val channel = mediaMethodChannel
            if (inst != null && channel != null) {
                inst.runOnUiThread {
                    channel.invokeMethod("onMediaAction", action)
                }
            } else if (context != null) {
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    this.action = "com.lifeos.app.ACTION_MEDIA_COMMAND"
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("media_action", action)
                }
                context.startActivity(launchIntent)
            }
        }

        fun dispatchSeekTo(positionMs: Long) {
            activityInstance?.runOnUiThread {
                mediaMethodChannel?.invokeMethod("onSeekTo", positionMs)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        activityInstance = this
        installSplashScreen()
        super.onCreate(savedInstanceState)
        hideSystemUI()
        handleLaunchIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleLaunchIntent(intent)
    }

    private fun handleLaunchIntent(intent: Intent?) {
        if (intent == null) return
        val mediaAction = intent.getStringExtra("media_action")
        if (mediaAction != null) {
            val channel = mediaMethodChannel
            if (channel != null) {
                activityInstance?.runOnUiThread {
                    channel.invokeMethod("onMediaAction", mediaAction)
                }
            } else {
                pendingMediaAction = mediaAction
            }
        }

        val targetTab = intent.getStringExtra("target_tab")
        val openNowPlaying = intent.getBooleanExtra("open_now_playing", false)
        if (targetTab != null || openNowPlaying) {
            val args = mapOf(
                "target_tab" to (targetTab ?: "music_player"),
                "open_now_playing" to openNowPlaying
            )
            pendingLaunchArgs = args
            val channel = mediaMethodChannel
            if (channel != null) {
                activityInstance?.runOnUiThread {
                    channel.invokeMethod("onWidgetLaunch", args)
                }
            }
        }
    }

    override fun onDestroy() {
        if (activityInstance == this) {
            activityInstance = null
            mediaMethodChannel = null
        }
        super.onDestroy()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            hideSystemUI()
        }
    }

    private fun hideSystemUI() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.let { controller ->
                controller.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                controller.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_FULLSCREEN
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        try {
                            val file = File(filePath)
                            if (!file.exists() || file.length() < 1000000) {
                                result.error("FILE_NOT_FOUND", "APK file not found or incomplete at $filePath", null)
                                return@setMethodCallHandler
                            }

                            // Check unknown app sources permission for Android 8.0+
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                if (!packageManager.canRequestPackageInstalls()) {
                                    val manageIntent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                        data = Uri.parse("package:$packageName")
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                    startActivity(manageIntent)
                                    result.error("PERMISSION_DENIED", "Install unknown apps permission required. Please allow and tap update again.", null)
                                    return@setMethodCallHandler
                                }
                            }

                            // Ensure file is readable by external package installer
                            file.setReadable(true, false)

                            val contentUri: Uri = FileProvider.getUriForFile(
                                applicationContext,
                                "${applicationContext.packageName}.fileprovider",
                                file
                            )

                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(contentUri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }

                            // Explicitly grant read/write permissions to all potential installer activities
                            val resInfoList = packageManager.queryIntentActivities(intent, 0)
                            for (resolveInfo in resInfoList) {
                                val pkgName = resolveInfo.activityInfo.packageName
                                grantUriPermission(pkgName, contentUri, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                            }

                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "filePath cannot be null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Media session channel for background notification banner & home screen widget
        val mediaChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CHANNEL)
        mediaMethodChannel = mediaChannel
        mediaChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updatePlaybackState" -> {
                    val title = call.argument<String>("title") ?: ""
                    val artist = call.argument<String>("artist") ?: ""
                    val album = call.argument<String>("album") ?: ""
                    val thumbnail = call.argument<String>("thumbnail") ?: ""
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    val positionMs = (call.argument<Number>("positionMs"))?.toLong() ?: 0L
                    val durationMs = (call.argument<Number>("durationMs"))?.toLong() ?: 0L
                    val isLiked = call.argument<Boolean>("isLiked") ?: false

                    MediaNotificationManager.showPlaybackNotification(
                        applicationContext,
                        title = title,
                        artist = artist,
                        album = album,
                        thumbnail = thumbnail,
                        isPlaying = isPlaying,
                        positionMs = positionMs,
                        durationMs = durationMs,
                        isLiked = isLiked
                    )
                    LifeOSWidgetProvider.updateWidget(
                        applicationContext,
                        title,
                        artist,
                        thumbnail,
                        isPlaying
                    )
                    result.success(true)
                }
                "getInitialWidgetLaunch" -> {
                    result.success(pendingLaunchArgs)
                    pendingLaunchArgs = null
                }
                "getInitialMediaAction" -> {
                    result.success(pendingMediaAction)
                    pendingMediaAction = null
                }
                "updateWidgetConfig" -> {
                    val showArtwork = call.argument<Boolean>("showArtwork") ?: true
                    val opacity = call.argument<Int>("opacity") ?: 90
                    val themeStyle = call.argument<String>("themeStyle") ?: "glass"
                    val targetTab = call.argument<String>("targetTab") ?: "music_player"
                    val widgetType = call.argument<String>("widgetType") ?: "standard"

                    LifeOSWidgetProvider.updateConfig(
                        applicationContext,
                        showArtwork,
                        opacity,
                        themeStyle,
                        targetTab,
                        widgetType
                    )
                    result.success(true)
                }
                "stopPlayback" -> {
                    MediaNotificationManager.cancelNotification(applicationContext)
                    LifeOSWidgetProvider.updateWidget(
                        applicationContext,
                        "",
                        "",
                        "",
                        false
                    )
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
