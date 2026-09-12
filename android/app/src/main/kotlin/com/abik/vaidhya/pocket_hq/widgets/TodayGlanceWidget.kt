package com.abik.vaidhya.pocket_hq.widgets

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

class TodayGlanceWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences("pocket_hq_widget", Context.MODE_PRIVATE)
        val title = prefs.getString("title", "Pocket HQ") ?: "Pocket HQ"
        val subtitle = prefs.getString("subtitle", "Open the app to refresh") ?: "Open the app to refresh"
        val habits = prefs.getString("habits", "—") ?: "—"
        val screen = prefs.getString("screen", "—") ?: "—"

        provideContent {
            GlanceTheme {
                WidgetContent(
                    title = title,
                    subtitle = subtitle,
                    habits = habits,
                    screen = screen
                )
            }
        }
    }

    @Composable
    private fun WidgetContent(
        title: String,
        subtitle: String,
        habits: String,
        screen: String
    ) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ColorProvider(Color(0xFF16181D)))
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalAlignment = Alignment.Start
        ) {
            Text(
                text = title,
                style = TextStyle(
                    color = ColorProvider(Color.White),
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp
                )
            )
            Spacer(GlanceModifier.height(4.dp))
            Text(
                text = subtitle,
                style = TextStyle(
                    color = ColorProvider(Color(0xFFB0B3B8)),
                    fontSize = 12.sp
                )
            )
            Spacer(GlanceModifier.height(12.dp))
            Text(
                text = "Habits  $habits",
                style = TextStyle(
                    color = ColorProvider(Color(0xFF8B9BFF)),
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium
                )
            )
            Spacer(GlanceModifier.height(4.dp))
            Text(
                text = "Screen  $screen",
                style = TextStyle(
                    color = ColorProvider(Color(0xFFB0B3B8)),
                    fontSize = 13.sp
                )
            )
        }
    }
}

class TodayGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = TodayGlanceWidget()
}
