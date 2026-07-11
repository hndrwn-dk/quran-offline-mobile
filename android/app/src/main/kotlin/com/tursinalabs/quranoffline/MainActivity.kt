package com.tursinalabs.quranoffline

import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    companion object {
        private const val APP_CHECK_CHANNEL = "com.tursinalabs.quran_offline/app_check"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Native PackageManager query — Flutter cannot detect other apps' install state.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_CHECK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPackageInstalled" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName.isNullOrBlank()) {
                            result.success(false)
                        } else {
                            result.success(isPackageInstalled(packageName))
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }
}
