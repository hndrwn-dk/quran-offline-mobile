# Backup for reversion (v1.0.0+7)

This folder holds copies of code **before** the v1.0.0+7 changes so you can revert easily if needed.

## What changed in 1.0.0+7

- **Tajweed rendering fix**: Arabic diacritics (fatḥah, kasrah, dammah, madda) were sometimes missing or overlapping when Tajweed was enabled. The fix merges leading combining characters into the previous `TextSpan` so Flutter lays them out correctly.
- **Version**: `pubspec.yaml` set to `1.0.0+7`.

## How to revert the Tajweed fix only

To go back to the pre-fix Tajweed widget (e.g. for testing or rollback):

1. Copy the backup file over the current widget:
   ```bash
   cp backup/tajweed_text_pre_1.0.0+7.dart lib/core/widgets/tajweed_text.dart
   ```
   On Windows (PowerShell):
   ```powershell
   Copy-Item backup\tajweed_text_pre_1.0.0+7.dart lib\core\widgets\tajweed_text.dart -Force
   ```

2. Run the app. Tajweed will use the old behavior (possible diacritic overlap/missing).

## How to revert the whole release (version + code)

- Use git: create a tag before releasing (e.g. `git tag v1.0.0+6`) so you can `git checkout v1.0.0+6` or `git revert` to that state.
- Or restore from your own backup of the repo.

## Files in this backup

| File | Description |
|------|-------------|
| `tajweed_text_pre_1.0.0+7.dart` | `TajweedText` widget without the diacritic merge logic (pre-fix). |
| `README.md` | This file. |
