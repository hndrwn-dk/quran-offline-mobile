# Quick Testing Guide

## Before Testing

1. **Generate required code:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

2. **Verify dependencies:**
```bash
flutter pub get
```

## Testing on Android

### Option 1: Android Emulator

```bash
# List available emulators
flutter emulators

# Launch an emulator (replace with your emulator ID)
flutter emulators --launch Pixel_5_API_33

# Or create one in Android Studio:
# Tools > Device Manager > Create Virtual Device
```

### Option 2: Physical Android Device

1. Enable Developer Options:
   - Settings > About Phone > Tap "Build Number" 7 times
2. Enable USB Debugging:
   - Settings > Developer Options > USB Debugging
3. Connect device via USB
4. Verify connection:
```bash
flutter devices
```

### Run the App

```bash
# Debug mode (with hot reload)
flutter run

# Release mode (optimized, closer to production)
flutter run --release
```

## Testing on iOS

### Option 1: iOS Simulator (macOS only)

```bash
# List available simulators
xcrun simctl list devices

# Open Simulator
open -a Simulator

# Or use Xcode:
# Xcode > Open Developer Tool > Simulator
```

### Option 2: Physical iOS Device (macOS only)

1. Connect iPhone/iPad via USB
2. Open Xcode: `open ios/Runner.xcworkspace`
3. Select your device in the device dropdown
4. Go to "Signing & Capabilities" tab
5. Select your Team (Apple Developer account)
6. Trust the computer on your device if prompted

### Run the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

## Quick Test Checklist

Run through these features to ensure everything works:

- [ ] App launches without crashes
- [ ] Splash screen appears
- [ ] Data imports on first launch (may take a minute)
- [ ] Read tab shows Surah/Juz/Pages options
- [ ] Can navigate to a surah and see verses
- [ ] Can navigate to a juz and see verses
- [ ] Can navigate to a page and see verses
- [ ] Reader displays Arabic text correctly (RTL)
- [ ] Translation appears below Arabic
- [ ] Can toggle transliteration in settings
- [ ] Can bookmark a verse
- [ ] Bookmarks tab shows saved bookmarks
- [ ] Can search for text in translations
- [ ] Search results are clickable
- [ ] Can change language in settings
- [ ] Can adjust font sizes
- [ ] Share button works
- [ ] Dark mode works (if available)
- [ ] App works offline (disable WiFi/data)

## Common Issues

### Android

**Issue:** "No devices found"
**Solution:** 
- Check USB debugging is enabled
- Try different USB cable/port
- Run `adb devices` to verify connection

**Issue:** Build fails
**Solution:**
- Run `flutter clean`
- Run `flutter pub get`
- Check Android SDK is installed

### iOS

**Issue:** Code signing errors
**Solution:**
- Open Xcode: `open ios/Runner.xcworkspace`
- Select Runner target
- Go to "Signing & Capabilities"
- Select your Team
- Ensure "Automatically manage signing" is checked

**Issue:** Simulator not found
**Solution:**
- Install Xcode from App Store
- Run `sudo xcode-select --switch /Applications/Xcode.app`
- Run `sudo xcodebuild -license accept`

## Performance Testing

Test app performance:

```bash
# Profile mode (for performance analysis)
flutter run --profile

# Check app size
flutter build apk --release
# Check: build/app/outputs/flutter-apk/app-release.apk
```

## Debugging

### View Logs

```bash
# Android
flutter logs

# iOS
# Use Xcode console or:
flutter logs
```

### Hot Reload

While app is running:
- Press `r` to hot reload
- Press `R` to hot restart
- Press `q` to quit

## Next Steps

After testing, proceed to:
1. [DEPLOYMENT.md](DEPLOYMENT.md) - For building release versions
2. Create app icons
3. Prepare store listings
4. Build release versions

