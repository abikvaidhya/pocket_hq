package com.abik.vaidhya.pocket_hq

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
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
import com.abik.vaidhya.pocket_hq.widgets.PocketHQWidgetProvider
import com.abik.vaidhya.pocket_hq.widgets.WidgetDataStore
import com.abik.vaidhya.pocket_hq.workers.DailyDigestWorker

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.abik.vaidhya.pocket_hq/native"
    private val EVENTS = "com.abik.vaidhya.pocket_hq/events"
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        captureDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureDeepLink(intent)
        methodChannel?.invokeMethod(
            "onDeepLink",
            mapOf(
                "route" to pendingRoute,
                "noteId" to pendingNoteId
            )
        )
    }

    private fun captureDeepLink(intent: Intent?) {
        if (intent == null) return
        pendingRoute = intent.getStringExtra("route")
        pendingNoteId = intent.getStringExtra("noteId")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getTodayEvents" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        val events = CalendarHelper.getTodayEvents(this@MainActivity)
                        Handler(Looper.getMainLooper()).post {
                            result.success(events)
                        }
                    }
                }
                "hasUsagePermission" -> {
                    result.success(UsageStatsHelper.hasPermission(this))
                }
                "openUsageAccessSettings" -> {
                    UsageStatsHelper.openUsageAccessSettings(this)
                    result.success(null)
                }
                "getScreenTimeToday" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        val summary = UsageStatsHelper.getScreenTimeToday(this@MainActivity)
                        Handler(Looper.getMainLooper()).post {
                            result.success(summary)
                        }
                    }
                }
                "getAppUsageToday" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        val apps = UsageStatsHelper.getAppUsageToday(this@MainActivity)
                        Handler(Looper.getMainLooper()).post {
                            result.success(apps)
                        }
                    }
                }
                "authenticate" -> result.success(false)
                "canAuthenticate" -> result.success(false)
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
                    WidgetDataStore.saveFromFlutter(
                        this,
                        data["notesJson"] as? String,
                        data["habitsJson"] as? String,
                        data["appsJson"] as? String,
                        data["screenTotal"] as? String,
                        data["cartJson"] as? String
                    )
                    // Keep legacy keys for any old UI
                    getSharedPreferences(WidgetDataStore.PREFS, Context.MODE_PRIVATE)
                        .edit()
                        .putString("title", data["title"] as? String ?: "Pocket HQ")
                        .putString("subtitle", data["subtitle"] as? String ?: "")
                        .apply()
                    try {
                        PocketHQWidgetProvider.refreshAll(this)
                    } catch (_: Exception) {
                    }
                    result.success(null)
                }
                "drainWidgetHabitCompletions" -> {
                    result.success(WidgetDataStore.drainCompletedHabitIds(this))
                }
                "getPendingDeepLink" -> {
                    val map = mapOf(
                        "route" to pendingRoute,
                        "noteId" to pendingNoteId
                    )
                    pendingRoute = null
                    pendingNoteId = null
                    result.success(map)
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

    companion object {
        @JvmStatic var pendingRoute: String? = null
        @JvmStatic var pendingNoteId: String? = null
    }
}
