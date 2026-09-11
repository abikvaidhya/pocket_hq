package com.abik.vaidhya.pocket_hq

import com.abik.vaidhya.pocket_hq.usage.UsageStatsHelper
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.pockethq/native"
    private val EVENTS = "com.pockethq/events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getTodayEvents" -> {
                        result.success(emptyList<Map<String, Any>>())
                    }
                    "hasUsagePermission" -> {
                        result.success(UsageStatsHelper.hasPermission(this))
                    }
                    "openUsageAccessSettings" -> {
                        UsageStatsHelper.openUsageAccessSettings(this)
                        result.success(null)
                    }
                    "getScreenTimeToday" -> {
                        result.success(UsageStatsHelper.getScreenTimeToday(this))
                    }
                    "getAppUsageToday" -> {
                        result.success(UsageStatsHelper.getAppUsageToday(this))
                    }
                    "authenticate" -> {
                        result.success(false)
                    }
                    "canAuthenticate" -> {
                        result.success(false)
                    }
                    "scheduleDailyDigest" -> {
                        result.success(null)
                    }
                    "cancelDailyDigest" -> {
                        result.success(null)
                    }
                    "updateHomeWidget" -> {
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {}
                override fun onCancel(arguments: Any?) {}
            })
    }
}
