package com.abik.vaidhya.pocket_hq.usage

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import java.util.Calendar
import java.util.concurrent.TimeUnit

object UsageStatsHelper {

    fun hasPermission(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun openUsageAccessSettings(context: Context) {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun getScreenTimeToday(context: Context): Map<String, Any> {
        if (!hasPermission(context)) {
            return mapOf("totalMs" to 0L, "formatted" to "0h 0m")
        }

        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val (start, end) = todayRange()
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
            ?: emptyList()

        var total = 0L
        for (s in stats) {
            total += s.totalTimeInForeground
        }

        return mapOf(
            "totalMs" to total,
            "formatted" to formatDuration(total)
        )
    }

    fun getAppUsageToday(context: Context): List<Map<String, Any>> {
        if (!hasPermission(context)) return emptyList()

        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val pm = context.packageManager
        val (start, end) = todayRange()
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
            ?: emptyList()

        val aggregated = mutableMapOf<String, Long>()
        for (s in stats) {
            if (s.totalTimeInForeground <= 0) continue
            aggregated[s.packageName] =
                (aggregated[s.packageName] ?: 0L) + s.totalTimeInForeground
        }

        return aggregated.entries
            .sortedByDescending { it.value }
            .map { (pkg, ms) ->
                mapOf(
                    "packageName" to pkg,
                    "appName" to resolveAppName(pm, pkg),
                    "totalTimeMs" to ms
                )
            }
    }

    private fun todayRange(): Pair<Long, Long> {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val start = cal.timeInMillis
        val end = System.currentTimeMillis()
        return start to end
    }

    private fun resolveAppName(pm: PackageManager, packageName: String): String {
        return try {
            val ai: ApplicationInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getApplicationInfo(packageName, PackageManager.ApplicationInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                pm.getApplicationInfo(packageName, 0)
            }
            pm.getApplicationLabel(ai).toString()
        } catch (_: Exception) {
            packageName.substringAfterLast('.')
        }
    }

    private fun formatDuration(ms: Long): String {
        val totalMin = TimeUnit.MILLISECONDS.toMinutes(ms)
        val h = totalMin / 60
        val m = totalMin % 60
        return if (h > 0) "${h}h ${m}m" else "${m}m"
    }
}
