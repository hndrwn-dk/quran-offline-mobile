package com.tursinalabs.quranoffline.widget

import org.json.JSONObject

/** Snapshot written by Flutter's HomeWidgetSync (`beranda_payload`). */
data class WidgetPayload(
    val reflectionLabel: String,
    val reflectionTitle: String,
    val reflectionDeepLink: String,
    val reflectionButton: String,
    val ayahRef: String,
    val ayahTranslation: String,
    val ayahPosition: String,
    val ayahDeepLink: String,
    val ayahImageMedium: String,
    val ayahImageLarge: String,
    val hasContinue: Boolean,
    val continueTitle: String,
    val surahName: String,
    val continueMeta: String,
    val continueButton: String,
    val continuePercent: Int,
    val continueDescription: String,
    val continueHint: String,
    val readDeepLink: String,
    /** Differs per sync, so an identical-looking payload still recomposes and reloads the PNGs. */
    val updatedAt: Long,
) {
    val hasReflection: Boolean get() = ayahRef.isNotEmpty() || reflectionTitle.isNotEmpty()

    /** Ayah link when there is one, else the reflection sheet. */
    val reflectionTapLink: String get() = ayahDeepLink.ifEmpty { reflectionDeepLink }

    companion object {
        const val DEFAULT_READ_LINK = "quranoffline://read"
        const val DEFAULT_REFLECTION_LINK = "quranoffline://reflection"

        /** Null when Flutter has not written a payload yet (app never opened). */
        fun parse(raw: String?): WidgetPayload? {
            if (raw.isNullOrBlank()) return null
            return try {
                val json = JSONObject(raw)
                WidgetPayload(
                    reflectionLabel = json.str("reflectionLabel"),
                    reflectionTitle = json.str("reflectionTitle"),
                    reflectionDeepLink = json.str("reflectionDeepLink").ifEmpty { DEFAULT_REFLECTION_LINK },
                    reflectionButton = json.str("reflectionButton"),
                    ayahRef = json.str("ayahRef"),
                    ayahTranslation = json.str("ayahTranslation"),
                    ayahPosition = json.str("ayahPosition"),
                    ayahDeepLink = json.str("ayahDeepLink"),
                    ayahImageMedium = json.str("ayahImageMedium"),
                    ayahImageLarge = json.str("ayahImageLarge"),
                    hasContinue = json.optBoolean("hasContinue", false),
                    continueTitle = json.str("continueTitle").ifEmpty { json.str("continueLabel") },
                    surahName = json.str("surahName"),
                    continueMeta = json.str("continueMeta"),
                    continueButton = json.str("continueButton"),
                    continuePercent = if (json.isNull("continuePercent")) -1 else json.optInt("continuePercent", -1),
                    continueDescription = json.str("continueDescription"),
                    continueHint = json.str("continueHint"),
                    readDeepLink = json.str("readDeepLink").let {
                        // The legacy "home" fallback would only open Beranda; the
                        // read link lands on the Read tab when nothing was read yet.
                        if (it.isEmpty() || it == "quranoffline://home") DEFAULT_READ_LINK else it
                    },
                    updatedAt = json.optLong("updatedAt", 0L),
                )
            } catch (_: Exception) {
                null
            }
        }

        /** optString turns JSON null into "null"; treat it as empty. */
        private fun JSONObject.str(key: String): String =
            if (isNull(key)) "" else optString(key, "")
    }
}
