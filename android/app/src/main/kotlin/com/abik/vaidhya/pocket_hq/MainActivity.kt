package com.abik.vaidhya.pocket_hq

import android.content.Context
import androidx.glance.appwidget.updateAll
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import com.abik.vaidhya.pocket_hq.calendar.CalendarHelper
import com.abik.vaidhya.pocket_hq.usage.UsageStatsHelper
import com.abik.vaidhya.pocket_hq.widgets.TodayGlanceWidget
import com.abik.vaidhya.pocket_hq.workers.DailyDigestWorker

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.abik.vaidhya.pocket_hq/native"
    private val EVENTS = "com.abik.vaidhya.pocket_hq/events"

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
                        val hour = call.argument<Int>("hour") ?: 8
                        val minute = call.argument<Int>("minute") ?: 0
                        DailyDigestWorker.schedule(this, hour, minute)
                        result.success(null)
                    }

                    "cancelDailyDigest" -> {
                        DailyDigestWorker.cancel(this)
                        result.success(null)
                    }

                    "updateDigestData" -> {
                        val habitsPending = call.argument<Int>("habitsPending") ?: 0
                        val notesCount = call.argument<Int>("notesCount") ?: 0
                        val tripsToday = call.argument<Int>("tripsToday") ?: 0
                        val summary = call.argument<String>("summary") ?: ""
                        DailyDigestWorker.updateDigestData(
                            this, habitsPending, notesCount, tripsToday, summary
                        )
                        result.success(null)
                    }

                    "updateHomeWidget" -> {
                        val data = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                        val prefs = getSharedPreferences("pocket_hq_widget", Context.MODE_PRIVATE)
                        prefs.edit()
                            .putString("title", data["title"] as? String ?: "Pocket HQ")
                            .putString("subtitle", data["subtitle"] as? String ?: "")
                            .putString("habits", data["habits"] as? String ?: "—")
                            .putString("screen", data["screen"] as? String ?: "—")
                            .apply()
                        CoroutineScope(Dispatchers.Main).launch {
                            try {
                                TodayGlanceWidget().updateAll(this@MainActivity)
                            } catch (_: Exception) {
                            }
                        }
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
