package com.abik.vaidhya.pocket_hq.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import com.abik.vaidhya.pocket_hq.MainActivity
import com.abik.vaidhya.pocket_hq.R

class ShoppingCartWidgetProvider : AppWidgetProvider() {

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
            ACTION_TOGGLE_ITEM -> {
                val itemId = intent.getStringExtra(EXTRA_ITEM_ID) ?: return
                WidgetDataStore.toggleCartItem(context, itemId)
                refreshAll(context)
            }
            ACTION_OPEN_APP -> {
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("route", "/carts")
                }
                context.startActivity(launchIntent)
            }
        }
    }

    companion object {
        const val ACTION_TOGGLE_ITEM = "com.pockethq.widget.TOGGLE_CART_ITEM"
        const val ACTION_OPEN_APP = "com.pockethq.widget.OPEN_APP"
        const val EXTRA_ITEM_ID = "cart_item_id"
        private const val ROW_COUNT = 8

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, ShoppingCartWidgetProvider::class.java)
            )
            ids.forEach { updateAppWidget(context, manager, it) }
        }

        private fun updateAppWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.shopping_cart_widget)
            views.setTextViewText(R.id.section_title, "Cart")
            views.setOnClickPendingIntent(
                R.id.widget_root,
                pendingBroadcast(context, ACTION_OPEN_APP)
            )

            for (index in 0 until ROW_COUNT) {
                views.setViewVisibility(rowId(index), View.GONE)
            }

            val cart = WidgetDataStore.getCart(context)
            val pending = cart.items.filterNot { it.checked }.take(ROW_COUNT)
            if (pending.isEmpty()) {
                views.setViewVisibility(R.id.row_0, View.VISIBLE)
                views.setTextViewText(
                    R.id.row_0_text,
                    if (cart.id.isNullOrBlank()) "Your shopping list is empty"
                    else "Everything is checked off"
                )
                views.setViewVisibility(R.id.row_0_action, View.GONE)
            } else {
                pending.forEachIndexed { index, item ->
                    val row = rowId(index)
                    val action = actionId(index)
                    views.setViewVisibility(row, View.VISIBLE)
                    views.setViewVisibility(action, View.VISIBLE)
                    views.setTextViewText(textId(index), item.name)
                    views.setTextViewText(action, "☐")
                    views.setOnClickPendingIntent(
                        action,
                        pendingBroadcast(
                            context,
                            ACTION_TOGGLE_ITEM,
                            EXTRA_ITEM_ID to item.id
                        )
                    )
                }
            }
            manager.updateAppWidget(appWidgetId, views)
        }

        private fun rowId(index: Int) = when (index) {
            0 -> R.id.row_0
            1 -> R.id.row_1
            2 -> R.id.row_2
            3 -> R.id.row_3
            4 -> R.id.row_4
            5 -> R.id.row_5
            6 -> R.id.row_6
            else -> R.id.row_7
        }

        private fun textId(index: Int) = when (index) {
            0 -> R.id.row_0_text
            1 -> R.id.row_1_text
            2 -> R.id.row_2_text
            3 -> R.id.row_3_text
            4 -> R.id.row_4_text
            5 -> R.id.row_5_text
            6 -> R.id.row_6_text
            else -> R.id.row_7_text
        }

        private fun actionId(index: Int) = when (index) {
            0 -> R.id.row_0_action
            1 -> R.id.row_1_action
            2 -> R.id.row_2_action
            3 -> R.id.row_3_action
            4 -> R.id.row_4_action
            5 -> R.id.row_5_action
            6 -> R.id.row_6_action
            else -> R.id.row_7_action
        }

        private fun pendingBroadcast(
            context: Context,
            action: String,
            extra: Pair<String, String>? = null
        ): PendingIntent {
            val intent = Intent(context, ShoppingCartWidgetProvider::class.java).apply {
                this.action = action
                extra?.let { putExtra(it.first, it.second) }
            }
            return PendingIntent.getBroadcast(
                context,
                action.hashCode() xor (extra?.hashCode() ?: 0),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }
}
