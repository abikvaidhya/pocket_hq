package com.abik.vaidhya.pocket_hq.widgets

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object WidgetDataStore {
    const val PREFS = "pocket_hq_widget"
    private const val KEY_PAGE = "page" // 0 notes, 1 habits, 2 screen
    private const val KEY_NOTES = "notes_json"
    private const val KEY_HABITS = "habits_json"
    private const val KEY_APPS = "apps_json"
    private const val KEY_SCREEN_TOTAL = "screen_total"
    private const val KEY_COMPLETED_QUEUE = "habit_completed_queue"

    fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun getPage(context: Context): Int =
        prefs(context).getInt(KEY_PAGE, 0).coerceIn(0, 2)

    fun setPage(context: Context, page: Int) {
        prefs(context).edit().putInt(KEY_PAGE, page.coerceIn(0, 2)).apply()
    }

    fun cyclePage(context: Context, delta: Int): Int {
        val next = (getPage(context) + delta + 3) % 3
        setPage(context, next)
        return next
    }

    data class NoteItem(
        val id: String,
        val title: String,
        val isVoice: Boolean,
        val audioPath: String?,
        val isPinned: Boolean,
        val durationLabel: String
    )

    data class HabitItem(
        val id: String,
        val title: String,
        val colorArgb: Long
    )

    data class AppItem(
        val name: String,
        val minutes: Int
    )

    fun saveFromFlutter(
        context: Context,
        notesJson: String,
        habitsJson: String,
        appsJson: String,
        screenTotal: String
    ) {
        prefs(context).edit()
            .putString(KEY_NOTES, notesJson)
            .putString(KEY_HABITS, habitsJson)
            .putString(KEY_APPS, appsJson)
            .putString(KEY_SCREEN_TOTAL, screenTotal)
            .apply()
    }

    fun getNotes(context: Context): List<NoteItem> {
        val raw = prefs(context).getString(KEY_NOTES, "[]") ?: "[]"
        return try {
            val arr = JSONArray(raw)
            buildList {
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    add(
                        NoteItem(
                            id = o.optString("id"),
                            title = o.optString("title", "Note"),
                            isVoice = o.optBoolean("isVoice", false),
                            audioPath = o.optString("audioPath", null).takeIf { !it.isNullOrBlank() },
                            isPinned = o.optBoolean("isPinned", false),
                            durationLabel = o.optString("durationLabel", "")
                        )
                    )
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun getHabits(context: Context): List<HabitItem> {
        val raw = prefs(context).getString(KEY_HABITS, "[]") ?: "[]"
        return try {
            val arr = JSONArray(raw)
            buildList {
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    add(
                        HabitItem(
                            id = o.optString("id"),
                            title = o.optString("title", "Habit"),
                            colorArgb = o.optLong("color", 0xFF5B6CFF)
                        )
                    )
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun getApps(context: Context): List<AppItem> {
        val raw = prefs(context).getString(KEY_APPS, "[]") ?: "[]"
        return try {
            val arr = JSONArray(raw)
            buildList {
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    add(
                        AppItem(
                            name = o.optString("name", "App"),
                            minutes = o.optInt("minutes", 0)
                        )
                    )
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun getScreenTotal(context: Context): String =
        prefs(context).getString(KEY_SCREEN_TOTAL, "0m") ?: "0m"

    /** Remove habit from widget list and queue id for Flutter to apply. */
    fun completeHabit(context: Context, habitId: String) {
        val remaining = getHabits(context).filter { it.id != habitId }
        val arr = JSONArray()
        remaining.forEach { h ->
            arr.put(
                JSONObject()
                    .put("id", h.id)
                    .put("title", h.title)
                    .put("color", h.colorArgb)
            )
        }
        val queue = prefs(context).getString(KEY_COMPLETED_QUEUE, "[]") ?: "[]"
        val q = try {
            JSONArray(queue)
        } catch (_: Exception) {
            JSONArray()
        }
        q.put(habitId)
        prefs(context).edit()
            .putString(KEY_HABITS, arr.toString())
            .putString(KEY_COMPLETED_QUEUE, q.toString())
            .apply()
    }

    /** Flutter reads + clears on resume. */
    fun drainCompletedHabitIds(context: Context): List<String> {
        val queue = prefs(context).getString(KEY_COMPLETED_QUEUE, "[]") ?: "[]"
        val ids = try {
            val arr = JSONArray(queue)
            buildList {
                for (i in 0 until arr.length()) add(arr.getString(i))
            }
        } catch (_: Exception) {
            emptyList()
        }
        prefs(context).edit().putString(KEY_COMPLETED_QUEUE, "[]").apply()
        return ids
    }
}
