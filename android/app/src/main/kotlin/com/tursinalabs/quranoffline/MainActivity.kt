package com.tursinalabs.quranoffline

import android.content.Intent
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.tursinalabs.quranoffline/voice_settings",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openVoiceInputSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_VOICE_INPUT_SETTINGS))
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
