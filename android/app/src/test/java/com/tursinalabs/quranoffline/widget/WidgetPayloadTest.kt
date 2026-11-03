package com.tursinalabs.quranoffline.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetPayloadTest {

    @Test
    fun parsesResponsiveFields() {
        val payload = WidgetPayload.parse(
            """
            {"reflectionLabel":"Renungan minggu ini","reflectionTitle":"Kesulitan",
             "ayahRef":"QS Ash-Sharh 94:5","ayahDeepLink":"quranoffline://read?surah=94&ayah=5",
             "ayahImageMedium":"/x/widget_ayah_m.png","ayahImageLarge":null,
             "hasContinue":true,"continueLabel":"Lanjutkan baca","surahName":"Al-Kahf",
             "continueMeta":"Hal. 297 · Juz 15","continuePercent":49,
             "readDeepLink":"quranoffline://read?resume=1&surah=18&ayah=45"}
            """.trimIndent(),
        )!!
        assertEquals("Lanjutkan baca", payload.continueTitle)
        assertEquals(49, payload.continuePercent)
        assertEquals("", payload.ayahImageLarge)
        assertEquals("quranoffline://read?surah=94&ayah=5", payload.reflectionTapLink)
        assertTrue(payload.hasReflection)
    }

    @Test
    fun legacyPayloadFallsBackToSafeLinks() {
        val payload = WidgetPayload.parse("""{"readDeepLink":"quranoffline://home","continuePercent":null}""")!!
        assertEquals(WidgetPayload.DEFAULT_READ_LINK, payload.readDeepLink)
        assertEquals(WidgetPayload.DEFAULT_REFLECTION_LINK, payload.reflectionTapLink)
        assertEquals(-1, payload.continuePercent)
        assertFalse(payload.hasReflection)
    }

    @Test
    fun missingOrBrokenPayloadIsNull() {
        assertNull(WidgetPayload.parse(null))
        assertNull(WidgetPayload.parse("not json"))
    }
}
