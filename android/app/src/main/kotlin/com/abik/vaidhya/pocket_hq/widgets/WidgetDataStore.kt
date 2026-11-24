package com.abik.vaidhya.pocket_hq.widgets

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object WidgetDataStore {
    const val PREFS = "pocket_hq_widget"
    private const val KEY_NOTES = "notes_json"
    private const val KEY_CART = "cart_json"
    private const val KEY_CART_CHECK_QUEUE = "cart_checked_queue"

    fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    data class NoteItem(
        val id: String,
        val title: String,
        val isVoice: Boolean,
        val audioPath: String?,
        val isPinned: Boolean
    )

    data class CartItemRow(
        val id: String,
        val name: String,
        val checked: Boolean
    )

    data class CartPayload(
        val id: String?,
        val items: List<CartItemRow>
    )

    fun saveFromFlutter(context: Context, notesJson: String?, cartJson: String?) {
        val editor = prefs(context).edit()
        notesJson?.let { editor.putString(KEY_NOTES, it) }
        cartJson?.let { editor.putString(KEY_CART, it) }
        editor.apply()
    }

    fun getNotes(context: Context): List<NoteItem> {
        val raw = prefs(context).getString(KEY_NOTES, "[]") ?: "[]"
        return try {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val note = array.getJSONObject(index)
                    add(
                        NoteItem(
                            id = note.optString("id"),
                            title = note.optString("title", "Note"),
                            isVoice = note.optBoolean("isVoice", false),
                            audioPath = note.optString("audioPath", null)
                                .takeIf { !it.isNullOrBlank() },
                            isPinned = note.optBoolean("isPinned", false)
                        )
                    )
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun getCart(context: Context): CartPayload {
        val raw = prefs(context).getString(KEY_CART, "{}") ?: "{}"
        return try {
            val cart = JSONObject(raw)
            val itemArray = cart.optJSONArray("items") ?: JSONArray()
            val items = buildList {
                for (index in 0 until itemArray.length()) {
                    val item = itemArray.getJSONObject(index)
                    add(
                        CartItemRow(
                            id = item.optString("id"),
                            name = item.optString("name", "Item"),
                            checked = item.optBoolean("checked", false)
                        )
                    )
                }
            }
            CartPayload(
                id = cart.optString("id", null).takeIf { !it.isNullOrBlank() },
                items = items
            )
        } catch (_: Exception) {
            CartPayload(null, emptyList())
        }
    }

    fun toggleCartItem(context: Context, itemId: String) {
        val raw = prefs(context).getString(KEY_CART, "{}") ?: "{}"
        val cart = try {
            JSONObject(raw)
        } catch (_: Exception) {
            return
        }
        val items = cart.optJSONArray("items") ?: return
        var found = false
        for (index in 0 until items.length()) {
            val item = items.optJSONObject(index) ?: continue
            if (item.optString("id") == itemId) {
                item.put("checked", !item.optBoolean("checked", false))
                found = true
                break
            }
        }
        if (!found) return

        val preferences = prefs(context)
        val queue = try {
            JSONArray(preferences.getString(KEY_CART_CHECK_QUEUE, "[]") ?: "[]")
        } catch (_: Exception) {
            JSONArray()
        }
        queue.put(itemId)
        preferences.edit()
            .putString(KEY_CART, cart.toString())
            .putString(KEY_CART_CHECK_QUEUE, queue.toString())
            .apply()
    }

    fun drainCartCheckIds(context: Context): List<String> {
        val preferences = prefs(context)
        val raw = preferences.getString(KEY_CART_CHECK_QUEUE, "[]") ?: "[]"
        val ids = try {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) add(array.getString(index))
            }
        } catch (_: Exception) {
            emptyList()
        }
        preferences.edit().putString(KEY_CART_CHECK_QUEUE, "[]").apply()
        return ids
    }
}
