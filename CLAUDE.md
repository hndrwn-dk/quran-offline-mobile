# Quran Offline: rules for Claude Code

Offline-first Quran app by Tursina Labs. Flutter, Riverpod, Drift, Material 3.
Package: `com.tursinalabs.quranoffline`. Default branch: `main`.

Also follow the scoped rules in `.cursor/rules/` (AI search, Android R8, edge-to-edge).

## Mushaf rendering
- Mushaf uses QPC V2 per-page fonts (604 pages) and the QUL `SurahNameV2` font for surah names. Fonts load per page, so anything that rasterizes a page (snapshots, goldens) must wait for that page's font.
- Phone and Fold cover (window width < 600dp): Mushaf must stay pixel-identical to the current goldens unless I explicitly approve a change.
- Framed mode = width >= 600dp: two-page spread, or one wide single page. Odd page on the RIGHT, even page on the LEFT (1|2, 3|4 ... 603|604).
- Every page is a strict 15-row grid. Pages 1 and 2 have 8 rows and use one shared opening scale.
- Framed focus mode hides the AppBar and system bars (an approved exception to the edge-to-edge rule). Never let a design change shrink the ayah font size; report before/after sizes.

## Colors and copy
- Surah names, end-caps, page numbers, and other structure use `colorScheme.primary`. Quran text uses the ink color (`onSurface`). No hard-coded hex; use theme tokens (light, dark, and sepia must all work).
- Indonesian UI copy uses "kamu", never "Anda".
- Localized strings live in `lib/core/utils/app_localizations.dart` (id, en, zh, ja). There are no ARB files.

## Workflow
- Work on a feature branch from `main`. Small commits. Open a PR and stop for my OK; never merge without it.
- Run `flutter analyze` and `flutter test` before reporting. `scripts/qo.sh` (local, not in git) has `verify` and `apk` helpers when present.
- Never touch `feat/hafalan-setoran`. Never upload anything to Play Console. Never bump the version unless asked.
- Release builds are signed with the upload key; Play-installed builds may not update from a local build. Don't uninstall apps on my devices.

## Device verification
- Devices: Pixel 8 Pro (`3A251FDJG0045D`) and Galaxy Z Fold 8 (wireless adb; ask me for the current address). Fold 8 inner screen is about 933x704dp landscape; cover about 475x751dp.
- For any UI change, install a debug build, capture screenshots with `adb exec-out screencap -p`, LOOK at them yourself, and iterate until they match the spec before reporting.
- Keep the screen awake while capturing (`adb shell svc power stayon true`), and restore it afterwards.
