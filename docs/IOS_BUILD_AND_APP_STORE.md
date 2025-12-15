# iOS Build & App Store Deployment Guide

Panduan lengkap step-by-step untuk build iOS package dan mendaftarkan ke App Store. Panduan ini dibuat untuk pemula, sangat detail, tidak ada yang terlewat.

---

## 📋 DAFTAR ISI

1. [Prerequisites & Requirements](#1-prerequisites--requirements)
2. [Install macOS & Xcode](#2-install-macos--xcode)
3. [Install Flutter](#3-install-flutter)
4. [Setup iOS Development Environment](#4-setup-ios-development-environment)
5. [Clone & Setup Project](#5-clone--setup-project)
6. [Configure iOS App](#6-configure-ios-app)
7. [Build iOS App](#7-build-ios-app)
8. [Test di Simulator](#8-test-di-simulator)
9. [Test di Physical Device](#9-test-di-physical-device)
10. [Register Apple Developer Account](#10-register-apple-developer-account)
11. [Setup App Store Connect](#11-setup-app-store-connect)
12. [Prepare App Store Assets](#12-prepare-app-store-assets)
13. [Build Archive untuk App Store](#13-build-archive-untuk-app-store)
14. [Upload ke App Store Connect](#14-upload-ke-app-store-connect)
15. [Submit untuk Review](#15-submit-untuk-review)
16. [Troubleshooting](#16-troubleshooting)

---

## 1. PREREQUISITES & REQUIREMENTS

### 1.1 Hardware Requirements

- **Mac Computer** (MacBook, iMac, Mac mini, atau Mac Studio)
  - Minimum macOS Big Sur (11.0) atau lebih baru
  - Recommended: macOS Ventura (13.0) atau lebih baru
  - Minimum 8GB RAM (recommended: 16GB)
  - Minimum 20GB free disk space untuk Xcode dan tools

### 1.2 Software Requirements

- **macOS** (latest stable version)
- **Xcode** (latest version dari App Store)
- **Flutter SDK** (latest stable version)
- **CocoaPods** (dependency manager untuk iOS)
- **Apple Developer Account** (untuk deploy ke App Store)

### 1.3 Account Requirements

- **Apple ID** (gratis, untuk download Xcode)
- **Apple Developer Account** ($99/tahun, untuk publish ke App Store)

---

## 2. INSTALL macOS & XCODE

### 2.1 Pastikan macOS Up-to-Date

1. Klik **Apple Menu** (🍎) di kiri atas
2. Pilih **About This Mac**
3. Klik **Software Update**
4. Install semua update yang tersedia
5. Restart Mac jika diperlukan

### 2.2 Install Xcode dari App Store

1. Buka **App Store** di Mac
2. Search **"Xcode"**
3. Klik **Get** atau **Install**
4. Tunggu download selesai (bisa 10-15GB, butuh waktu lama)
5. Setelah selesai, buka **Xcode** dari Applications
6. Xcode akan meminta install **Additional Components**
   - Klik **Install** dan tunggu selesai
7. Setelah semua selesai, buka **Terminal** dan jalankan:

```bash
xcode-select --install
```

8. Setelah command line tools terinstall, verifikasi:

```bash
xcodebuild -version
```

**Expected output:**
```
Xcode 15.0
Build version 15A240d
```

### 2.3 Accept Xcode License

1. Buka **Terminal**
2. Jalankan:

```bash
sudo xcodebuild -license accept
```

3. Masukkan password Mac Anda

### 2.4 Setup Xcode Command Line Tools Path

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

Verifikasi:

```bash
xcode-select -p
```

**Expected output:**
```
/Applications/Xcode.app/Contents/Developer
```

---

## 3. INSTALL FLUTTER

### 3.1 Download Flutter SDK

1. Buka browser, kunjungi: https://flutter.dev/docs/get-started/install/macos
2. Klik **Download Flutter SDK** (latest stable version)
3. File akan terdownload sebagai `flutter_macos_xxx-stable.zip`

### 3.2 Extract Flutter SDK

1. Buka **Finder**
2. Buka folder **Downloads**
3. Double-click file `flutter_macos_xxx-stable.zip`
4. File akan ter-extract menjadi folder `flutter`

### 3.3 Move Flutter ke Lokasi Permanent

1. Buka **Terminal**
2. Pindahkan folder flutter ke lokasi yang diinginkan (recommended: home directory):

```bash
cd ~/Downloads
mv flutter ~/flutter
```

Atau jika ingin di lokasi lain:

```bash
cd ~/Downloads
mv flutter /Users/YOUR_USERNAME/development/flutter
```

### 3.4 Setup Flutter PATH

1. Buka **Terminal**
2. Edit file `.zshrc` (jika pakai zsh) atau `.bash_profile` (jika pakai bash):

**Untuk zsh (default di macOS Catalina+):**
```bash
nano ~/.zshrc
```

**Untuk bash:**
```bash
nano ~/.bash_profile
```

3. Tambahkan baris berikut di akhir file:

```bash
export PATH="$PATH:$HOME/flutter/bin"
```

4. Save file:
   - Tekan `Ctrl + O` (save)
   - Tekan `Enter` (confirm)
   - Tekan `Ctrl + X` (exit)

5. Reload shell configuration:

**Untuk zsh:**
```bash
source ~/.zshrc
```

**Untuk bash:**
```bash
source ~/.bash_profile
```

6. Verifikasi Flutter terinstall:

```bash
flutter --version
```

**Expected output:**
```
Flutter 3.16.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision xxxxxx
Engine • revision xxxxxx
Tools • Dart 3.2.0 • DevTools 2.25.0
```

### 3.5 Run Flutter Doctor

Jalankan command untuk check semua requirements:

```bash
flutter doctor
```

**Expected output (ideal):**
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.16.0, on macOS 14.0 23A344 darwin-arm64, locale en-US)
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
[✓] Xcode - develop for iOS and macOS (Xcode 15.0)
[✓] Chrome - develop for the web
[✓] Android Studio (version 2023.1)
[✓] VS Code (version 1.84.0)
[✓] Connected device (3 available)
[✓] Network resources
```

Jika ada tanda `[!]` atau `[✗]`, ikuti instruksi yang diberikan Flutter untuk memperbaikinya.

### 3.6 Install CocoaPods

CocoaPods adalah dependency manager untuk iOS projects.

1. Buka **Terminal**
2. Install CocoaPods menggunakan Ruby (sudah built-in di macOS):

```bash
sudo gem install cocoapods
```

3. Masukkan password Mac Anda
4. Tunggu sampai selesai
5. Verifikasi:

```bash
pod --version
```

**Expected output:**
```
1.12.0
```

---

## 4. SETUP iOS DEVELOPMENT ENVIRONMENT

### 4.1 Install iOS Simulator

iOS Simulator sudah termasuk dalam Xcode. Untuk memastikan:

1. Buka **Xcode**
2. Pilih **Xcode > Settings** (atau **Preferences**)
3. Pilih tab **Platforms** (atau **Components**)
4. Pastikan **iOS** terinstall dengan versi terbaru
5. Jika belum, klik **Download** dan tunggu selesai

### 4.2 Setup iOS Simulator dari Command Line

1. Buka **Terminal**
2. List semua available simulators:

```bash
xcrun simctl list devices
```

3. Untuk membuka Simulator:

```bash
open -a Simulator
```

### 4.3 Verify iOS Development Setup

Jalankan Flutter doctor dengan verbose untuk detail:

```bash
flutter doctor -v
```

Pastikan bagian iOS menunjukkan:
```
[✓] Xcode - develop for iOS and macOS (Xcode 15.0)
[✓] CocoaPods version 1.12.0 is installed.
```

---

## 5. CLONE & SETUP PROJECT

### 5.1 Install Git (jika belum ada)

Git biasanya sudah terinstall di macOS. Verifikasi:

```bash
git --version
```

Jika belum ada, install via Xcode Command Line Tools (sudah terinstall di step 2.2) atau download dari: https://git-scm.com/download/mac

### 5.2 Clone Project dari GitHub

1. Buka **Terminal**
2. Navigate ke folder tempat Anda ingin menyimpan project:

```bash
cd ~/Documents
# atau
cd ~/development
```

3. Clone repository:

```bash
git clone https://github.com/YOUR_USERNAME/quran-offline-mobile.git
```

Atau jika menggunakan SSH:

```bash
git clone git@github.com:YOUR_USERNAME/quran-offline-mobile.git
```

4. Masuk ke folder project:

```bash
cd quran-offline-mobile
```

### 5.3 Verify Project Structure

Pastikan struktur project benar:

```bash
ls -la
```

**Expected structure:**
```
lib/
ios/
android/
pubspec.yaml
README.md
...
```

### 5.4 Install Flutter Dependencies

1. Masih di folder project, jalankan:

```bash
flutter pub get
```

2. Tunggu sampai selesai. Output akan menunjukkan:
```
Running "flutter pub get" in quran-offline-mobile...
Resolving dependencies...
Got dependencies!
```

### 5.5 Install iOS Dependencies (CocoaPods)

1. Masuk ke folder iOS:

```bash
cd ios
```

2. Install pods:

```bash
pod install
```

3. Tunggu sampai selesai. Output akan menunjukkan:
```
Analyzing dependencies
Downloading dependencies
Installing ...
Pod installation complete!
```

4. Kembali ke root project:

```bash
cd ..
```

---

## 6. CONFIGURE iOS APP

### 6.1 Update Bundle Identifier

1. Buka **Xcode**
2. File > Open
3. Navigate ke folder project, pilih file `ios/Runner.xcworkspace` (BUKAN `.xcodeproj`)
4. Klik **Open**
5. Di sidebar kiri, klik **Runner** (project name)
6. Pilih target **Runner** di bagian **TARGETS**
7. Pilih tab **Signing & Capabilities**
8. Ubah **Bundle Identifier** menjadi:
   ```
   com.tursinalabs.quranoffline
   ```

### 6.2 Update Display Name

1. Masih di Xcode, pilih tab **General**
2. Di bagian **Identity**, ubah **Display Name**:
   ```
   Quran Offline
   ```

### 6.3 Update Version & Build Number

1. Masih di tab **General**
2. Di bagian **Identity**:
   - **Version**: `1.0.0` (atau sesuai versi app)
   - **Build**: `1` (increment setiap kali upload ke App Store)

### 6.4 Update Info.plist

1. Di sidebar Xcode, expand **Runner** folder
2. Klik file **Info.plist**
3. Pastikan atau update values berikut:

```xml
<key>CFBundleDisplayName</key>
<string>Quran Offline</string>

<key>CFBundleName</key>
<string>Quran Offline</string>

<key>CFBundleIdentifier</key>
<string>com.tursinalabs.quranoffline</string>

<key>CFBundleVersion</key>
<string>1</string>

<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
```

### 6.5 Configure App Icons

1. Di Xcode sidebar, klik **Assets.xcassets**
2. Klik **AppIcon**
3. Drag & drop icon images ke slot yang sesuai:
   - **20x20** (iPhone Notification)
   - **29x29** (iPhone Settings)
   - **40x40** (iPhone Spotlight)
   - **60x60** (iPhone App)
   - **1024x1024** (App Store)

**Note:** Icon harus dalam format PNG, tanpa alpha channel untuk 1024x1024.

### 6.6 Configure Launch Screen

1. Di Xcode sidebar, klik **Assets.xcassets**
2. Klik **LaunchImage** (atau buat LaunchScreen.storyboard)
3. Set background color sesuai app theme
4. Atau gunakan splash screen yang sudah dikonfigurasi di Flutter

---

## 7. BUILD iOS APP

### 7.1 Clean Previous Builds

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

### 7.2 Build untuk Simulator

1. Pastikan Simulator sudah terbuka:

```bash
open -a Simulator
```

2. List available devices:

```bash
flutter devices
```

3. Build dan run:

```bash
flutter run
```

Atau build saja tanpa run:

```bash
flutter build ios --simulator
```

### 7.3 Build untuk Physical Device

1. Connect iPhone/iPad ke Mac via USB
2. Trust computer di device jika diminta
3. Unlock device
4. Di Xcode, pilih device dari dropdown di toolbar
5. Build:

```bash
flutter build ios --release
```

Atau build via Xcode:
1. Buka `ios/Runner.xcworkspace` di Xcode
2. Pilih device dari dropdown
3. Product > Build (⌘B)

---

## 8. TEST DI SIMULATOR

### 8.1 Open Simulator

```bash
open -a Simulator
```

### 8.2 Pilih Device

Di Simulator menu:
- **File > Open Simulator > iPhone 15 Pro** (atau device lain)

### 8.3 Run App

```bash
flutter run
```

Atau dari Xcode:
1. Buka `ios/Runner.xcworkspace`
2. Pilih simulator dari dropdown
3. Klik **Run** button (▶️) atau tekan ⌘R

### 8.4 Test Features

Test semua fitur app:
- ✅ Splash screen
- ✅ Data import
- ✅ Read mode (Surah, Juz, Mushaf)
- ✅ Search
- ✅ Bookmarks
- ✅ Settings
- ✅ Text settings
- ✅ Theme switching

---

## 9. TEST DI PHYSICAL DEVICE

### 9.1 Connect Device

1. Connect iPhone/iPad ke Mac via USB
2. Unlock device
3. Trust computer jika diminta

### 9.2 Setup Provisioning Profile (Free Apple ID)

1. Buka **Xcode**
2. Buka `ios/Runner.xcworkspace`
3. Pilih **Runner** project di sidebar
4. Pilih target **Runner**
5. Tab **Signing & Capabilities**
6. Centang **Automatically manage signing**
7. Pilih **Team** (Apple ID Anda)
8. Xcode akan otomatis membuat provisioning profile

### 9.3 Run di Device

1. Pilih device dari dropdown di Xcode toolbar
2. Klik **Run** (▶️) atau tekan ⌘R
3. Tunggu build selesai
4. App akan terinstall dan launch di device

**Atau via command line:**

```bash
flutter devices
flutter run -d <device-id>
```

### 9.4 Trust Developer Certificate (First Time)

Jika ini pertama kali install app dari Mac ini:
1. Di iPhone, buka **Settings > General > VPN & Device Management**
2. Tap **Developer App** (nama Apple ID Anda)
3. Tap **Trust**
4. Tap **Trust** lagi untuk konfirmasi

---

## 10. REGISTER APPLE DEVELOPER ACCOUNT

### 10.1 Create Apple ID (jika belum ada)

1. Buka browser, kunjungi: https://appleid.apple.com/
2. Klik **Create Your Apple ID**
3. Isi form:
   - First Name
   - Last Name
   - Email (gunakan email yang valid)
   - Password (min 8 karakter, kombinasi huruf/angka/simbol)
   - Security Questions
   - Phone Number
4. Verifikasi email dan phone number
5. Selesai

### 10.2 Enroll Apple Developer Program

1. Buka browser, kunjungi: https://developer.apple.com/programs/
2. Klik **Enroll**
3. Sign in dengan Apple ID Anda
4. Pilih entity type:
   - **Individual** (untuk personal)
   - **Organization** (untuk company)
5. Isi informasi yang diperlukan
6. Agree to License Agreement
7. **Payment**: $99 USD per tahun
8. Tunggu approval (biasanya 24-48 jam)

### 10.3 Verify Enrollment

1. Kunjungi: https://developer.apple.com/account/
2. Sign in dengan Apple ID
3. Pastikan status menunjukkan **Active**

---

## 11. SETUP APP STORE CONNECT

### 11.1 Access App Store Connect

1. Buka browser, kunjungi: https://appstoreconnect.apple.com/
2. Sign in dengan Apple Developer Account
3. Klik **My Apps**

### 11.2 Create New App

1. Klik **+** button di kiri atas
2. Pilih **New App**
3. Fill form:
   - **Platform**: iOS
   - **Name**: Quran Offline
   - **Primary Language**: English (atau sesuai)
   - **Bundle ID**: com.tursinalabs.quranoffline
   - **SKU**: quran-offline-ios (unique identifier, bisa apa saja)
4. Klik **Create**

### 11.3 Fill App Information

1. **App Information** tab:
   - **Category**: Books / Reference
   - **Privacy Policy URL**: (jika ada)
   - **Subtitle**: Read by Surah, Juz & Pages

2. **Pricing and Availability**:
   - **Price**: Free
   - **Availability**: All countries (atau pilih specific)

3. **App Privacy**:
   - Klik **Get Started**
   - Answer questions tentang data collection
   - Untuk app ini (offline-first), biasanya **No data collected**

---

## 12. PREPARE APP STORE ASSETS

### 12.1 App Screenshots

Siapkan screenshots untuk berbagai device sizes:

**Required sizes:**
- iPhone 6.7" (iPhone 14 Pro Max): 1290 x 2796 pixels
- iPhone 6.5" (iPhone 11 Pro Max): 1242 x 2688 pixels
- iPhone 5.5" (iPhone 8 Plus): 1242 x 2208 pixels

**Cara ambil screenshot:**
1. Run app di Simulator dengan device size yang sesuai
2. Tekan **⌘ + S** untuk screenshot
3. Screenshot akan tersimpan di Desktop
4. Edit jika perlu (crop, add frames, dll)

**Jumlah screenshot:**
- Minimum: 3 screenshots per device size
- Recommended: 5-10 screenshots

### 12.2 App Icon

- Size: 1024 x 1024 pixels
- Format: PNG atau JPEG
- No transparency
- No rounded corners (Apple akan otomatis round)

### 12.3 App Preview Video (Optional)

- Format: MP4 atau MOV
- Duration: 15-30 seconds
- Size: sesuai device size
- Showcase main features

### 12.4 App Description

Siapkan text untuk:
- **Name**: Quran Offline
- **Subtitle**: Read by Surah, Juz & Pages
- **Description**: 
  ```
  Read the Quran offline by Surah, Juz, or Page with translation.
  
  Features:
  - Read by Surah, Juz, or Mushaf (Page) mode
  - Offline-first: All content available without internet
  - Multiple translations
  - Bookmarks
  - Search functionality
  - Material 3 design
  - Dark mode support
  ```
- **Keywords**: quran, qur'an, islam, offline, reading, surah, juz
- **Support URL**: (jika ada website)
- **Marketing URL**: (optional)

### 12.5 Upload Assets ke App Store Connect

1. Di App Store Connect, pilih app **Quran Offline**
2. Pilih versi **1.0** (atau versi yang sesuai)
3. Scroll ke **App Store Listing**
4. Upload screenshots untuk setiap device size
5. Upload app icon
6. Fill description, keywords, dll
7. Klik **Save**

---

## 13. BUILD ARCHIVE UNTUK APP STORE

### 13.1 Update Version & Build Number

1. Buka **Xcode**
2. Buka `ios/Runner.xcworkspace`
3. Pilih **Runner** project
4. Pilih target **Runner**
5. Tab **General**:
   - **Version**: `1.0.0`
   - **Build**: `1` (increment setiap upload)

### 13.2 Configure Signing & Capabilities

1. Tab **Signing & Capabilities**
2. Pilih **Team** (Apple Developer Team Anda)
3. Pastikan **Automatically manage signing** tercentang
4. Pastikan **Bundle Identifier** benar: `com.tursinalabs.quranoffline`

### 13.3 Select Generic iOS Device

1. Di Xcode toolbar, klik device dropdown
2. Pilih **Any iOS Device** atau **Generic iOS Device**
3. **PENTING**: Jangan pilih simulator atau physical device

### 13.4 Create Archive

1. Menu: **Product > Archive**
2. Tunggu build selesai (bisa beberapa menit)
3. Window **Organizer** akan terbuka otomatis
4. Archive akan muncul di list

### 13.5 Validate Archive

1. Di Organizer window, pilih archive yang baru dibuat
2. Klik **Validate App**
3. Pilih **Automatically manage signing**
4. Klik **Next**
5. Tunggu validation selesai
6. Jika ada error, fix dulu sebelum upload

### 13.6 Distribute App

1. Masih di Organizer, pilih archive
2. Klik **Distribute App**
3. Pilih **App Store Connect**
4. Klik **Next**
5. Pilih **Upload**
6. Klik **Next**
7. Pilih **Automatically manage signing**
8. Klik **Next**
9. Review summary
10. Klik **Upload**
11. Tunggu upload selesai (bisa beberapa menit)

**Atau via command line:**

```bash
flutter build ipa --release
```

File `.ipa` akan ada di `build/ios/ipa/`

---

## 14. UPLOAD KE APP STORE CONNECT

### 14.1 Via Xcode Organizer (Recommended)

1. Setelah archive dibuat (step 13.6)
2. Di Organizer, pilih archive
3. Klik **Distribute App**
4. Ikuti wizard sampai upload selesai

### 14.2 Via Transporter App

1. Download **Transporter** dari Mac App Store
2. Open Transporter
3. Sign in dengan Apple Developer Account
4. Drag & drop file `.ipa` ke Transporter
5. Klik **Deliver**
6. Tunggu upload selesai

### 14.3 Via Command Line (altool)

```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/quran_offline.ipa \
  --username YOUR_APPLE_ID \
  --password YOUR_APP_SPECIFIC_PASSWORD
```

**Note:** App-specific password dibuat di: https://appleid.apple.com/account/manage

### 14.4 Verify Upload

1. Buka **App Store Connect**
2. Pilih app **Quran Offline**
3. Klik **TestFlight** tab
4. Tunggu processing selesai (bisa 10-30 menit)
5. Build akan muncul di **Builds** section

---

## 15. SUBMIT UNTUK REVIEW

### 15.1 Select Build

1. Di App Store Connect, pilih app
2. Klik versi **1.0** (atau versi yang sesuai)
3. Scroll ke **Build** section
4. Klik **+** untuk select build
5. Pilih build yang sudah di-upload
6. Klik **Done**

### 15.2 Fill Version Information

1. **What's New in This Version**:
   ```
   Initial release of Quran Offline.
   
   Features:
   - Read Quran by Surah, Juz, or Mushaf (Page) mode
   - Offline-first: All content available without internet
   - Multiple translations
   - Bookmarks
   - Search functionality
   - Material 3 design
   - Dark mode support
   ```

2. **App Review Information**:
   - **Contact Information**: Email Anda
   - **Phone**: Phone number
   - **Demo Account**: (jika diperlukan, untuk app ini tidak perlu)
   - **Notes**: (optional, jelaskan fitur khusus jika ada)

3. **Version Release**:
   - **Automatically release this version**: (centang jika ingin auto-release setelah approved)
   - Atau **Manually release this version**: (release manual setelah approved)

### 15.3 Export Compliance

1. **Export Compliance**:
   - **Does your app use encryption?**: Usually **No** untuk app seperti ini
   - Jika **Yes**, perlu isi form tambahan

### 15.4 Advertising Identifier (IDFA)

1. **Does this app use the Advertising Identifier (IDFA)?**: **No** (untuk app ini)

### 15.5 Content Rights

1. **Do you have the rights to use all content in this app?**: **Yes**

### 15.6 Submit for Review

1. Review semua informasi
2. Pastikan semua required fields sudah diisi
3. Klik **Submit for Review** button
4. Konfirmasi submission

### 15.7 Review Process

1. Status akan berubah menjadi **Waiting for Review**
2. Review biasanya 24-48 jam
3. Anda akan mendapat email notification:
   - **In Review**: App sedang di-review
   - **Approved**: App approved, akan release sesuai setting
   - **Rejected**: Ada issue, perlu fix dan resubmit

### 15.8 After Approval

1. Jika **Automatically release** tercentang, app akan otomatis muncul di App Store
2. Jika **Manually release**, Anda perlu:
   - Buka App Store Connect
   - Pilih app
   - Klik **Release This Version**

---

## 16. TROUBLESHOOTING

### 16.1 Flutter Doctor Issues

**Issue: CocoaPods not installed**
```bash
sudo gem install cocoapods
```

**Issue: Xcode not found**
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

**Issue: iOS toolchain not found**
- Pastikan Xcode terinstall lengkap
- Run: `xcodebuild -runFirstLaunch`

### 16.2 Build Errors

**Error: "No such module"**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

**Error: "Signing for Runner requires a development team"**
- Buka Xcode
- Pilih Runner project
- Tab Signing & Capabilities
- Pilih Team (Apple Developer Account)

**Error: "Provisioning profile not found"**
- Di Xcode, Signing & Capabilities
- Centang "Automatically manage signing"
- Xcode akan otomatis generate profile

### 16.3 Archive Errors

**Error: "Archive failed"**
- Pastikan pilih "Any iOS Device" bukan simulator
- Clean build: Product > Clean Build Folder (⇧⌘K)
- Build lagi: Product > Archive

**Error: "Invalid Bundle"**
- Check Bundle Identifier di Xcode dan App Store Connect harus sama
- Check version number harus increment

### 16.4 Upload Errors

**Error: "Invalid credentials"**
- Pastikan Apple ID dan password benar
- Jika pakai 2FA, gunakan app-specific password

**Error: "ITMS-90426: Invalid Swift Support"**
- Flutter sudah handle ini otomatis
- Pastikan build dengan `flutter build ipa`

### 16.5 App Store Connect Issues

**Build tidak muncul setelah upload**
- Tunggu 10-30 menit untuk processing
- Check email untuk notification
- Pastikan build sudah "Processed"

**Cannot select build**
- Pastikan build sudah "Ready to Submit"
- Check version number match dengan app version

### 16.6 Common Flutter iOS Issues

**App crash saat launch**
- Check console logs di Xcode
- Pastikan semua dependencies terinstall: `pod install`
- Check Info.plist configuration

**App tidak terlihat di device**
- Trust developer certificate di device
- Settings > General > VPN & Device Management > Trust

---

## 📝 CHECKLIST SEBELUM SUBMIT

- [ ] App tested di Simulator
- [ ] App tested di Physical Device
- [ ] Semua fitur berfungsi dengan baik
- [ ] No crash atau major bugs
- [ ] App icons sudah di-set
- [ ] Screenshots sudah di-upload
- [ ] Description sudah diisi
- [ ] Keywords sudah diisi
- [ ] Privacy policy (jika diperlukan)
- [ ] Version & Build number sudah benar
- [ ] Bundle Identifier sudah benar
- [ ] Archive sudah di-validate
- [ ] Build sudah di-upload ke App Store Connect
- [ ] Build sudah di-select untuk version
- [ ] Version information sudah diisi
- [ ] Export compliance sudah diisi
- [ ] Ready to submit!

---

## 🎉 SELAMAT!

Setelah app Anda approved dan release di App Store, app akan tersedia untuk download oleh semua user iOS di seluruh dunia!

**Tips:**
- Monitor reviews dan ratings
- Update app secara berkala
- Fix bugs yang dilaporkan user
- Tambah fitur baru berdasarkan feedback

---

## 📚 REFERENSI

- [Flutter iOS Setup](https://flutter.dev/docs/get-started/install/macos)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

**Last Updated:** December 2024
**Flutter Version:** 3.16.0+
**Xcode Version:** 15.0+

