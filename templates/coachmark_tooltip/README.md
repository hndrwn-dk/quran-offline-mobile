# Coachmark Tooltip — Copy-Paste Template

Reusable Flutter coachmark: dim overlay, spotlight cut-out, pulse ring, tooltip bubble, and **staged reminders** (show up to N times with day-based gaps; stop forever after CTA tap).

**Dependencies:** `shared_preferences` only. No showcase package.

---

## Quick start

1. Copy everything under `lib/` into your project, e.g. `lib/core/coachmark/`.
2. Add `shared_preferences` to `pubspec.yaml` if missing.
3. Customize `YOUR_FEATURE_COACHMARK_CONFIG` in `feature_coachmark_template.dart`.
4. Increment `AppOpenCounter` once per cold start (splash / app init).
5. Attach `GlobalKey` to the target widget and call `FeatureCoachmark.maybeShow()` from `postFrameCallback`.

See [INTEGRATION.md](INTEGRATION.md) for step-by-step wiring.

---

## File map

| File | Role |
|------|------|
| `app_open_counter.dart` | Global cold-start counter |
| `coachmark_storage_keys.dart` | Prefix-based SharedPreferences keys |
| `staged_coachmark_service.dart` | When to show + record shown / CTA |
| `coachmark_style.dart` | Colors, sizes, animation timing |
| `coachmark_spotlight_painter.dart` | Dim overlay with rounded cut-out |
| `coachmark_overlay.dart` | Generic overlay UI (reusable across features) |
| `feature_coachmark_template.dart` | **Copy & rename** per feature |
| `staged_coachmark_service_test.dart` | Unit test examples |

---

## Customize per feature

```dart
// Example: support / donate icon on home header
const supportCoachmarkConfig = CoachmarkConfig(
  keys: CoachmarkStorageKeys(prefix: 'support_coachmark'),
  firstShowMinAppOpens: 3,
  maxShowCount: 3,
  reminderDelays: [
    Duration(days: 7),   // before 2nd show
    Duration(days: 14),  // before 3rd show
  ],
);

// Example: Ramadan tracker — different prefix, same overlay
const ramadanCoachmarkConfig = CoachmarkConfig(
  keys: CoachmarkStorageKeys(prefix: 'ramadan_coachmark'),
  firstShowMinAppOpens: 1,
  maxShowCount: 2,
  reminderDelays: [Duration(days: 3)],
);
```

One `CoachmarkOverlay` widget serves all features; only the **service config** and **wrapper copy/CTA** change.

---

## Trigger logic (reference)

```
if hasTappedCta → STOP
if showCount >= maxShowCount → STOP
if showCount == 0 → show when appOpenCount >= firstShowMinAppOpens
if showCount == 1 → show when now - lastShownAt >= reminderDelays[0]
if showCount == 2 → show when now - lastShownAt >= reminderDelays[1]
...
```

- **Dismiss / tap dim area:** only closes overlay (`recordShown` already ran when displayed).
- **CTA tap:** `recordCtaTapped()` → never show again.

---

## UI tokens (edit in `coachmark_style.dart`)

| Token | Default |
|-------|---------|
| Overlay dim | `rgba(20,26,18,0.55)` |
| Tooltip bg | `#2F3B2B` |
| Tooltip text | `#F6F8F1` |
| Fade duration | 400ms |
| Tooltip delay | 200ms after overlay |

---

## Tests

Copy `staged_coachmark_service_test.dart` to your `test/` folder and run:

```bash
flutter test test/staged_coachmark_service_test.dart
```

Inject `now: () => fixedDate` for deterministic day-threshold tests.
