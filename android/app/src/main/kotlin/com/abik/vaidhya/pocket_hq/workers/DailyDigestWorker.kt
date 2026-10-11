package com.abik.vaidhya.pocket_hq.workers

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

class DailyDigestWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val prefs = applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val habitsPending = prefs.getInt("habits_pending", 0)
        val notesCount = prefs.getInt("notes_count", 0)
        val tripsToday = prefs.getInt("trips_today", 0)
        val summary = prefs.getString("digest_summary", null)
            ?: buildString {
                append("Habits left: $habitsPending")
                if (notesCount > 0) append(" · Notes: $notesCount")
                if (tripsToday > 0) append(" · Trips today: $tripsToday")
            }

        showNotification(
            title = "Pocket HQ · Daily digest",
            body = summary
        )
        return Result.success()
    }

    private fun showNotification(title: String, body: String) {
        val nm = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Daily Digest",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Daily summary of tasks and habits"
                }
            )
        }
        val notification = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_today)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .build()
        nm.notify(NOTIFICATION_ID, notification)
    }

    companion object {
        const val UNIQUE_WORK = "pocket_hq_daily_digest"
        const val PREFS = "pocket_hq_digest"
        private const val CHANNEL_ID = "pocket_hq_digest"
        private const val NOTIFICATION_ID = 7101

        fun schedule(context: Context, hour: Int, minute: Int) {
            // Approximate daily cadence; exact time via flex is limited on PeriodicWork
            val request = PeriodicWorkRequestBuilder<DailyDigestWorker>(24, TimeUnit.HOURS)
                .addTag(UNIQUE_WORK)
                .build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                UNIQUE_WORK,
                ExistingPeriodicWorkPolicy.UPDATE,
                request
            )

            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putInt("digest_hour", hour)
                .putInt("digest_minute", minute)
                .apply()
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(UNIQUE_WORK)
        }

        fun updateDigestData(
            context: Context,
            habitsPending: Int,
            notesCount: Int,
            tripsToday: Int,
            summary: String
        ) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putInt("habits_pending", habitsPending)
                .putInt("notes_count", notesCount)
                .putInt("trips_today", tripsToday)
                .putString("digest_summary", summary)
                .apply()
        }
    }
}
