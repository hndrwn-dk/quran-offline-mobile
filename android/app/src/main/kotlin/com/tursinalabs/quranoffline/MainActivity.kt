package com.tursinalabs.quranoffline

import android.content.Intent
import android.content.pm.PackageManager
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    companion object {
        private const val APP_CHECK_CHANNEL = "com.tursinalabs.quran_offline/app_check"
        private const val PLAY_INTEGRITY_CHANNEL = "com.tursinalabs.quran_offline/play_integrity"
        private const val PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER = 975063804069L
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
                    "launchPackage" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName.isNullOrBlank()) {
                            result.success(false)
                        } else {
                            result.success(launchPackage(packageName))
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLAY_INTEGRITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestToken" -> {
                        val nonce = call.argument<String>("nonce")
                        if (nonce.isNullOrBlank()) {
                            result.error("invalid_nonce", "nonce is required", null)
                        } else {
                            requestPlayIntegrityToken(nonce, result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestPlayIntegrityToken(nonce: String, result: MethodChannel.Result) {
        val request = IntegrityTokenRequest.builder()
            .setNonce(nonce)
            .setCloudProjectNumber(PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER)
            .build()
        IntegrityManagerFactory.create(applicationContext)
            .requestIntegrityToken(request)
            .addOnSuccessListener { response ->
                result.success(response.token())
            }
            .addOnFailureListener { error ->
                result.error("integrity_failed", error.message, null)
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

    /** Opens the app's launcher activity; more reliable than custom-scheme deep links. */
    private fun launchPackage(packageName: String): Boolean {
        return try {
            val intent = packageManager.getLaunchIntentForPackage(packageName) ?: return false
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}
