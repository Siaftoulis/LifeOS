package com.lifeos.app.lifeos_client

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.content.FileProvider
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.lifeos.app/ota_installer"

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
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
    }
}
