# Follow-up: ANR input dispatch on 1.0.5+45

Status: **pending review — not fixed.** Documented only. Do not treat this as
closed by the 1.0.5+46 AAB, and do not fold a speculative fix into AI Search.

Play Console (ANR, last seen ~20 days before 21 Sep 2026):

| Field | Value |
|-------|--------|
| Issue | `[split_config.arm64_v8a.apk!libflutter.so] flutter::PlatformViewAndroidJNIImpl` |
| Type | ANR |
| Message | `input dispatching timed out` |
| Native frame | `FlutterViewHandlePlatformMessage` |
| Affected version | **45 (1.0.5)** — 1 event, 1 user |
| Currently available | Affects **0** versions currently available for download |
| Previously available | Affects **1** version previously available for download |

## What the stack actually means

The C++ class name is Flutter's Android embedding (`FlutterView`), **not** a
Dart `AndroidView` / platform-view widget. This app has no `AndroidView` /
`PlatformView` widgets.

`FlutterViewHandlePlatformMessage` is the JNI path that delivers **any**
platform-channel message. Combined with Android's input-dispatch ANR, it means
the UI thread did not process input for ~5s while a platform message was in
flight. The Console snippet does **not** name the plugin or Dart caller
(share, notifications, audio, Play Integrity, etc.).

## What +45 / +46 did and did not change

| Build | Change | Relation to this ANR |
|-------|--------|----------------------|
| 1.0.5+45 (`e6fd36e`) | Verse share is plain text; live path no longer captures a PNG card | Could reduce share-related stalls, but Vitals still attributes this cluster to **+45** |
| 1.0.5+46 (`8ba2edc`) | Decode splash / nav / explore icons at display size (`cacheWidth` / `ResizeImage`); smaller explore PNGs | May reduce UI-thread bitmap work. **Not** a targeted `FlutterViewHandlePlatformMessage` fix |
| 1.0.5+46 tip (`1fe1034`) | Edge-to-edge `FragmentActivity` experiments reverted | Unrelated to this stack |
| R8 keep-narrowing | Still **not applied** (`docs/followup-r8-keep-narrowing.md`) | Unrelated |

No commit, QA checklist, or release note mentions this ANR or that JNI method.

Play's "0 versions currently available" is **absence of new reports** on the
live store binary (if that binary is +46), not proof of a fix. One event is too
thin to close.

## Open for review

1. Pull a fuller native main-thread stack from this Console issue (what the
   thread was doing besides `FlutterViewHandlePlatformMessage`).
2. Confirm whether +46 is the version currently served. If a new event appears
   on +46, this is still open.
3. Do **not** change production code from this note alone. A real fix needs a
   named plugin/call site or a second event.

## Out of scope

- AI Search (`feat/ai-search*`)
- Recalibrating reflection tests (Items A–C)
- Uploading / promoting an AAB
