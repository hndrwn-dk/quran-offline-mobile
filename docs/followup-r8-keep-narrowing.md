# Follow-up: R8 keep narrowing

Status: **not applied yet**. Task 3 (explicit minify + `proguard-rules.pro`) is on
hold until device testing of the notification Gson path and a clean rebuild that
includes Task 2. This note captures the keep inventory so we do not re-litigate
it when Task 3 unblocks.

## (a) Keeps that remain (justified)

These are the only app-owned keeps approved for `android/app/proguard-rules.pro`
when Task 3 lands. Each is named in `AndroidManifest.xml` or instantiated
reflectively; R8 cannot prove use from a static call graph alone.

| Keep target | Why |
|-------------|-----|
| `com.tursinalabs.quranoffline.widget.QuranBerandaWidgetReceiver` | AppWidget provider `receiver` in the manifest; Glance/home_widget instantiates via reflection. Without a keep, the widget can die silently in release. |
| `com.tursinalabs.quranoffline.widget.QuranBerandaWidget` | Paired GlanceAppWidget class referenced from the receiver; same reflective path. |
| `com.tursinalabs.quranoffline.notifications.WeeklyReminderBootReceiver` | Manifest receiver for `BOOT_COMPLETED` / `MY_PACKAGE_REPLACED`; patches the flutter_local_notifications cache then forwards to the plugin boot receiver. |
| `com.tursinalabs.quranoffline.notifications.PluginScheduledNotificationCache` | Called from the boot receiver; must survive shrinking so upgrade/boot reschedule still patches cache rows. |

No JSON / `tl_tj` / Dart `fromJson` keeps: that path is Dart `jsonDecode`, not JVM
reflection. R8 never sees it.

## (b) Dropped after consumer-rules / reachability check

Inspected AAR / plugin artifacts (not app-level sample ProGuard files).
Versions below re-resolved on the current toolchain (AGP **8.11.1**, Gradle
**8.14**) via `:app:dependencies --configuration releaseRuntimeClasspath` for
the versionCode **46** release build — same coordinates as under AGP 8.9.1
(no shift):

| Proposed keep (earlier draft) | Disposition | Evidence |
|-------------------------------|-------------|----------|
| `com.google.android.play.core.integrity.**` | **Dropped** | `com.google.android.play:integrity:1.4.0` AAR ships **no** `proguard.txt`. Keep still unnecessary: `MainActivity` calls `IntegrityManagerFactory` / `IntegrityTokenRequest` directly, so R8 sees the graph. |
| `androidx.media.**` / `android.support.v4.media.**` (blanket) | **Dropped** | `androidx.media:media:1.7.0` embeds `proguard.txt` keeping Parcelable `Creator`s (also present in this build’s merged R8 config). |
| media3 / ExoPlayer renderer / MediaSource factories | **Dropped** (never add) | `androidx.media3:media3-exoplayer:1.4.1` (+ common/extractor/datasource) embed `proguard.txt` for reflective constructors. `just_audio` pulls media3; no app-level keep. |
| Dart model / `tl_tj` / Gson TypeToken for Quran JSON | **Dropped** | Not JVM. |

`flutter_local_notifications` 20.x: plugin docs say app ProGuard samples are not
required for v19+. We still keep **our** boot receiver and cache helper (above).

## (c) Still unsure — pending device testing / Task 3

| Item | Why unsure |
|------|------------|
| `-keep class com.ryanheise.audioservice.** { *; }` | `audio_service` 0.18.18 declares **no** `consumerProguardFiles`. Manifest registers `AudioService` + `MediaButtonReceiver`, so a keep is plausible — but width is broad. Confirm after release-build audio: notification tap, resume after process death, media buttons. Narrow only with evidence. |
| Explicit `isMinifyEnabled` / `isShrinkResources` in app `build.gradle.kts` | Flutter Gradle plugin already enables both for release and wires `proguard-android-optimize.txt`. Re-setting them alone should not change bytecode; keep as documentation-only if we add them. |
| Whether `isShrinkResources` can strip Glance `res/xml` | Expected safe: manifest `android:resource="@xml/quran_beranda_widget_info"` keeps the provider XML. Still verify widget after first optimized release build. |
| Notification Gson vs JSONObject fallback | Separate from keep narrowing, but blocks shipping confidence: see device test plan (logcat Gson path; upgrade path via `MY_PACKAGE_REPLACED`). |

Do **not** add `android.enableR8.fullMode` flags in this follow-up. Re-verified on
the current tree/AAB (AGP **8.11.1**, R8 **8.11.18** from
`BUNDLE-METADATA/com.android.tools/r8.json`): `isProGuardCompatibilityModeEnabled`
is `false` (full mode), and `android/gradle.properties` does **not** set
`android.enableR8.fullMode=false`. Docs still describe full mode as the AGP 8.0+
default; this build matches that.

## (d) Open question: what Play’s “R8 optimization” tip keys on

It is **not** a boolean “is minify enabled?” check. Play’s technical quality
docs measure **DEX optimization coverage** (shrinking / obfuscation /
optimization percentages) and will require **≥ 25% each** for apps with
non-negligible DEX (**> 10 MB**) from February 2027:

- https://support.google.com/googleplay/android-developer/answer/17492799

**Measured DEX size (this release AAB, versionCode 46):** uncompressed
`base/dex/classes.dex` + `base/dex/classes2.dex` = **3,328,932 bytes
(~3.17 MiB)**. That is **below** the 10 MB app DEX floor, so the Feb 2027
minimum-coverage mandate likely **does not apply** to this binary (QPC V2 page
fonts are Flutter assets, not DEX). Soft Console tips may still appear.

Soft Console recommendations push deeper R8 effectiveness (narrower keeps,
optimize config, avoid opting out of full mode), not merely flipping
`isMinifyEnabled`. Flutter already minifies release with
`proguard-android-optimize.txt`. Re-declaring minify without changing keep
surface or DEX composition is unlikely to clear the tip by itself.

See also:

- https://developer.android.com/topic/performance/app-optimization/enable-app-optimization
- https://android-developers.googleblog.com/2025/11/use-r8-to-shrink-optimize-and-fast.html

## Out of scope for this follow-up

- Do not narrow keeps until device tests pass.
- Do not touch any vendored flutter_local_notifications receiver patch.
- Edge-to-edge (`AudioServiceFragmentActivity` + `EdgeToEdge.enable`) is a
  separate task; not part of R8 narrowing.
- Flutter 3.47 toolchain bumps (Gradle / AGP / Kotlin) ship as their own change;
  do not fold them into the bitmap/R8 Play-fix release.
