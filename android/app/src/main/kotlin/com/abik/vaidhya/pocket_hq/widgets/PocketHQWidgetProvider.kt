package com.abik.vaidhya.pocket_hq.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.MediaPlayer
import android.view.View
import android.widget.RemoteViews
import com.abik.vaidhya.pocket_hq.MainActivity
import com.abik.vaidhya.pocket_hq.R

/**
 * Classic RemoteViews home widget (no Glance / Compose).
 * Sections: 0 Notes · 1 Habits · 2 Screen — cycle via next/prev or tabs.
 */
class PocketHQWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, id)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_CYCLE -> {
                val delta = intent.getIntExtra(EXTRA_DELTA, 1)
                WidgetDataStore.cyclePage(context, delta)
                refreshAll(context)
            }
            ACTION_SET_PAGE -> {
                val page = intent.getIntExtra(EXTRA_PAGE, 0)
                WidgetDataStore.setPage(context, page)
                refreshAll(context)
            }
            ACTION_COMPLETE_HABIT -> {
                val habitId = intent.getStringExtra(EXTRA_HABIT_ID) ?: return
                WidgetDataStore.completeHabit(context, habitId)
                refreshAll(context)
            }
            ACTION_TOGGLE_VOICE -> {
                val path = intent.getStringExtra(EXTRA_AUDIO_PATH) ?: return
                WidgetAudioPlayer.toggle(path)
                refreshAll(context)
            }
            ACTION_OPEN_APP -> {
                val route = intent.getStringExtra(EXTRA_ROUTE) ?: "/notes"
                val noteId = intent.getStringExtra(EXTRA_NOTE_ID)
                val i = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("route", route)
                    if (!noteId.isNullOrBlank()) putExtra("noteId", noteId)
                }
                context.startActivity(i)
            }
        }
    }

    companion object {
        const val ACTION_CYCLE = "com.pockethq.widget.CYCLE"
        const val ACTION_SET_PAGE = "com.pockethq.widget.SET_PAGE"
        const val ACTION_COMPLETE_HABIT = "com.pockethq.widget.COMPLETE_HABIT"
        const val ACTION_TOGGLE_VOICE = "com.pockethq.widget.TOGGLE_VOICE"
        const val ACTION_OPEN_APP = "com.pockethq.widget.OPEN_APP"

        const val EXTRA_DELTA = "delta"
        const val EXTRA_PAGE = "page"
        const val EXTRA_HABIT_ID = "habit_id"
        const val EXTRA_AUDIO_PATH = "audio_path"
        const val EXTRA_ROUTE = "route"
        const val EXTRA_NOTE_ID = "note_id"

        fun refreshAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, PocketHQWidgetProvider::class.java)
            )
            for (id in ids) {
                updateAppWidget(context, mgr, id)
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.pocket_hq_widget)
            val page = WidgetDataStore.getPage(context)

            // Header actions
            views.setOnClickPendingIntent(
                R.id.btn_prev,
                pendingBroadcast(context, ACTION_CYCLE, EXTRA_DELTA to -1)
            )
            views.setOnClickPendingIntent(
                R.id.btn_next,
                pendingBroadcast(context, ACTION_CYCLE, EXTRA_DELTA to 1)
            )
            views.setOnClickPendingIntent(
                R.id.tab_notes,
                pendingBroadcast(context, ACTION_SET_PAGE, EXTRA_PAGE to 0)
            )
            views.setOnClickPendingIntent(
                R.id.tab_habits,
                pendingBroadcast(context, ACTION_SET_PAGE, EXTRA_PAGE to 1)
            )
            views.setOnClickPendingIntent(
                R.id.tab_screen,
                pendingBroadcast(context, ACTION_SET_PAGE, EXTRA_PAGE to 2)
            )

            // Highlight tabs
            val accent = 0xFF8B9BFF.toInt()
            val muted = 0xFF9AA0A8.toInt()
            views.setTextColor(R.id.tab_notes, if (page == 0) accent else muted)
            views.setTextColor(R.id.tab_habits, if (page == 1) accent else muted)
            views.setTextColor(R.id.tab_screen, if (page == 2) accent else muted)

            // Hide all rows first
            for (i in 0 until 4) {
                views.setViewVisibility(rowId(i), View.GONE)
                views.setViewVisibility(actionId(i), View.GONE)
            }

            when (page) {
                0 -> bindNotes(context, views)
                1 -> bindHabits(context, views)
                else -> bindScreen(context, views)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun bindNotes(context: Context, views: RemoteViews) {
            views.setTextViewText(R.id.section_title, "Notes")
            views.setOnClickPendingIntent(
                R.id.widget_root,
                pendingBroadcast(context, ACTION_OPEN_APP, EXTRA_ROUTE to "/notes")
            )

            val notes = WidgetDataStore.getNotes(context)
            val pinned = notes.filter { it.isPinned }
            val display = if (pinned.isNotEmpty()) pinned else notes

            if (display.isEmpty()) {
                views.setViewVisibility(R.id.row_0, View.VISIBLE)
                views.setTextViewText(R.id.row_0_text, "No notes yet. Open app to create one.")
                views.setViewVisibility(R.id.row_0_action, View.GONE)
                return
            }

            display.take(3).forEachIndexed { index, note ->
                val rid = rowId(index)
                val aid = actionId(index)
                val tid = textId(index)
                views.setViewVisibility(rid, View.VISIBLE)
                val title = note.title.ifBlank {
                    if (note.isVoice) "Voice note" else "Note"
                }
                views.setTextViewText(tid, title)

                if (note.isVoice && !note.audioPath.isNullOrBlank()) {
                    views.setViewVisibility(aid, View.VISIBLE)
                    val playing =
                        WidgetAudioPlayer.playingPath == note.audioPath && WidgetAudioPlayer.isPlaying
                    views.setTextViewText(aid, if (playing) "❚❚" else "▶")
                    views.setOnClickPendingIntent(
                        aid,
                        pendingBroadcast(
                            context,
                            ACTION_TOGGLE_VOICE,
                            EXTRA_AUDIO_PATH to note.audioPath!!
                        )
                    )
                    // Don't open app on row tap for voice
                    views.setOnClickPendingIntent(rid, null)
                } else {
                    views.setViewVisibility(aid, View.GONE)
                    views.setOnClickPendingIntent(
                        rid,
                        pendingBroadcast(
                            context,
                            ACTION_OPEN_APP,
                            EXTRA_ROUTE to "/notes",
                            EXTRA_NOTE_ID to note.id
                        )
                    )
                }
            }
        }

        private fun bindHabits(context: Context, views: RemoteViews) {
            views.setTextViewText(R.id.section_title, "Pending habits")
            views.setOnClickPendingIntent(
                R.id.widget_root,
                pendingBroadcast(context, ACTION_OPEN_APP, EXTRA_ROUTE to "/habits")
            )

            val habits = WidgetDataStore.getHabits(context)
            if (habits.isEmpty()) {
                views.setViewVisibility(R.id.row_0, View.VISIBLE)
                views.setTextViewText(
                    R.id.row_0_text,
                    "No pending habits. Create some in the app."
                )
                views.setViewVisibility(R.id.row_0_action, View.GONE)
                return
            }

            habits.take(3).forEachIndexed { index, habit ->
                val rid = rowId(index)
                val aid = actionId(index)
                val tid = textId(index)
                views.setViewVisibility(rid, View.VISIBLE)
                views.setViewVisibility(aid, View.VISIBLE)
                views.setTextViewText(tid, habit.title)
                views.setTextViewText(aid, "✓")
                views.setOnClickPendingIntent(
                    aid,
                    pendingBroadcast(
                        context,
                        ACTION_COMPLETE_HABIT,
                        EXTRA_HABIT_ID to habit.id
                    )
                )
            }
        }

        private fun bindScreen(context: Context, views: RemoteViews) {
            val total = WidgetDataStore.getScreenTotal(context)
            views.setTextViewText(R.id.section_title, "Screen time  ·  $total")
            views.setOnClickPendingIntent(
                R.id.widget_root,
                pendingBroadcast(context, ACTION_OPEN_APP, EXTRA_ROUTE to "/focus")
            )

            val apps = WidgetDataStore.getApps(context)
            if (apps.isEmpty()) {
                views.setViewVisibility(R.id.row_0, View.VISIBLE)
                views.setTextViewText(
                    R.id.row_0_text,
                    "No usage data. Grant access in Focus."
                )
                views.setViewVisibility(R.id.row_0_action, View.GONE)
                return
            }

            apps.take(4).forEachIndexed { index, app ->
                val rid = rowId(index)
                val tid = textId(index)
                views.setViewVisibility(rid, View.VISIBLE)
                views.setViewVisibility(actionId(index), View.GONE)
                val mins = if (app.minutes < 60) {
                    "${app.minutes}m"
                } else {
                    "${app.minutes / 60}h ${app.minutes % 60}m"
                }
                views.setTextViewText(tid, "${app.name}  ·  $mins")
            }
        }

        private fun rowId(i: Int) = when (i) {
            0 -> R.id.row_0
            1 -> R.id.row_1
            2 -> R.id.row_2
            else -> R.id.row_3
        }

        private fun textId(i: Int) = when (i) {
            0 -> R.id.row_0_text
            1 -> R.id.row_1_text
            2 -> R.id.row_2_text
            else -> R.id.row_3_text
        }

        private fun actionId(i: Int) = when (i) {
            0 -> R.id.row_0_action
            1 -> R.id.row_1_action
            2 -> R.id.row_2_action
            else -> R.id.row_3_action
        }

        private fun pendingBroadcast(
            context: Context,
            action: String,
            vararg extras: Pair<String, Any>
        ): PendingIntent {
            val intent = Intent(context, PocketHQWidgetProvider::class.java).apply {
                this.action = action
                extras.forEach { (k, v) ->
                    when (v) {
                        is Int -> putExtra(k, v)
                        is String -> putExtra(k, v)
                    }
                }
            }
            val requestCode = action.hashCode() xor extras.contentHashCode()
            return PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }
}

/** Simple process-local player for voice notes on the widget. */
object WidgetAudioPlayer {
    private var player: MediaPlayer? = null

    @Volatile
    var isPlaying: Boolean = false

    @Volatile
    var playingPath: String? = null

    fun toggle(path: String) {
        try {
            val current = player
            if (playingPath == path && current != null) {
                if (current.isPlaying) {
                    current.pause()
                    isPlaying = false
                } else {
                    current.start()
                    isPlaying = true
                }
                return
            }
            release()
            val mp = MediaPlayer()
            mp.setDataSource(path)
            mp.setOnCompletionListener {
                isPlaying = false
                playingPath = null
            }
            mp.prepare()
            mp.start()
            player = mp
            playingPath = path
            isPlaying = true
        } catch (_: Exception) {
            release()
        }
    }

    fun release() {
        try {
            player?.release()
        } catch (_: Exception) {
        }
        player = null
        playingPath = null
        isPlaying = false
    }
}
