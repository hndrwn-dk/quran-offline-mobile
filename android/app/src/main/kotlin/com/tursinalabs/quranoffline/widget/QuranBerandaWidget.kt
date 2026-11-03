package com.tursinalabs.quranoffline.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.os.Build
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.Action
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ColumnScope
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.tursinalabs.quranoffline.MainActivity
import com.tursinalabs.quranoffline.R
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity

private val Ink = ColorProvider(R.color.widget_ink)
private val Muted = ColorProvider(R.color.widget_muted)
private val Primary = ColorProvider(R.color.widget_primary)
private val OnPrimary = ColorProvider(R.color.widget_on_primary)
private val OnPrimaryContainer = ColorProvider(R.color.widget_on_primary_container)

/**
 * Responsive buckets: ~2×1 continue, ~4×2 ayah, ~4×3+ full reflection.
 * In Responsive mode LocalSize is the matched bucket, not the real size, so
 * the extra heights let each layout grow its translation and title.
 * Cell heights differ a lot per launcher (a Pixel 4×2 is ~227dp, the AOSP
 * minimum ~130dp), so the large layout starts above a tall 4×2.
 */
private val SmallSize = DpSize(110.dp, 40.dp)
// A Pixel 4×1 is ~106dp: too short for the ayah, so it keeps the continue layout.
private val MediumSize = DpSize(200.dp, 120.dp)
private val LargeSize = DpSize(200.dp, 240.dp)
private val ResponsiveSizes = setOf(
    SmallSize,
    DpSize(110.dp, 64.dp),
    DpSize(250.dp, 40.dp),
    DpSize(250.dp, 64.dp),
    MediumSize,
    DpSize(200.dp, 150.dp),
    DpSize(200.dp, 190.dp),
    LargeSize,
    DpSize(200.dp, 280.dp),
    DpSize(200.dp, 320.dp),
)

/** Bucket widths are minimums; 4-column widgets are wider, so size the image box for that. */
private const val ASSUMED_WIDTH_DP = 280f

/** Height of one 12sp translation line and of an 11sp label, for the image budget. */
private const val TRANSLATION_LINE_DP = 16
private const val LABEL_LINE_DP = 16

class QuranBerandaWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override val sizeMode = SizeMode.Responsive(ResponsiveSizes)

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val state: HomeWidgetGlanceState = currentState()
            WidgetRoot(WidgetPayload.parse(state.preferences.getString(PAYLOAD_KEY, null)))
        }
    }

    companion object {
        const val PAYLOAD_KEY = "beranda_payload"
    }
}

@Composable
private fun WidgetRoot(payload: WidgetPayload?) {
    val size = LocalSize.current
    var modifier = GlanceModifier
        .fillMaxSize()
        .appWidgetBackground()
        .background(ImageProvider(R.drawable.widget_background))
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        modifier = modifier.cornerRadius(android.R.dimen.system_app_widget_background_radius)
    }
    Box(modifier = modifier) {
        when {
            payload == null -> NotReadyContent()
            size.height >= LargeSize.height && size.width >= LargeSize.width && payload.hasReflection ->
                LargeContent(payload)
            size.height >= MediumSize.height && size.width >= MediumSize.width && payload.hasReflection ->
                MediumContent(payload)
            else -> SmallContent(payload)
        }
    }
}

@Composable
private fun NotReadyContent() {
    val context = LocalContext.current
    Column(
        modifier = GlanceModifier.fillMaxSize().padding(horizontal = 14.dp, vertical = 10.dp)
            .clickable(open(context, WidgetPayload.DEFAULT_READ_LINK)),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(context.getString(R.string.widget_beranda_label), style = label(Primary))
        Text(
            context.getString(R.string.widget_open_app_hint),
            style = TextStyle(color = Muted, fontSize = 12.sp),
            maxLines = 2,
        )
    }
}

/** ~2×1: progress ring + surah · page · juz; tap resumes the last-read page. */
@Composable
private fun SmallContent(payload: WidgetPayload) {
    val context = LocalContext.current
    val size = LocalSize.current
    val tall = size.height >= 64.dp
    val description = if (payload.hasContinue) {
        "${payload.continueTitle}, ${payload.surahName}, ${payload.continueMeta}. ${payload.continueDescription}"
    } else {
        payload.continueTitle
    }
    Row(
        modifier = GlanceModifier.fillMaxSize()
            .padding(horizontal = 12.dp, vertical = 6.dp)
            .clickable(open(context, payload.readDeepLink))
            .semantics { contentDescription = description },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ProgressRing(percent = payload.continuePercent.coerceAtLeast(0), diameter = if (tall) 44.dp else 38.dp)
        Spacer(GlanceModifier.width(10.dp))
        Column(modifier = GlanceModifier.defaultWeight()) {
            if (payload.hasContinue) {
                if (tall) Text(payload.continueTitle, style = label(Primary), maxLines = 1)
                Text(
                    payload.surahName,
                    style = TextStyle(color = Ink, fontSize = 15.sp, fontWeight = FontWeight.Bold),
                    maxLines = 1,
                )
                Text(payload.continueMeta, style = TextStyle(color = Muted, fontSize = 11.sp), maxLines = 1)
            } else {
                Text(
                    payload.continueTitle,
                    style = TextStyle(color = Ink, fontSize = 15.sp, fontWeight = FontWeight.Bold),
                    maxLines = 1,
                )
                Text(payload.continueHint, style = TextStyle(color = Muted, fontSize = 11.sp), maxLines = 2)
            }
        }
        // A wide 4×1 has room for the explicit action.
        if (payload.hasContinue && size.width >= 250.dp) {
            Spacer(GlanceModifier.width(8.dp))
            ActionButton(
                text = payload.continueButton,
                action = open(context, payload.readDeepLink),
                filled = true,
                modifier = GlanceModifier.width(140.dp),
            )
        }
    }
}

/** ~4×2: one ayah (QPC V2 image), translation, reference; tap opens the ayah. */
@Composable
private fun MediumContent(payload: WidgetPayload) {
    val context = LocalContext.current
    val size = LocalSize.current
    val translationLines = if (size.height >= 190.dp) 3 else if (size.height >= 150.dp) 2 else 1
    // padding 20 + label + spacers 12 + translation + reference
    val reserved = 20 + LABEL_LINE_DP + 12 + translationLines * TRANSLATION_LINE_DP + LABEL_LINE_DP
    Column(
        modifier = GlanceModifier.fillMaxSize()
            .padding(horizontal = 14.dp, vertical = 10.dp)
            .clickable(open(context, payload.reflectionTapLink)),
    ) {
        Text(payload.reflectionLabel, style = label(Primary), maxLines = 1)
        AyahBlock(
            payload = payload,
            imagePath = ayahImageFor(payload, size.width.value - 28, size.height.value - reserved),
            translationLines = translationLines,
        )
    }
}

/** ~4×3+: title, ayah, translation, "1 dari N ayat", and two actions. */
@Composable
private fun LargeContent(payload: WidgetPayload) {
    val context = LocalContext.current
    val size = LocalSize.current
    val titleLines = if (size.height >= 320.dp) 2 else 1
    val translationLines = if (size.height >= 320.dp) 4 else if (size.height >= 280.dp) 3 else 2
    // padding 24 + label + title + spacers 20 + translation + reference + buttons 44
    val reserved = 24 + LABEL_LINE_DP + titleLines * 22 + 20 +
        translationLines * TRANSLATION_LINE_DP + LABEL_LINE_DP + 44
    Column(modifier = GlanceModifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 12.dp)) {
        Column(
            modifier = GlanceModifier.fillMaxWidth().defaultWeight()
                .clickable(open(context, payload.reflectionTapLink)),
        ) {
            Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    payload.reflectionLabel,
                    style = label(Primary),
                    maxLines = 1,
                    modifier = GlanceModifier.defaultWeight(),
                )
                if (payload.ayahPosition.isNotEmpty()) {
                    Text(payload.ayahPosition, style = TextStyle(color = Muted, fontSize = 11.sp), maxLines = 1)
                }
            }
            if (payload.reflectionTitle.isNotEmpty()) {
                Text(
                    payload.reflectionTitle,
                    style = TextStyle(color = Ink, fontSize = 16.sp, fontWeight = FontWeight.Bold),
                    maxLines = titleLines,
                )
            }
            AyahBlock(
                payload = payload,
                imagePath = ayahImageFor(payload, size.width.value - 32, size.height.value - reserved),
                translationLines = translationLines,
            )
        }
        Spacer(GlanceModifier.height(8.dp))
        Row(modifier = GlanceModifier.fillMaxWidth()) {
            ActionButton(
                text = payload.reflectionButton.ifEmpty { context.getString(R.string.widget_read_reflection) },
                action = open(context, payload.reflectionDeepLink),
                filled = false,
                modifier = GlanceModifier.defaultWeight(),
            )
            Spacer(GlanceModifier.width(8.dp))
            ActionButton(
                text = payload.continueButton.ifEmpty { context.getString(R.string.widget_continue) },
                action = open(context, payload.readDeepLink),
                filled = true,
                modifier = GlanceModifier.defaultWeight(),
            )
        }
    }
}

/**
 * The 2-line render (~4.5:1) suits wide, short boxes; the 3-line one (~2:1)
 * reads bigger once the box is at least ~1:3 tall. Either falls back to the other.
 */
private fun ayahImageFor(payload: WidgetPayload, boxWidthDp: Float, boxHeightDp: Float): String {
    val width = maxOf(boxWidthDp, ASSUMED_WIDTH_DP)
    val tall = boxHeightDp / width >= 0.33f
    val preferred = if (tall) payload.ayahImageLarge else payload.ayahImageMedium
    return preferred.ifEmpty { payload.ayahImageMedium.ifEmpty { payload.ayahImageLarge } }
}

/** Arabic image (tinted with the theme ink) over translation and reference. */
@Composable
private fun ColumnScope.AyahBlock(payload: WidgetPayload, imagePath: String, translationLines: Int) {
    val bitmap = loadBitmap(imagePath)
    Spacer(GlanceModifier.height(6.dp))
    if (bitmap != null) {
        Image(
            provider = ImageProvider(bitmap),
            contentDescription = payload.ayahRef,
            contentScale = ContentScale.Fit,
            colorFilter = ColorFilter.tint(Ink),
            modifier = GlanceModifier.fillMaxWidth().defaultWeight(),
        )
        Spacer(GlanceModifier.height(6.dp))
    }
    if (payload.ayahTranslation.isNotEmpty()) {
        Text(
            payload.ayahTranslation,
            style = TextStyle(color = Ink, fontSize = 12.sp),
            maxLines = if (bitmap == null) translationLines + 2 else translationLines,
        )
        Spacer(GlanceModifier.height(2.dp))
    }
    if (payload.ayahRef.isNotEmpty()) {
        Text(payload.ayahRef, style = label(Primary), maxLines = 1)
    }
}

@Composable
private fun ActionButton(text: String, action: Action, filled: Boolean, modifier: GlanceModifier) {
    Box(
        modifier = modifier
            .height(36.dp)
            .background(ImageProvider(if (filled) R.drawable.widget_button_filled else R.drawable.widget_button_tonal))
            .clickable(action)
            .semantics { contentDescription = text },
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text,
            style = TextStyle(
                color = if (filled) OnPrimary else OnPrimaryContainer,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
                textAlign = TextAlign.Center,
            ),
            maxLines = 1,
            modifier = GlanceModifier.padding(horizontal = 8.dp),
        )
    }
}

/**
 * Track + arc are white masks tinted with the theme primary, so they follow
 * night mode. Glance's tint drops a color's alpha, so the track's transparency
 * lives in its bitmap.
 */
@Composable
private fun ProgressRing(percent: Int, diameter: androidx.compose.ui.unit.Dp) {
    Box(modifier = GlanceModifier.size(diameter), contentAlignment = Alignment.Center) {
        Image(
            provider = ImageProvider(ringBitmap(100, TRACK_ALPHA)),
            contentDescription = null,
            colorFilter = ColorFilter.tint(Primary),
            modifier = GlanceModifier.size(diameter),
        )
        if (percent > 0) {
            Image(
                provider = ImageProvider(ringBitmap(percent)),
                contentDescription = null,
                colorFilter = ColorFilter.tint(Primary),
                modifier = GlanceModifier.size(diameter),
            )
        }
        Text(
            "$percent%",
            style = TextStyle(color = Ink, fontSize = 10.sp, fontWeight = FontWeight.Medium),
            maxLines = 1,
        )
    }
}

private fun label(color: ColorProvider, size: TextUnit = 11.sp) =
    TextStyle(color = color, fontSize = size, fontWeight = FontWeight.Medium)

private fun open(context: Context, link: String): Action =
    actionStartActivity<MainActivity>(context, Uri.parse(link))

private fun loadBitmap(path: String): Bitmap? {
    if (path.isEmpty()) return null
    return try {
        BitmapFactory.decodeFile(path)
    } catch (_: Exception) {
        null
    }
}

private const val RING_PX = 132
private const val RING_STROKE_PX = 13f

private const val TRACK_ALPHA = 64

internal fun ringBitmap(percent: Int, alpha: Int = 255): Bitmap {
    val bitmap = Bitmap.createBitmap(RING_PX, RING_PX, Bitmap.Config.ARGB_8888)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = RING_STROKE_PX
        strokeCap = Paint.Cap.ROUND
        color = android.graphics.Color.argb(alpha, 255, 255, 255)
    }
    val inset = RING_STROKE_PX / 2 + 1
    val oval = RectF(inset, inset, RING_PX - inset, RING_PX - inset)
    val sweep = 360f * percent.coerceIn(0, 100) / 100f
    if (sweep >= 360f) {
        Canvas(bitmap).drawOval(oval, paint)
    } else {
        Canvas(bitmap).drawArc(oval, -90f, sweep, false, paint)
    }
    return bitmap
}
