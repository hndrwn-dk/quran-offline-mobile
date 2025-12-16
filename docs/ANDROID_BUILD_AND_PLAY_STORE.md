# Android Build & Play Store Deployment Guide

Panduan lengkap step-by-step untuk build Android package dan mendaftarkan ke Google Play Store. Panduan ini dibuat untuk pemula, sangat detail, tidak ada yang terlewat.

---

## 📋 DAFTAR ISI

1. [Prerequisites & Requirements](#1-prerequisites--requirements)
2. [Install Java Development Kit (JDK)](#2-install-java-development-kit-jdk)
3. [Install Android Studio](#3-install-android-studio)
4. [Install Flutter](#4-install-flutter)
5. [Setup Android Development Environment](#5-setup-android-development-environment)
6. [Clone & Setup Project](#6-clone--setup-project)
7. [Configure Android App](#7-configure-android-app)
8. [Build Android App](#8-build-android-app)
9. [Test di Emulator](#9-test-di-emulator)
10. [Test di Physical Device](#10-test-di-physical-device)
11. [Register Google Play Console Account](#11-register-google-play-console-account)
12. [Setup Play Console](#12-setup-play-console)
13. [Prepare Play Store Assets](#13-prepare-play-store-assets)
14. [Generate Signing Key](#14-generate-signing-key)
15. [Configure App Signing](#15-configure-app-signing)
16. [Build App Bundle untuk Play Store](#16-build-app-bundle-untuk-play-store)
17. [Upload ke Play Console](#17-upload-ke-play-console)
18. [Submit untuk Review](#18-submit-untuk-review)
19. [Troubleshooting](#19-troubleshooting)

---

## 1. PREREQUISITES & REQUIREMENTS

### 1.1 Hardware Requirements

- **Computer** (Windows, macOS, atau Linux)
  - Minimum 8GB RAM (recommended: 16GB)
  - Minimum 20GB free disk space untuk Android Studio dan SDK
  - Processor: 64-bit dengan virtualization support (untuk emulator)

### 1.2 Software Requirements

- **Operating System**: Windows 10/11, macOS 10.14+, atau Linux (Ubuntu 18.04+)
- **Java Development Kit (JDK)** 11 atau lebih baru
- **Android Studio** (latest version)
- **Flutter SDK** (latest stable version)
- **Google Play Console Account** (untuk deploy ke Play Store)

### 1.3 Account Requirements

- **Google Account** (gratis, untuk Play Console)
- **Google Play Console Account** ($25 one-time fee, untuk publish ke Play Store)

---

## 2. INSTALL JAVA DEVELOPMENT KIT (JDK)

### 2.1 Check Java Installation (Optional)

1. Buka **Terminal** (macOS/Linux) atau **Command Prompt** (Windows)
2. Jalankan:
```bash
java -version
```

Jika sudah terinstall, akan muncul versi Java. Jika belum, lanjut ke step 2.2.

### 2.2 Download JDK

**Untuk Windows:**
1. Buka browser, kunjungi: https://adoptium.net/
2. Pilih **JDK 11** atau **JDK 17** (LTS version)
3. Pilih **Windows x64**
4. Download installer
5. Run installer dan ikuti wizard
6. Pastikan **Add to PATH** tercentang

**Untuk macOS:**
1. Buka browser, kunjungi: https://adoptium.net/
2. Pilih **JDK 11** atau **JDK 17** (LTS version)
3. Pilih **macOS x64** (atau **ARM64** untuk Apple Silicon)
4. Download `.pkg` file
5. Double-click untuk install
6. Ikuti wizard installation

**Untuk Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install openjdk-11-jdk
```

### 2.3 Verify JDK Installation

1. Buka **Terminal** atau **Command Prompt**
2. Jalankan:
```bash
java -version
```

**Expected output:**
```
openjdk version "11.0.20" 2023-07-18
OpenJDK Runtime Environment (build 11.0.20+8)
OpenJDK 64-Bit Server VM (build 11.0.20+8, mixed mode)
```

3. Verifikasi JAVA_HOME (optional tapi recommended):
```bash
echo $JAVA_HOME
```

Jika kosong, set JAVA_HOME:
- **Windows**: Set via System Environment Variables
- **macOS/Linux**: Tambahkan ke `~/.zshrc` atau `~/.bash_profile`:
```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 11)
```

---

## 3. INSTALL ANDROID STUDIO

### 3.1 Download Android Studio

1. Buka browser, kunjungi: https://developer.android.com/studio
2. Klik **Download Android Studio**
3. Pilih sesuai OS Anda (Windows, macOS, atau Linux)
4. File akan terdownload (sekitar 1GB)

### 3.2 Install Android Studio

**Untuk Windows:**
1. Run installer `.exe` yang sudah didownload
2. Ikuti wizard installation
3. Pastikan **Android SDK**, **Android SDK Platform**, dan **Android Virtual Device** tercentang
4. Tunggu install selesai
5. Launch Android Studio

**Untuk macOS:**
1. Double-click file `.dmg` yang sudah didownload
2. Drag **Android Studio** ke **Applications** folder
3. Buka **Applications** > **Android Studio**
4. Jika muncul warning "Android Studio is from an unidentified developer":
   - Buka **System Preferences** > **Security & Privacy**
   - Klik **Open Anyway**

**Untuk Linux:**
1. Extract file `.tar.gz`:
```bash
cd ~/Downloads
tar -xzf android-studio-*.tar.gz
```
2. Move ke `/opt` (optional):
```bash
sudo mv android-studio /opt/
```
3. Run:
```bash
/opt/android-studio/bin/studio.sh
```

### 3.3 First Launch Setup

1. **Welcome Screen**: Pilih **Do not import settings** (jika pertama kali)
2. **Setup Wizard**:
   - **Install Type**: Pilih **Standard**
   - Klik **Next**
3. **SDK Components Setup**:
   - **Android SDK Location**: Biarkan default atau pilih lokasi custom
   - Pastikan **Android SDK**, **Android SDK Platform**, dan **Android Virtual Device** tercentang
   - Klik **Next**
4. **Verify Settings**: Review dan klik **Finish**
5. Tunggu download SDK components selesai (bisa 10-30 menit, tergantung internet)
6. Klik **Finish** setelah selesai

### 3.4 Verify Android Studio Installation

1. Buka Android Studio
2. Menu: **Help > About**
3. Pastikan versi terbaru terinstall (contoh: Android Studio Hedgehog | 2023.1.1)

---

## 4. INSTALL FLUTTER

### 4.1 Download Flutter SDK

1. Buka browser, kunjungi: https://flutter.dev/docs/get-started/install
2. Pilih OS Anda (Windows, macOS, atau Linux)
3. Klik **Download Flutter SDK** (latest stable version)
4. File akan terdownload sebagai `flutter_windows_xxx-stable.zip` (Windows) atau `flutter_macos_xxx-stable.zip` (macOS) atau `flutter_linux_xxx-stable.zip` (Linux)

### 4.2 Extract Flutter SDK

**Untuk Windows:**
1. Buka **File Explorer**
2. Buka folder **Downloads**
3. Right-click file `flutter_windows_xxx-stable.zip`
4. Pilih **Extract All...**
5. Extract ke lokasi yang diinginkan (recommended: `C:\src\flutter`)

**Untuk macOS:**
1. Buka **Finder**
2. Buka folder **Downloads**
3. Double-click file `flutter_macos_xxx-stable.zip`
4. File akan ter-extract menjadi folder `flutter`

**Untuk Linux:**
```bash
cd ~/Downloads
unzip flutter_linux_xxx-stable.zip
```

### 4.3 Move Flutter ke Lokasi Permanent

**Untuk Windows:**
1. Pindahkan folder `flutter` ke `C:\src\flutter` (atau lokasi lain)
2. Pastikan path tidak ada spasi (hindari `C:\Program Files\`)

**Untuk macOS:**
```bash
cd ~/Downloads
mv flutter ~/flutter
```

**Untuk Linux:**
```bash
cd ~/Downloads
mv flutter ~/flutter
```

### 4.4 Setup Flutter PATH

**Untuk Windows:**
1. Buka **System Properties**:
   - Tekan `Win + R`
   - Ketik `sysdm.cpl`
   - Tekan Enter
2. Tab **Advanced** > **Environment Variables**
3. Di **System Variables**, cari **Path**
4. Klik **Edit**
5. Klik **New**
6. Tambahkan path Flutter bin: `C:\src\flutter\bin` (atau sesuai lokasi Anda)
7. Klik **OK** di semua dialog
8. Buka **Command Prompt baru** (penting: harus baru)
9. Verifikasi:
```bash
flutter --version
```

**Untuk macOS:**
1. Buka **Terminal**
2. Edit file `.zshrc` (jika pakai zsh) atau `.bash_profile` (jika pakai bash):
```bash
nano ~/.zshrc
```
atau
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
```bash
source ~/.zshrc
```
atau
```bash
source ~/.bash_profile
```
6. Verifikasi:
```bash
flutter --version
```

**Untuk Linux:**
1. Buka **Terminal**
2. Edit file `.bashrc`:
```bash
nano ~/.bashrc
```
3. Tambahkan baris berikut di akhir file:
```bash
export PATH="$PATH:$HOME/flutter/bin"
```
4. Save file dan reload:
```bash
source ~/.bashrc
```
5. Verifikasi:
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

### 4.5 Run Flutter Doctor

Jalankan command untuk check semua requirements:
```bash
flutter doctor
```

**Expected output (ideal):**
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.16.0, on Windows 10 10.0.19045, locale en-US)
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
[✓] Chrome - develop for the web
[✓] Visual Studio - develop for Windows (Visual Studio Build Tools 2022)
[✓] Android Studio (version 2023.1)
[✓] VS Code (version 1.84.0)
[✓] Connected device (2 available)
[✓] Network resources
```

Jika ada tanda `[!]` atau `[✗]`, ikuti instruksi yang diberikan Flutter untuk memperbaikinya.

### 4.6 Accept Android Licenses

Jalankan command berikut untuk accept semua Android licenses:
```bash
flutter doctor --android-licenses
```

Tekan `y` untuk setiap license yang muncul.

---

## 5. SETUP ANDROID DEVELOPMENT ENVIRONMENT

### 5.1 Install Android SDK Components

1. Buka **Android Studio**
2. Menu: **Tools > SDK Manager**
3. Tab **SDK Platforms**:
   - Centang **Android 13.0 (Tiramisu)** atau **Android 14.0 (UpsideDownCake)**
   - Centang **Show Package Details**
   - Pastikan **Android SDK Platform 33** atau **34** tercentang
4. Tab **SDK Tools**:
   - Centang **Android SDK Build-Tools**
   - Centang **Android SDK Command-line Tools**
   - Centang **Android SDK Platform-Tools**
   - Centang **Android Emulator**
   - Centang **Google Play services**
   - Centang **Intel x86 Emulator Accelerator (HAXM)** (jika Intel processor)
5. Klik **Apply** dan tunggu download selesai

### 5.2 Setup Android Emulator

1. Di Android Studio, menu: **Tools > Device Manager**
2. Klik **Create Device**
3. Pilih device (contoh: **Pixel 6**)
4. Klik **Next**
5. Pilih system image (contoh: **Tiramisu API 33**)
6. Klik **Download** jika system image belum terdownload
7. Tunggu download selesai
8. Klik **Next**
9. Review configuration dan klik **Finish**
10. Emulator akan muncul di Device Manager

### 5.3 Verify Android Development Setup

Jalankan Flutter doctor dengan verbose untuk detail:
```bash
flutter doctor -v
```

Pastikan bagian Android menunjukkan:
```
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
[✓] Android Studio (version 2023.1)
[✓] Android SDK Platform-Tools
[✓] Android SDK Build-Tools
```

---

## 6. CLONE & SETUP PROJECT

### 6.1 Install Git (jika belum ada)

**Untuk Windows:**
- Download dari: https://git-scm.com/download/win
- Run installer dan ikuti wizard
- Pastikan **Git Bash** terinstall

**Untuk macOS:**
- Git biasanya sudah terinstall
- Verifikasi:
```bash
git --version
```

**Untuk Linux:**
```bash
sudo apt install git
```

### 6.2 Clone Project dari GitHub

1. Buka **Terminal** (macOS/Linux) atau **Git Bash** (Windows)
2. Navigate ke folder tempat Anda ingin menyimpan project:
```bash
cd ~/Documents
# atau
cd ~/development
# atau Windows: cd C:\Users\YourName\Documents
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

### 6.3 Verify Project Structure

Pastikan struktur project benar:
```bash
ls -la
# atau Windows: dir
```

**Expected structure:**
```
lib/
android/
ios/
pubspec.yaml
README.md
...
```

### 6.4 Install Flutter Dependencies

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

### 6.5 Generate Required Code

Beberapa packages memerlukan code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Tunggu sampai selesai.

---

## 7. CONFIGURE ANDROID APP

### 7.1 Update Application ID (Package Name)

1. Buka file `android/app/build.gradle.kts` (atau `build.gradle` jika menggunakan Groovy)
2. Cari bagian `defaultConfig`:
```kotlin
defaultConfig {
    applicationId = "com.tursinalabs.quranoffline"
    // ...
}
```

3. Pastikan `applicationId` sudah benar: `com.tursinalabs.quranoffline`
4. **PENTING**: Application ID ini harus unik dan tidak bisa diubah setelah app dipublish ke Play Store

### 7.2 Update App Name

1. Buka file `android/app/src/main/AndroidManifest.xml`
2. Cari baris:
```xml
<application
    android:label="Quran Offline"
    ...
```

3. Pastikan `android:label` sudah benar: `Quran Offline`

### 7.3 Update Version & Build Number

1. Buka file `pubspec.yaml`
2. Cari baris:
```yaml
version: 1.0.0+1
```

3. Format: `version+buildNumber`
   - **Version**: `1.0.0` (user-visible version)
   - **Build Number**: `1` (increment setiap kali upload ke Play Store)
4. Update sesuai kebutuhan:
```yaml
version: 1.0.0+1  # Version 1.0.0, Build 1
```

### 7.4 Configure App Icons

1. Pastikan icon sudah ada di `assets/icon/`
2. Run command untuk generate icons:
```bash
flutter pub run flutter_launcher_icons
```

3. Icons akan otomatis di-generate ke folder Android yang sesuai

### 7.5 Configure Splash Screen

Splash screen sudah dikonfigurasi di `pubspec.yaml`:
```yaml
flutter_native_splash:
  image: assets/icon/splash_icon.png
  color: "#FFFFFF"
  color_dark: "#121212"
  android: true
```

Generate splash screen:
```bash
flutter pub run flutter_native_splash:create
```

### 7.6 Update Minimum SDK Version

1. Buka file `android/app/build.gradle.kts`
2. Cari `minSdk`:
```kotlin
minSdk = flutter.minSdkVersion
```

3. Atau set manual (minimum untuk Play Store: 21):
```kotlin
minSdk = 21
```

### 7.7 Update Target SDK Version

1. Masih di `android/app/build.gradle.kts`
2. Cari `targetSdk`:
```kotlin
targetSdk = flutter.targetSdkVersion
```

3. Pastikan menggunakan versi terbaru (recommended: 34 atau lebih baru)

---

## 8. BUILD ANDROID APP

### 8.1 Clean Previous Builds

```bash
flutter clean
flutter pub get
```

### 8.2 Build untuk Emulator/Device (Debug)

1. Pastikan emulator sudah running atau device terhubung:
```bash
flutter devices
```

2. Build dan run:
```bash
flutter run
```

Atau build saja tanpa run:
```bash
flutter build apk --debug
```

### 8.3 Build untuk Physical Device (Release)

1. Connect Android device via USB
2. Enable **USB Debugging** di device
3. Verify connection:
```bash
flutter devices
```

4. Build release APK:
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 9. TEST DI EMULATOR

### 9.1 Start Emulator

**Via Android Studio:**
1. Buka Android Studio
2. Menu: **Tools > Device Manager**
3. Klik **Play** button (▶️) pada emulator yang ingin digunakan

**Via Command Line:**
```bash
flutter emulators
flutter emulators --launch <emulator_id>
```

### 9.2 Run App di Emulator

```bash
flutter run
```

Atau:
```bash
flutter run -d <device-id>
```

### 9.3 Test Features

Test semua fitur app:
- ✅ Splash screen
- ✅ Data import
- ✅ Read mode (Surah, Juz, Mushaf)
- ✅ Search
- ✅ Bookmarks
- ✅ Settings
- ✅ Text settings
- ✅ Theme switching
- ✅ Share functionality
- ✅ Offline functionality

---

## 10. TEST DI PHYSICAL DEVICE

### 10.1 Enable Developer Options

1. Di Android device, buka **Settings**
2. Scroll ke **About Phone** (atau **About Device**)
3. Tap **Build Number** 7 kali
4. Akan muncul pesan "You are now a developer!"

### 10.2 Enable USB Debugging

1. Kembali ke **Settings**
2. Buka **Developer Options** (sekarang sudah muncul)
3. Aktifkan **USB Debugging**
4. Aktifkan **Install via USB** (jika ada)

### 10.3 Connect Device

1. Connect Android device ke computer via USB
2. Di device, akan muncul dialog "Allow USB debugging?"
3. Centang **Always allow from this computer**
4. Tap **OK**

### 10.4 Verify Connection

```bash
flutter devices
```

**Expected output:**
```
2 connected devices:

sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64  • Android 13 (API 33) (emulator)
SM G991B (mobile)           • R58M30XXXXX   • android-arm64  • Android 13 (API 33)
```

### 10.5 Run di Device

```bash
flutter run -d <device-id>
```

Atau:
```bash
flutter run --release
```

### 10.6 Test di Device

Test semua fitur di physical device:
- ✅ App launch
- ✅ Touch interactions
- ✅ Performance
- ✅ Battery usage
- ✅ Network behavior (offline mode)

---

## 11. REGISTER GOOGLE PLAY CONSOLE ACCOUNT

### 11.1 Create Google Account (jika belum ada)

1. Buka browser, kunjungi: https://accounts.google.com/signup
2. Isi form:
   - First Name
   - Last Name
   - Username (email address)
   - Password (min 8 karakter)
   - Phone Number (untuk verifikasi)
3. Verifikasi phone number
4. Agree to Terms of Service
5. Selesai

### 11.2 Register Google Play Console

1. Buka browser, kunjungi: https://play.google.com/console/signup
2. Sign in dengan Google Account Anda
3. Pilih **Individual** (untuk personal) atau **Organization** (untuk company)
4. Isi informasi:
   - **Developer Name**: Nama yang akan muncul di Play Store
   - **Email Address**: Email untuk kontak
   - **Phone Number**: Phone untuk kontak
   - **Country/Region**: Pilih negara Anda
5. **Payment**: $25 USD (one-time fee, bukan per tahun)
6. Agree to **Developer Distribution Agreement**
7. Complete payment
8. Tunggu approval (biasanya instant, maksimal 24 jam)

### 11.3 Verify Account

1. Setelah payment selesai, Anda akan mendapat email konfirmasi
2. Buka: https://play.google.com/console
3. Sign in dengan Google Account
4. Pastikan status menunjukkan **Active**

---

## 12. SETUP PLAY CONSOLE

### 12.1 Access Play Console

1. Buka browser, kunjungi: https://play.google.com/console
2. Sign in dengan Google Account yang sudah terdaftar
3. Dashboard akan muncul

### 12.2 Create New App

1. Klik **Create app** button
2. Fill form:
   - **App name**: Quran Offline
   - **Default language**: English (United States) atau sesuai
   - **App or game**: App
   - **Free or paid**: Free
3. Klik **Create app**
4. App akan dibuat dan muncul di dashboard

### 12.3 Complete App Access

1. Setelah app dibuat, akan muncul checklist
2. Complete **App access** section:
   - **App access**: All functionality is available without restrictions
   - Atau pilih sesuai kebutuhan app Anda

---

## 13. PREPARE PLAY STORE ASSETS

### 13.1 App Icon

**Requirements:**
- Size: **512 x 512 pixels**
- Format: PNG atau JPEG
- No transparency
- No rounded corners (Google akan otomatis round)

**Cara membuat:**
1. Siapkan icon 512x512px
2. Pastikan tidak ada transparansi
3. Simpan sebagai PNG

### 13.2 Feature Graphic

**Requirements:**
- Size: **1024 x 500 pixels**
- Format: PNG atau JPEG
- No transparency

**Cara membuat:**
1. Buat graphic yang menarik dengan ukuran 1024x500px
2. Bisa menggunakan design tool seperti Figma, Canva, atau Photoshop
3. Simpan sebagai PNG

### 13.3 Screenshots

**Requirements:**
- **Phone**: Minimum 2, maksimal 8 screenshots
- **Tablet**: Minimum 1, maksimal 8 screenshots (optional)
- Format: PNG atau JPEG
- Aspect ratio: 16:9 atau 9:16
- Size: Minimum 320px, maksimal 3840px (panjang atau lebar)

**Cara ambil screenshot:**
1. Run app di emulator atau device
2. Navigate ke screen yang ingin di-screenshot
3. **Android Studio Emulator**: 
   - Klik icon camera di toolbar emulator
   - Atau tekan `Ctrl + S` (Windows/Linux) atau `Cmd + S` (macOS)
4. **Physical Device**:
   - Tekan **Power + Volume Down** bersamaan
   - Screenshot akan tersimpan di Gallery
5. Edit jika perlu (crop, add frames, dll)

**Recommended screenshots:**
- Home screen
- Surah reading mode
- Juz reading mode
- Mushaf (Page) reading mode
- Search functionality
- Bookmarks
- Settings

### 13.4 App Description

**Short Description:**
- Maximum: **80 characters**
- Contoh:
```
Offline-first Quran reader with multiple reading modes, bookmarks, and search
```

**Full Description:**
- Maximum: **4000 characters**
- Contoh:
```
Quran Offline is a production-ready, offline-first Quran reader app built with Material 3 design.

Features:
• Read by Surah, Juz, or Pages
• Multi-language translations (Indonesian, English, Chinese, Japanese)
• Bookmarks to save your favorite verses
• Offline search through translations
• Customizable text sizes
• Optional transliteration
• Share verses with others
• Dark mode support
• Tablet-optimized layout

Privacy-First:
• Works fully offline
• No analytics or tracking
• All data stored locally

Perfect for daily reading, study, and reflection. Works completely offline - no internet required.
```

### 13.5 Privacy Policy

**Requirements:**
- **Wajib** untuk semua app di Play Store
- Harus accessible via URL (public)
- Harus dalam bahasa yang sama dengan app listing

**Cara membuat:**
1. Buat file HTML atau Markdown dengan privacy policy
2. Host di GitHub Pages, Netlify, atau hosting lain
3. Contoh content:
```html
<!DOCTYPE html>
<html>
<head>
    <title>Privacy Policy - Quran Offline</title>
</head>
<body>
    <h1>Privacy Policy</h1>
    <p>Last updated: [Date]</p>
    
    <h2>Introduction</h2>
    <p>Quran Offline ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we handle information in our mobile application.</p>
    
    <h2>Information We Collect</h2>
    <p>Quran Offline is an offline-first application. We do not collect, store, or transmit any personal information or user data.</p>
    
    <h2>Local Storage</h2>
    <p>All data, including bookmarks and settings, are stored locally on your device. We do not have access to this data.</p>
    
    <h2>Third-Party Services</h2>
    <p>Our app does not use any third-party analytics, advertising, or tracking services.</p>
    
    <h2>Changes to This Privacy Policy</h2>
    <p>We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.</p>
    
    <h2>Contact Us</h2>
    <p>If you have any questions about this Privacy Policy, please contact us at: [Your Email]</p>
</body>
</html>
```

4. Upload ke hosting dan dapatkan URL (contoh: `https://yourusername.github.io/privacy-policy.html`)

---

## 14. GENERATE SIGNING KEY

### 14.1 Create Keystore

**PENTING**: Simpan keystore file dan password dengan aman. Jika hilang, Anda tidak bisa update app di Play Store!

1. Buka **Terminal** (macOS/Linux) atau **Command Prompt** (Windows)
2. Navigate ke folder project:
```bash
cd ~/Documents/quran-offline-mobile
# atau sesuai lokasi project Anda
```

3. Run command untuk generate keystore:
```bash
keytool -genkey -v -keystore ~/quran-offline-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias quran-offline
```

**Atau untuk Windows:**
```bash
keytool -genkey -v -keystore C:\Users\YourName\quran-offline-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias quran-offline
```

4. Isi informasi yang diminta:
   - **Keystore password**: (buat password yang kuat, simpan dengan aman!)
   - **Re-enter password**: (ketik ulang password)
   - **First and last name**: (nama Anda atau nama company)
   - **Organizational unit**: (opsional)
   - **Organization**: (nama company, jika ada)
   - **City**: (kota Anda)
   - **State**: (provinsi/state)
   - **Country code**: (contoh: ID untuk Indonesia, US untuk USA)
   - **Confirm**: (tekan Enter)
   - **Key password**: (bisa sama dengan keystore password, atau berbeda)

5. Keystore file akan dibuat di lokasi yang ditentukan (contoh: `~/quran-offline-key.jks`)

### 14.2 Verify Keystore

```bash
keytool -list -v -keystore ~/quran-offline-key.jks
```

Masukkan password keystore. Akan muncul informasi keystore.

### 14.3 Backup Keystore

**PENTING**: Backup keystore file ke lokasi yang aman (cloud storage, external drive, dll)!

1. Copy file keystore ke lokasi backup
2. Simpan password keystore di password manager yang aman
3. **Jangan commit keystore ke Git!**

---

## 15. CONFIGURE APP SIGNING

### 15.1 Create key.properties File

1. Di folder project, buat file `android/key.properties`
2. **PENTING**: File ini berisi password, jangan commit ke Git!
3. Isi file dengan:
```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=quran-offline
storeFile=<path-to-keystore>
```

**Contoh untuk macOS/Linux:**
```properties
storePassword=YourSecurePassword123!
keyPassword=YourSecurePassword123!
keyAlias=quran-offline
storeFile=/Users/YourName/quran-offline-key.jks
```

**Contoh untuk Windows:**
```properties
storePassword=YourSecurePassword123!
keyPassword=YourSecurePassword123!
keyAlias=quran-offline
storeFile=C:\\Users\\YourName\\quran-offline-key.jks
```

4. Ganti `<your-keystore-password>`, `<your-key-password>`, dan `<path-to-keystore>` dengan nilai yang sesuai

### 15.2 Update build.gradle.kts

1. Buka file `android/app/build.gradle.kts`
2. Tambahkan code berikut di **awal file**, sebelum `android {`:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing code ...
```

3. Update `android {` block, tambahkan `signingConfigs`:
```kotlin
android {
    namespace = "com.tursinalabs.quranoffline"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "com.tursinalabs.quranoffline"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

4. Tambahkan import di bagian atas file (jika belum ada):
```kotlin
import java.util.Properties
import java.io.FileInputStream
```

### 15.3 Add key.properties to .gitignore

1. Buka file `.gitignore` di root project
2. Pastikan ada baris:
```
android/key.properties
android/*.jks
*.jks
```

3. Ini memastikan file keystore dan password tidak ter-commit ke Git

### 15.4 Verify Signing Configuration

1. Build release APK untuk test:
```bash
flutter build apk --release
```

2. Jika build berhasil, berarti signing configuration sudah benar
3. APK akan ter-sign dengan keystore Anda

---

## 16. BUILD APP BUNDLE UNTUK PLAY STORE

### 16.1 Update Version & Build Number

1. Buka file `pubspec.yaml`
2. Update version:
```yaml
version: 1.0.0+1
```

Format: `version+buildNumber`
- **Version**: `1.0.0` (user-visible version)
- **Build Number**: `1` (increment setiap kali upload)

Untuk update berikutnya:
```yaml
version: 1.0.1+2  # Version 1.0.1, Build 2
version: 1.0.2+3  # Version 1.0.2, Build 3
```

### 16.2 Clean Build

```bash
flutter clean
flutter pub get
```

### 16.3 Build App Bundle

```bash
flutter build appbundle --release
```

**Expected output:**
```
Running Gradle task 'bundleRelease'...
...
Built build/app/outputs/bundle/release/app-release.aab
```

### 16.4 Verify App Bundle

1. File akan ada di: `build/app/outputs/bundle/release/app-release.aab`
2. Check file size (harus reasonable, tidak terlalu besar)
3. **PENTING**: Jangan build APK untuk Play Store, gunakan App Bundle (.aab)!

---

## 17. UPLOAD KE PLAY CONSOLE

### 17.1 Access Play Console

1. Buka browser, kunjungi: https://play.google.com/console
2. Sign in dengan Google Account
3. Pilih app **Quran Offline**

### 17.2 Complete Store Listing

1. Di sidebar kiri, klik **Store presence > Store listing**
2. Fill semua required fields:

**App details:**
- **App name**: Quran Offline
- **Short description**: (max 80 characters)
- **Full description**: (max 4000 characters)

**Graphics:**
- **App icon**: Upload 512x512px icon
- **Feature graphic**: Upload 1024x500px graphic
- **Phone screenshots**: Upload minimum 2 screenshots
- **Tablet screenshots**: (optional) Upload minimum 1 screenshot

**Categorization:**
- **App category**: Books & Reference
- **Tags**: (optional) quran, islam, offline, reading

**Contact details:**
- **Email**: Your email
- **Phone**: (optional)
- **Website**: (optional)

**Privacy Policy:**
- **Privacy Policy URL**: (wajib) URL privacy policy Anda

3. Klik **Save** setelah selesai

### 17.3 Complete Content Rating

1. Di sidebar, klik **Policy > App content**
2. Klik **Start questionnaire**
3. Answer questions:
   - **Does your app contain user-generated content?**: No
   - **Does your app contain violence?**: No
   - **Does your app contain sexual content?**: No
   - **Does your app contain profanity?**: No
   - **Does your app contain controlled substances?**: No
   - **Does your app contain gambling?**: No
   - **Does your app contain sensitive content?**: No
4. Submit questionnaire
5. Tunggu rating selesai (biasanya instant)

### 17.4 Complete Target Audience

1. Di sidebar, klik **Policy > Target audience and content**
2. Select **Target age group**: Everyone
3. Answer questions tentang content
4. Klik **Save**

### 17.5 Create Production Release (or Internal Testing)

**Untuk Internal Testing (Recommended untuk pertama kali):**
1. Di sidebar, klik **Testing > Internal testing**
2. Klik **Create new release**
3. Upload `app-release.aab` file:
   - Klik **Upload** button
   - Pilih file `build/app/outputs/bundle/release/app-release.aab`
   - Tunggu upload selesai
4. **Release name**: (optional) Version 1.0.0
5. **Release notes**: 
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
6. Klik **Save**
7. Klik **Review release**
8. Review semua informasi
9. Klik **Start rollout to Internal testing**
10. Tunggu processing selesai

**Untuk Production:**
1. Di sidebar, klik **Production**
2. Klik **Create new release**
3. Upload `app-release.aab` file
4. Fill release notes
5. Klik **Save**
6. Klik **Review release**
7. Review semua informasi
8. Klik **Start rollout to Production**

### 17.6 Verify Upload

1. Setelah upload, status akan menunjukkan **Processing**
2. Tunggu beberapa menit sampai status berubah menjadi **Ready to review** atau **Available**
3. Jika ada error, fix sesuai error message

---

## 18. SUBMIT UNTUK REVIEW

### 18.1 Complete App Content

Sebelum submit, pastikan semua section sudah complete:

**Required:**
- ✅ Store listing (complete)
- ✅ Content rating (complete)
- ✅ Target audience (complete)
- ✅ Privacy policy (URL provided)
- ✅ App bundle uploaded
- ✅ Release created

**Optional (tapi recommended):**
- ✅ App icon
- ✅ Feature graphic
- ✅ Screenshots (minimum 2)
- ✅ Full description

### 18.2 Check Pre-launch Report

1. Di sidebar, klik **Quality > Pre-launch report**
2. Review hasil testing otomatis
3. Fix issues jika ada

### 18.3 Submit for Review

1. Setelah semua complete, di **Production** atau **Internal testing** page
2. Klik **Review release**
3. Review semua informasi:
   - App bundle version
   - Release notes
   - Store listing
   - Content rating
4. Jika semua sudah benar, klik **Start rollout to Production** (atau **Internal testing**)

### 18.4 Review Process

1. Status akan berubah menjadi **In review**
2. Review biasanya 1-3 hari (bisa lebih cepat atau lebih lama)
3. Anda akan mendapat email notification:
   - **In review**: App sedang di-review
   - **Approved**: App approved, akan available di Play Store
   - **Rejected**: Ada issue, perlu fix dan resubmit

### 18.5 After Approval

1. Jika **Approved**, app akan otomatis available di Play Store
2. Status akan berubah menjadi **Available on Google Play**
3. App akan muncul di Play Store dalam beberapa jam
4. User bisa download dan install app

### 18.6 Monitor App

1. Di Play Console, monitor:
   - **Statistics**: Downloads, ratings, reviews
   - **Ratings and reviews**: User feedback
   - **Crashes and ANRs**: Error reports
   - **User feedback**: User reports

2. Respond to reviews dan fix bugs yang dilaporkan

---

## 19. TROUBLESHOOTING

### 19.1 Flutter Doctor Issues

**Issue: Android toolchain not found**
```bash
flutter doctor --android-licenses
```

**Issue: Java not found**
- Pastikan JDK terinstall dan PATH sudah di-set
- Verifikasi: `java -version`

**Issue: Android SDK not found**
- Buka Android Studio
- Menu: **Tools > SDK Manager**
- Install Android SDK Platform dan Tools

### 19.2 Build Errors

**Error: "Gradle build failed"**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build appbundle --release
```

**Error: "Signing config not found"**
- Pastikan file `android/key.properties` sudah dibuat
- Pastikan path keystore di `key.properties` benar
- Pastikan `build.gradle.kts` sudah dikonfigurasi dengan benar

**Error: "Keystore file not found"**
- Pastikan path keystore di `key.properties` benar
- Gunakan absolute path (full path)
- Windows: Gunakan double backslash `\\` atau forward slash `/`

**Error: "Invalid keystore format"**
- Pastikan keystore dibuat dengan `keytool` command yang benar
- Jangan gunakan keystore dari source lain

### 19.3 Upload Errors

**Error: "App bundle is invalid"**
- Pastikan build dengan `flutter build appbundle --release`
- Jangan gunakan APK, harus App Bundle (.aab)
- Pastikan version code sudah increment

**Error: "Version code already used"**
- Increment version code di `pubspec.yaml`
- Format: `version: 1.0.0+2` (build number harus lebih besar dari sebelumnya)

**Error: "App signing key mismatch"**
- Pastikan menggunakan keystore yang sama untuk setiap update
- Jangan generate keystore baru untuk update app yang sama

### 19.4 Play Console Issues

**Build tidak muncul setelah upload**
- Tunggu 10-30 menit untuk processing
- Check email untuk notification
- Pastikan build sudah "Processed"

**Cannot create release**
- Pastikan semua required sections sudah complete
- Check Store listing, Content rating, Target audience

**App rejected**
- Baca rejection reason di email atau Play Console
- Fix issues yang disebutkan
- Resubmit app

### 19.5 Common Flutter Android Issues

**App crash saat launch**
- Check logcat: `flutter logs` atau `adb logcat`
- Pastikan semua dependencies terinstall: `flutter pub get`
- Check `AndroidManifest.xml` configuration

**App tidak terlihat di device**
- Pastikan device sudah enable USB debugging
- Check: `flutter devices`
- Pastikan app sudah terinstall: `adb install app-release.apk`

**Build terlalu lama**
- Pastikan internet connection stabil
- Pastikan Android SDK sudah terdownload lengkap
- Clean build: `flutter clean`

---

## 📝 CHECKLIST SEBELUM SUBMIT

- [ ] App tested di Emulator
- [ ] App tested di Physical Device
- [ ] Semua fitur berfungsi dengan baik
- [ ] No crash atau major bugs
- [ ] App icons sudah di-set
- [ ] Screenshots sudah di-upload (minimum 2)
- [ ] Description sudah diisi
- [ ] Privacy policy URL sudah disediakan
- [ ] Content rating sudah complete
- [ ] Target audience sudah di-set
- [ ] Version & Build number sudah benar
- [ ] Application ID sudah benar
- [ ] Keystore sudah dibuat dan di-backup
- [ ] App signing sudah dikonfigurasi
- [ ] App Bundle sudah di-build
- [ ] App Bundle sudah di-upload ke Play Console
- [ ] Release sudah di-create
- [ ] Ready to submit!

---

## 🎉 SELAMAT!

Setelah app Anda approved dan available di Play Store, app akan tersedia untuk download oleh semua user Android di seluruh dunia!

**Tips:**
- Monitor reviews dan ratings
- Update app secara berkala
- Fix bugs yang dilaporkan user
- Tambah fitur baru berdasarkan feedback
- Respond to user reviews dengan sopan dan helpful

---

## 📚 REFERENSI

- [Flutter Android Setup](https://flutter.dev/docs/get-started/install)
- [Android Developer Documentation](https://developer.android.com/docs)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Play Store Policies](https://play.google.com/about/developer-content-policy/)
- [App Signing Best Practices](https://developer.android.com/studio/publish/app-signing)

---

**Last Updated:** December 2024
**Flutter Version:** 3.16.0+
**Android SDK Version:** 34.0.0+

