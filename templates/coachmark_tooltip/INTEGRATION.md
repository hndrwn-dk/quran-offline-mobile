# Integration Guide

## 1. Dependencies

```yaml
# pubspec.yaml
dependencies:
  shared_preferences: ^2.2.2
```

---

## 2. Copy files

```
templates/coachmark_tooltip/lib/  →  your_app/lib/core/coachmark/
```

Rename `feature_coachmark_template.dart` to match your feature, e.g. `support_coachmark.dart`.

---

## 3. Increment app open count (once per cold start)

```dart
// splash_screen.dart or main app initializer
import 'package:your_app/core/coachmark/app_open_counter.dart';

Future<void> _initializeApp() async {
  await AppOpenCounter.increment(); // do this before navigating to home
  // ... rest of init
}
```

Do **not** increment on every screen visit — only cold start.

---

## 4. Configure your feature coachmark

```dart
// lib/core/coachmark/support_coachmark.dart
import 'package:flutter/material.dart';
import 'coachmark_overlay.dart';
import 'coachmark_storage_keys.dart';
import 'staged_coachmark_service.dart';

/// Adjust prefix, thresholds, and copy for your app.
const _config = CoachmarkConfig(
  keys: CoachmarkStorageKeys(prefix: 'support_coachmark'),
  firstShowMinAppOpens: 3,
  maxShowCount: 3,
  reminderDelays: [
    Duration(days: 7),
    Duration(days: 14),
  ],
);

class SupportCoachmark {
  SupportCoachmark._();

  static final _service = StagedCoachmarkService(config: _config);

  static Future<void> maybeShow({
    required BuildContext context,
    required GlobalKey targetKey,
    required VoidCallback onCta,
  }) async {
    if (!await _service.shouldShow()) return;
    if (!context.mounted) return;

    await _service.recordShown();
    if (!context.mounted) return;

    CoachmarkOverlay.show(
      context: context,
      targetKey: targetKey,
      title: 'Enjoying the app?',
      body: 'Support development here. Free forever, no ads.',
      dismissLabel: 'Later',
      ctaLabel: 'View',
      onDismiss: () {},
      onCta: () async {
        await _service.recordCtaTapped();
        onCta();
      },
    );
  }
}
```

---

## 5. Wire target widget on home screen

```dart
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _donateIconKey = GlobalKey();
  bool _coachmarkScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowCoachmark());
  }

  Future<void> _maybeShowCoachmark() async {
    if (_coachmarkScheduled || !mounted) return;
    _coachmarkScheduled = true;

    await SupportCoachmark.maybeShow(
      context: context,
      targetKey: _donateIconKey,
      onCta: () => launchUrl(Uri.parse('https://ko-fi.com/your-page')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: _donateIconKey, // REQUIRED — overlay anchors here
            icon: const Icon(Icons.volunteer_activism_outlined),
            onPressed: () => launchUrl(...),
          ),
        ],
      ),
      body: ...,
    );
  }
}
```

**Why `postFrameCallback`?** The target widget must be laid out so `GlobalKey` can resolve screen position.

**Why `_coachmarkScheduled`?** Prevents double-show if `build` triggers multiple callbacks.

---

## 6. Multiple coachmarks in one app

| Feature | Prefix | Overlay |
|---------|--------|---------|
| Support / Ko-fi | `support_coachmark` | `CoachmarkOverlay` |
| Ramadan tracker | `ramadan_coachmark` | same `CoachmarkOverlay` |
| New feature X | `feature_x_coachmark` | same `CoachmarkOverlay` |

Each feature gets its own `CoachmarkConfig` + wrapper class. Shared: `AppOpenCounter`, `CoachmarkOverlay`, painters, style.

---

## 7. Manual QA checklist

- [ ] Fresh install: open 1x, 2x — no coachmark
- [ ] Open 3x — coachmark appears on target icon
- [ ] Tap "Later" / dim area — closes; same session no repeat
- [ ] After 7 days (or mock `lastShownAt`) — 2nd reminder
- [ ] After 14 more days — 3rd (final) reminder
- [ ] After 3 shows — never again
- [ ] Tap CTA anytime — never again + CTA action runs
- [ ] Rotate device / tablet — spotlight still aligns (re-layout on show)

### Debug: reset one coachmark

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.remove('support_coachmark_show_count');
await prefs.remove('support_coachmark_last_shown_at');
await prefs.remove('support_coachmark_has_tapped_cta');
```

---

## 8. Optional: localization

Replace hardcoded strings in your wrapper with your i18n layer:

```dart
title: AppLocalizations.coachmarkTitle(lang),
body: AppLocalizations.coachmarkBody(lang),
dismissLabel: AppLocalizations.later(lang),
ctaLabel: AppLocalizations.view(lang),
```
