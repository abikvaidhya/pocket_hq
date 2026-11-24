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

class PocketHQWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { updateAppWidget(context, appWidgetManager, it) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_TOGGLE_VOICE -> {
                val path = intent.getStringExtra(EXTRA_AUDIO_PATH) ?: return
                WidgetAudioPlayer.toggle(path)
                refreshAll(context)
            }
            ACTION_OPEN_APP -> openApp(context, intent)
        }
    }

    companion object {
        const val ACTION_TOGGLE_VOICE = "com.pockethq.widget.TOGGLE_VOICE"
        const val ACTION_OPEN_APP = "com.pockethq.widget.OPEN_APP"
        const val EXTRA_AUDIO_PATH = "audio_path"
        const val EXTRA_ROUTE = "route"
        const val EXTRA_NOTE_ID = "note_id"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, PocketHQWidgetProvider::class.java)
            )
            ids.forEach { updateAppWidget(context, manager, it) }
        }

        private fun openApp(context: Context, intent: Intent) {
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("route", intent.getStringExtra(EXTRA_ROUTE) ?: "/notes")
                intent.getStringExtra(EXTRA_NOTE_ID)?.takeIf { it.isNotBlank() }?.let {
                    putExtra("noteId", it)
                }
            }
            context.startActivity(launchIntent)
        }

        private fun updateAppWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.pocket_hq_widget)
            views.setTextViewText(R.id.section_title, "Notes")
            views.setOnClickPendingIntent(
                R.id.widget_root,
                pendingBroadcast(context, ACTION_OPEN_APP, EXTRA_ROUTE to "/notes")
            )

            for (index in 0 until ROW_COUNT) {
                views.setViewVisibility(rowId(index), View.GONE)
                views.setViewVisibility(actionId(index), View.GONE)
            }

            val notes = WidgetDataStore.getNotes(context)
            val pinned = notes.filter { it.isPinned }
            val display = (if (pinned.isNotEmpty()) pinned else notes).take(ROW_COUNT)
            if (display.isEmpty()) {
                views.setViewVisibility(R.id.row_0, View.VISIBLE)
                views.setTextViewText(R.id.row_0_text, "No notes yet. Open app to create one.")
            } else {
                display.forEachIndexed { index, note ->
                    val row = rowId(index)
                    val action = actionId(index)
                    views.setViewVisibility(row, View.VISIBLE)
                    views.setTextViewText(
                        textId(index),
                        note.title.ifBlank { if (note.isVoice) "Voice note" else "Note" }
                    )

                    if (note.isVoice && !note.audioPath.isNullOrBlank()) {
                        val playing =
                            WidgetAudioPlayer.playingPath == note.audioPath &&
                                WidgetAudioPlayer.isPlaying
                        views.setViewVisibility(action, View.VISIBLE)
                        views.setTextViewText(action, if (playing) "❚❚" else "▶")
                        views.setOnClickPendingIntent(
                            action,
                            pendingBroadcast(
                                context,
                                ACTION_TOGGLE_VOICE,
                                EXTRA_AUDIO_PATH to note.audioPath
                            )
                        )
                        views.setOnClickPendingIntent(row, null)
                    } else {
                        views.setOnClickPendingIntent(
                            row,
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
            manager.updateAppWidget(appWidgetId, views)
        }

        private const val ROW_COUNT = 4

        private fun rowId(index: Int) = when (index) {
            0 -> R.id.row_1
            1 -> R.id.row_2
            2 -> R.id.row_3
            else -> R.id.row_0
        }

        private fun textId(index: Int) = when (index) {
            0 -> R.id.row_1_text
            1 -> R.id.row_2_text
            2 -> R.id.row_3_text
            else -> R.id.row_0_text
        }

        private fun actionId(index: Int) = when (index) {
            0 -> R.id.row_1_action
            1 -> R.id.row_2_action
            2 -> R.id.row_3_action
            else -> R.id.row_0_action
        }

        private fun pendingBroadcast(
            context: Context,
            action: String,
            vararg extras: Pair<String, String?>
        ): PendingIntent {
            val intent = Intent(context, PocketHQWidgetProvider::class.java).apply {
                this.action = action
                extras.forEach { (key, value) -> putExtra(key, value) }
            }
            return PendingIntent.getBroadcast(
                context,
                action.hashCode() xor extras.contentHashCode(),
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
