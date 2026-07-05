package com.tursinalabs.quranoffline.widget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.tursinalabs.quranoffline.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity
import org.json.JSONObject

private val SagePrimary = Color(0xFF5A7358)
private val SageDark = Color(0xFF4A6B48)
private val Muted = Color(0xFF5C6B58)
private val Bg = Color(0xFFFDFDFD)
private val TextPrimary = Color(0xFF2D3F30)
private val Track = Color(0x1F5A7358)
private val SagePrimaryProvider = ColorProvider(SagePrimary)
private val SageDarkProvider = ColorProvider(SageDark)
private val MutedProvider = ColorProvider(Muted)
private val TextPrimaryProvider = ColorProvider(TextPrimary)
private val WhiteProvider = ColorProvider(Color.White)

class QuranBerandaWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            BerandaWidgetContent(context, currentState())
        }
    }
}

@Composable
private fun BerandaWidgetContent(context: Context, state: HomeWidgetGlanceState) {
    val payload = parsePayload(state.preferences.getString("beranda_payload", null))

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(Bg)
            .padding(12.dp)
            .clickable(
                onClick = actionStartActivity<MainActivity>(
                    context,
                    Uri.parse(payload.reflectionDeepLink),
                ),
            ),
        verticalAlignment = Alignment.Vertical.Top,
    ) {
        HeaderRow(payload.tagline)

        Spacer(modifier = GlanceModifier.height(8.dp))

        Column(
            modifier = GlanceModifier
                .fillMaxWidth()
                .clickable(
                    onClick = actionStartActivity<MainActivity>(
                        context,
                        Uri.parse(payload.reflectionDeepLink),
                    ),
                ),
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.Vertical.CenterVertically,
            ) {
                Text(
                    text = payload.reflectionLabel.uppercase(),
                    style = TextStyle(color = MutedProvider, fontSize = 8.sp, fontWeight = FontWeight.Medium),
                    modifier = GlanceModifier.defaultWeight(),
                )
                if (payload.reflectionBadge.isNotEmpty()) {
                    Text(
                        text = payload.reflectionBadge,
                        style = TextStyle(color = SagePrimaryProvider, fontSize = 7.sp, fontWeight = FontWeight.Medium),
                        modifier = GlanceModifier
                            .background(Color(0xB3FFFFFF))
                            .padding(horizontal = 6.dp, vertical = 2.dp),
                    )
                }
            }
            if (payload.reflectionTitle.isNotEmpty()) {
                Spacer(modifier = GlanceModifier.height(3.dp))
                Text(
                    text = payload.reflectionTitle,
                    style = TextStyle(color = TextPrimaryProvider, fontSize = 12.sp, fontWeight = FontWeight.Medium),
                    maxLines = 2,
                )
            }
            if (payload.reflectionRef.isNotEmpty()) {
                Spacer(modifier = GlanceModifier.height(2.dp))
                Text(
                    text = payload.reflectionRef,
                    style = TextStyle(color = SagePrimaryProvider, fontSize = 8.sp, fontWeight = FontWeight.Medium),
                    maxLines = 1,
                )
            }
        }

        if (payload.hasContinue) {
            Spacer(modifier = GlanceModifier.height(8.dp))
            Column(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .clickable(
                        onClick = actionStartActivity<MainActivity>(
                            context,
                            Uri.parse(payload.readDeepLink),
                        ),
                    ),
            ) {
                Spacer(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .height(1.dp)
                        .background(Color(0x245A7358)),
                )
                Spacer(modifier = GlanceModifier.height(6.dp))
                Text(
                    text = payload.continueLabel.uppercase(),
                    style = TextStyle(color = MutedProvider, fontSize = 8.sp, fontWeight = FontWeight.Medium),
                )
                Spacer(modifier = GlanceModifier.height(4.dp))
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    verticalAlignment = Alignment.Vertical.CenterVertically,
                ) {
                    Text(
                        text = payload.surahName,
                        style = TextStyle(color = TextPrimaryProvider, fontSize = 13.sp, fontWeight = FontWeight.Medium),
                        modifier = GlanceModifier.defaultWeight(),
                        maxLines = 1,
                    )
                    if (payload.ayahNo > 0) {
                        Text(
                            text = "Ayat ${payload.ayahNo}",
                            style = TextStyle(color = SagePrimaryProvider, fontSize = 9.sp, fontWeight = FontWeight.Medium),
                        )
                    }
                }
                if (payload.surahPercent >= 0) {
                    Spacer(modifier = GlanceModifier.height(5.dp))
                    ProgressRow(label = "SURAH", percent = payload.surahPercent, accent = SagePrimaryProvider)
                }
                if (payload.juzPercent >= 0 && payload.juzLabel.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    ProgressRow(label = payload.juzLabel.uppercase(), percent = payload.juzPercent, accent = SageDarkProvider)
                }
            }
        }
    }
}

@Composable
private fun HeaderRow(tagline: String) {
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        Text(
            text = "Q",
            style = TextStyle(color = WhiteProvider, fontSize = 8.sp, fontWeight = FontWeight.Bold),
            modifier = GlanceModifier
                .background(SagePrimary)
                .padding(horizontal = 4.dp, vertical = 2.dp),
        )
        Spacer(modifier = GlanceModifier.width(5.dp))
        Text(
            text = "Quran Offline",
            style = TextStyle(color = MutedProvider, fontSize = 8.sp, fontWeight = FontWeight.Medium),
        )
        Spacer(modifier = GlanceModifier.width(4.dp))
        Text(
            text = "— $tagline",
            style = TextStyle(color = MutedProvider, fontSize = 7.sp),
            maxLines = 1,
            modifier = GlanceModifier.defaultWeight(),
        )
    }
}

@Composable
private fun ProgressRow(label: String, percent: Int, accent: ColorProvider) {
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        Text(
            text = label,
            style = TextStyle(color = MutedProvider, fontSize = 7.sp, fontWeight = FontWeight.Medium),
            modifier = GlanceModifier.defaultWeight(),
        )
        Text(
            text = "$percent%",
            style = TextStyle(color = accent, fontSize = 7.sp, fontWeight = FontWeight.Medium),
        )
    }
    Spacer(modifier = GlanceModifier.height(3.dp))
    ProgressBar(percent = percent, accent = accent)
}

@Composable
private fun ProgressBar(percent: Int, accent: ColorProvider) {
    val track = ColorProvider(Track)
    val clamped = percent.coerceIn(0, 100)
    val filledSegments = (clamped / 5).coerceAtLeast(if (clamped > 0) 1 else 0)
    Row(modifier = GlanceModifier.fillMaxWidth().height(4.dp)) {
        repeat(20) { index ->
            Spacer(
                modifier = GlanceModifier
                    .defaultWeight()
                    .height(4.dp)
                    .background(if (index < filledSegments) accent else track),
            )
        }
    }
}

private data class WidgetPayload(
    val tagline: String,
    val reflectionLabel: String,
    val reflectionTitle: String,
    val reflectionRef: String,
    val reflectionBadge: String,
    val continueLabel: String,
    val surahName: String,
    val ayahNo: Int,
    val surahPercent: Int,
    val juzLabel: String,
    val juzPercent: Int,
    val readDeepLink: String,
    val reflectionDeepLink: String,
    val hasContinue: Boolean,
)

private fun emptyWidgetPayload() = WidgetPayload(
    tagline = "Baca, renungkan, lanjutkan tilawah",
    reflectionLabel = "Renungan",
    reflectionTitle = "",
    reflectionRef = "",
    reflectionBadge = "",
    continueLabel = "Lanjutkan baca",
    surahName = "",
    ayahNo = 0,
    surahPercent = -1,
    juzLabel = "",
    juzPercent = -1,
    readDeepLink = "quranoffline://home",
    reflectionDeepLink = "quranoffline://reflection",
    hasContinue = false,
)

private fun parsePayload(raw: String?): WidgetPayload {
    if (raw.isNullOrBlank()) return emptyWidgetPayload()
    return try {
        val json = JSONObject(raw)
        WidgetPayload(
            tagline = json.optString("tagline", ""),
            reflectionLabel = json.optString("reflectionLabel", "Renungan"),
            reflectionTitle = json.optString("reflectionTitle", ""),
            reflectionRef = json.optString("reflectionRef", ""),
            reflectionBadge = json.optString("reflectionBadge", ""),
            continueLabel = json.optString("continueLabel", "Lanjutkan baca"),
            surahName = json.optString("surahName", ""),
            ayahNo = json.optInt("ayahNo", 0),
            surahPercent = json.optInt("surahPercent", -1),
            juzLabel = json.optString("juzLabel", ""),
            juzPercent = json.optInt("juzPercent", -1),
            readDeepLink = json.optString("readDeepLink", "quranoffline://home"),
            reflectionDeepLink = json.optString("reflectionDeepLink", "quranoffline://reflection"),
            hasContinue = json.optBoolean("hasContinue", false),
        )
    } catch (_: Exception) {
        emptyWidgetPayload()
    }
}
