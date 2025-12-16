# Testing and Deployment Guide

This guide covers testing the Quran Offline app on Android and iOS, and submitting it to the Play Store and App Store.

## Prerequisites

1. **Flutter SDK** installed and configured
2. **Android Studio** (for Android development)
3. **Xcode** (for iOS development, macOS only)
4. **Developer Accounts**:
   - Google Play Console account ($25 one-time fee)
   - Apple Developer Program account ($99/year)

## Testing on Android

### 1. Set Up Android Emulator

```bash
# List available emulators
flutter emulators

# Launch an emulator
flutter emulators --launch <emulator_id>

# Or use Android Studio:
# Tools > Device Manager > Create Virtual Device
```

### 2. Test on Physical Android Device

1. Enable **Developer Options** on your Android device:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
2. Enable **USB Debugging**:
   - Settings > Developer Options > USB Debugging
3. Connect device via USB
4. Verify connection:
```bash
flutter devices
```

### 3. Run the App

```bash
# Debug mode (hot reload enabled)
flutter run

# Release mode (optimized)
flutter run --release

# Profile mode (performance testing)
flutter run --profile
```

### 4. Test Checklist

- [ ] App launches without crashes
- [ ] Data imports successfully on first launch
- [ ] All reading modes work (Surah/Juz/Pages)
- [ ] Reader displays verses correctly
- [ ] Bookmarks save and load
- [ ] Search functionality works
- [ ] Settings persist after app restart
- [ ] Text scaling works
- [ ] Share functionality works
- [ ] App works offline (disable WiFi/data)
- [ ] Dark mode works correctly
- [ ] Tablet layout works (if testing on tablet)

## Testing on iOS

### 1. Set Up iOS Simulator

```bash
# List available simulators
xcrun simctl list devices

# Open Simulator
open -a Simulator

# Or use Xcode:
# Xcode > Open Developer Tool > Simulator
```

### 2. Test on Physical iOS Device

1. Connect iPhone/iPad via USB
2. Open Xcode
3. Select your device in the device dropdown
4. Trust the computer on your device if prompted

### 3. Configure Signing

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to "Signing & Capabilities"
4. Select your Team (Apple Developer account)
5. Xcode will automatically manage provisioning

### 4. Run the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Profile mode
flutter run --profile
```

### 5. iOS-Specific Testing

- [ ] App launches on iOS
- [ ] SafeArea respects notch/home indicator
- [ ] Text rendering is correct
- [ ] Share sheet works
- [ ] App respects iOS accessibility settings
- [ ] Test on different iOS versions (if possible)

## Building Release Versions

### Android Release Build

#### 1. Configure App Signing

Create `android/key.properties`:
```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=<your-key-alias>
storeFile=<path-to-your-keystore.jks>
```

#### 2. Generate Keystore (if you don't have one)

```bash
keytool -genkey -v -keystore ~/quran-offline-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias quran-offline
```

#### 3. Update `android/app/build.gradle`

Add before `android {`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Update `android {` block:
```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### 4. Build App Bundle (for Play Store)

```bash
flutter build appbundle
```

Output: `build/app/outputs/bundle/release/app-release.aab`

#### 5. Build APK (for direct installation)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS Release Build

> 📱 **For detailed iOS build instructions**, see [IOS_BUILD_AND_APP_STORE.md](IOS_BUILD_AND_APP_STORE.md) - Complete guide from setup to App Store submission.

**Quick Build Commands:**
```bash
# Build for release
flutter build ios --release

# Build IPA
flutter build ipa
```

**Archive in Xcode:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" as target
3. Product > Archive
4. Distribute App > App Store Connect

For step-by-step instructions including version configuration, app icons, signing, and troubleshooting, see: **[IOS_BUILD_AND_APP_STORE.md](IOS_BUILD_AND_APP_STORE.md)**

## Google Play Store Submission

> 📱 **For detailed Android build and Play Store deployment guide**, see [ANDROID_BUILD_AND_PLAY_STORE.md](ANDROID_BUILD_AND_PLAY_STORE.md) - A comprehensive step-by-step guide from installing requirements to submitting to Play Store, perfect for beginners.

### Quick Reference

**Build Android App:**
```bash
flutter build appbundle --release
```

**Play Console:**
- Create app at [Google Play Console](https://play.google.com/console)
- Upload App Bundle (.aab file)
- Complete store listing, content rating, and privacy policy
- Submit for review

For complete detailed instructions including:
- Installing Java, Android Studio, Flutter
- Setting up Android development environment
- Configuring app signing and keystore
- Building and testing on emulator/device
- Registering Google Play Console account
- Preparing Play Store assets
- Uploading and submitting to Play Store

See: **[ANDROID_BUILD_AND_PLAY_STORE.md](ANDROID_BUILD_AND_PLAY_STORE.md)**

## Apple App Store Submission

> 📱 **For detailed iOS build and App Store deployment guide**, see [IOS_BUILD_AND_APP_STORE.md](IOS_BUILD_AND_APP_STORE.md) - A comprehensive step-by-step guide from installing requirements to submitting to App Store, perfect for beginners.

### Quick Reference

**Build iOS App:**
```bash
flutter build ios --release
flutter build ipa
```

**Archive in Xcode:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" as target
3. Product > Archive
4. Distribute App > App Store Connect

**App Store Connect:**
- Create app at [App Store Connect](https://appstoreconnect.apple.com)
- Upload build via Xcode Organizer or Transporter
- Fill app information and submit for review

For complete detailed instructions including:
- Installing macOS, Xcode, Flutter, CocoaPods
- Setting up iOS development environment
- Configuring app signing and capabilities
- Building and testing on simulator/device
- Registering Apple Developer account
- Preparing App Store assets
- Uploading and submitting to App Store

See: **[IOS_BUILD_AND_APP_STORE.md](IOS_BUILD_AND_APP_STORE.md)**

## Testing Checklist Before Submission

### Android
- [ ] App bundle builds successfully
- [ ] App installs on test device
- [ ] All features work in release mode
- [ ] App icon displays correctly
- [ ] App name is correct
- [ ] Version number is correct
- [ ] No debug code left in
- [ ] ProGuard rules configured (if needed)

### iOS
- [ ] App builds and archives successfully
- [ ] App installs on test device
- [ ] All features work in release mode
- [ ] App icon displays correctly
- [ ] App name is correct
- [ ] Version number is correct
- [ ] No debug code left in
- [ ] Info.plist configured correctly
- [ ] Privacy permissions declared (if any)

## Common Issues

### Android

**Issue:** App bundle too large
**Solution:** Enable ProGuard, remove unused resources:
```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
    }
}
```

**Issue:** Signing errors
**Solution:** Verify `key.properties` path and passwords

### iOS

**Issue:** Code signing errors
**Solution:** 
- Check Team selection in Xcode
- Ensure certificates are valid
- Clean build folder (Cmd+Shift+K)

**Issue:** Archive fails
**Solution:**
- Check deployment target (iOS 12.0+)
- Verify all dependencies support iOS
- Check for deprecated APIs

## Post-Submission

### Play Store
- Monitor crash reports in Play Console
- Respond to user reviews
- Update app regularly
- Monitor analytics (if enabled)

### App Store
- Monitor TestFlight feedback
- Respond to App Review feedback
- Update app regularly
- Monitor App Store Connect analytics

## Version Updates

When updating:
1. Increment version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # version+buildNumber
   ```
2. Update iOS version in Xcode
3. Build new release
4. Upload to stores
5. Add release notes

## Resources

- [Flutter Deployment Guide](https://docs.flutter.dev/deployment)
- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Play Store Policies](https://play.google.com/about/developer-content-policy/)

