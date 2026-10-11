package com.abik.vaidhya.pocket_hq.calendar

import android.content.ContentUris
import android.content.Context
import android.provider.CalendarContract
import java.util.Calendar
import java.util.TimeZone

object CalendarHelper {

    fun getTodayEvents(context: Context): List<Map<String, Any?>> {
        val cr = context.contentResolver
        val start = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val end = start + 24L * 60 * 60 * 1000

        val projection = arrayOf(
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.EVENT_LOCATION,
            CalendarContract.Instances.ALL_DAY,
            CalendarContract.Instances.CALENDAR_DISPLAY_NAME
        )

        val uri = CalendarContract.Instances.CONTENT_URI.buildUpon().let { builder ->
            ContentUris.appendId(builder, start)
            ContentUris.appendId(builder, end)
            builder.build()
        }

        val events = mutableListOf<Map<String, Any?>>()
        try {
            cr.query(
                uri,
                projection,
                null,
                null,
                "${CalendarContract.Instances.BEGIN} ASC"
            )?.use { cursor ->
                val titleIdx = cursor.getColumnIndex(CalendarContract.Instances.TITLE)
                val beginIdx = cursor.getColumnIndex(CalendarContract.Instances.BEGIN)
                val endIdx = cursor.getColumnIndex(CalendarContract.Instances.END)
                val locIdx = cursor.getColumnIndex(CalendarContract.Instances.EVENT_LOCATION)
                val allDayIdx = cursor.getColumnIndex(CalendarContract.Instances.ALL_DAY)
                val calIdx = cursor.getColumnIndex(CalendarContract.Instances.CALENDAR_DISPLAY_NAME)

                while (cursor.moveToNext()) {
                    events.add(
                        mapOf(
                            "title" to (cursor.getString(titleIdx) ?: "Event"),
                            "begin" to cursor.getLong(beginIdx),
                            "end" to cursor.getLong(endIdx),
                            "location" to cursor.getString(locIdx),
                            "allDay" to (cursor.getInt(allDayIdx) == 1),
                            "calendar" to cursor.getString(calIdx)
                        )
                    )
                }
            }
        } catch (_: SecurityException) {
            // Missing READ_CALENDAR
        } catch (_: Exception) {
        }
        return events
    }
}
