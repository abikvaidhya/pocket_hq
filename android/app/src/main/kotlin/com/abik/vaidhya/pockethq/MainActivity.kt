package com.abik.vaidhya.pocket_hq

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.pockethq/native"
    private val EVENTS = "com.pockethq/events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getTodayEvents" -> {
                        // TODO: CalendarContract query
                        result.success(emptyList<Map<String, Any>>())
                    }
                    "getScreenTimeToday" -> {
                        // TODO: UsageStatsManager
                        result.success(mapOf(
                            "totalMs" to 0L,
                            "formatted" to "0h 0m"
                        ))
                    }
                    "getAppUsageToday" -> {
                        result.success(emptyList<Map<String, Any>>())
                    }
                    "authenticate" -> {
                        // TODO: BiometricPrompt
                        result.success(false)
                    }
                    "canAuthenticate" -> {
                        result.success(false)
                    }
                    "scheduleDailyDigest" -> {
                        val hour = call.argument<Int>("hour") ?: 8
                        val minute = call.argument<Int>("minute") ?: 0
                        // TODO: WorkManager
                        result.success(null)
                    }
                    "cancelDailyDigest" -> {
                        result.success(null)
                    }
                    "updateHomeWidget" -> {
                        // TODO: GlanceAppWidgetManager
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    // Optional: push events to Flutter
                }
                override fun onCancel(arguments: Any?) {}
            })
    }
}
