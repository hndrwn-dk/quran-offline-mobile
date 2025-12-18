# Setup Signing Key untuk Google Play Store

## Overview

Untuk submit app ke Google Play Store, Anda perlu:
1. **Generate keystore** (hanya sekali, simpan dengan aman!)
2. **Configure signing** di `build.gradle.kts`
3. **Build App Bundle** (.aab) bukan APK

## ⚠️ PENTING: Backup Keystore!

**Keystore adalah kunci untuk update app di Play Store!**
- Jika keystore hilang, Anda **TIDAK BISA** update app yang sudah di Play Store
- Simpan keystore di lokasi yang aman (cloud storage, external drive)
- Simpan password di password manager yang aman
- **JANGAN commit keystore ke Git!**

---

## Step 1: Generate Keystore

### Windows

```bash
keytool -genkey -v -keystore C:\Users\YourName\quran-offline-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias quran-offline
```

### macOS/Linux

```bash
keytool -genkey -v -keystore ~/quran-offline-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias quran-offline
```

### Informasi yang Diminta

Saat generate keystore, Anda akan diminta:

1. **Keystore password**: Buat password yang kuat (minimal 8 karakter, kombinasi huruf, angka, simbol)
   - **PENTING: Password HARUS ASCII-only!** (huruf A-Z, a-z, angka 0-9, dan simbol ASCII standar seperti !@#$%^&*)
   - **JANGAN gunakan karakter non-ASCII** seperti emoji, karakter Unicode, atau karakter khusus lainnya
   - **Simpan password ini dengan aman!**
   - Contoh yang benar: `MySecurePass123!@#`
   - Contoh yang salah: `MySecurePass123!@#🔐` (ada emoji)

2. **Re-enter password**: Ketik ulang password yang sama

3. **First and last name**: Nama Anda atau nama company
   - Contoh: `Tursina Labs` atau `Your Name`

4. **Organizational unit**: (Opsional, bisa kosong)
   - Contoh: `Development` atau `IT Department`

5. **Organization**: Nama company/organization
   - Contoh: `Tursina Labs`

6. **City**: Kota Anda
   - Contoh: `Jakarta`

7. **State**: Provinsi/State
   - Contoh: `DKI Jakarta` atau `California`

8. **Country code**: Kode negara (2 huruf)
   - Contoh: `ID` untuk Indonesia, `US` untuk USA

9. **Confirm**: Tekan Enter untuk konfirmasi

10. **Key password**: Bisa sama dengan keystore password (tekan Enter) atau berbeda

### Verify Keystore

Setelah generate, verify keystore:

```bash
# Windows
keytool -list -v -keystore C:\Users\YourName\quran-offline-key.jks

# macOS/Linux
keytool -list -v -keystore ~/quran-offline-key.jks
```

Masukkan password, akan muncul informasi keystore.

---

## Step 2: Create key.properties File

1. Buat file `android/key.properties` di project root
2. **PENTING**: File ini berisi password, jangan commit ke Git!

### Template untuk Windows

```properties
storePassword=YourSecurePassword123!@#
keyPassword=YourSecurePassword123!@#
keyAlias=quran-offline
storeFile=C:\\Users\\YourName\\quran-offline-key.jks
```

### Template untuk macOS/Linux

```properties
storePassword=YourSecurePassword123!@#
keyPassword=YourSecurePassword123!@#
keyAlias=quran-offline
storeFile=/Users/YourName/quran-offline-key.jks
```

### Cara Mengisi

1. Ganti `YourSecurePassword123!@#` dengan password keystore Anda
2. Ganti `C:\\Users\\YourName\\quran-offline-key.jks` dengan path lengkap ke keystore Anda
3. Pastikan `keyAlias` sesuai dengan alias yang digunakan saat generate keystore

**Note untuk Windows**: Gunakan double backslash (`\\`) atau forward slash (`/`) untuk path.

---

## Step 3: Update build.gradle.kts

File `android/app/build.gradle.kts` sudah dikonfigurasi untuk membaca `key.properties`.

Pastikan file tersebut memiliki:

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
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
```

Dan import di bagian atas:

```kotlin
import java.util.Properties
import java.io.FileInputStream
```

---

## Step 4: Verify .gitignore

Pastikan `.gitignore` sudah include:

```
android/key.properties
*.jks
*.keystore
```

File keystore dan key.properties **TIDAK BOLEH** di-commit ke Git!

---

## Step 5: Test Build

### Build APK untuk Test

```bash
flutter build apk --release
```

Jika build berhasil tanpa error, berarti signing configuration sudah benar.

### Build App Bundle untuk Play Store

```bash
flutter build appbundle --release
```

**Output**: `build/app/outputs/bundle/release/app-release.aab`

**PENTING**: Untuk Play Store, gunakan **App Bundle (.aab)**, bukan APK!

---

## Troubleshooting

### Error: "Password is not ASCII"

**Penyebab**: Password keystore mengandung karakter non-ASCII (emoji, karakter Unicode, dll)

**Solusi**:
- Gunakan password yang hanya mengandung karakter ASCII:
  - Huruf: A-Z, a-z
  - Angka: 0-9
  - Simbol ASCII standar: !@#$%^&*()_+-=[]{}|;:,.<>?
- **JANGAN gunakan**: emoji, karakter Unicode, atau karakter khusus lainnya
- Contoh password yang benar: `MySecurePass123!@#`
- Contoh password yang salah: `MySecurePass123!@#🔐` atau `MySecurePass123!@#密码`

**Cara fix**:
1. Generate keystore lagi dengan password ASCII-only
2. Atau jika sudah punya keystore dengan password non-ASCII, buat keystore baru dengan password ASCII-only

### Error: "key.properties not found"

- Pastikan file `android/key.properties` ada di lokasi yang benar
- Pastikan path di `storeFile` benar (gunakan absolute path)

### Error: "Keystore was tampered with, or password was incorrect"

- Pastikan password di `key.properties` benar
- Pastikan keystore file tidak corrupt

### Error: "Alias does not exist"

- Pastikan `keyAlias` di `key.properties` sesuai dengan alias saat generate keystore
- Verify dengan: `keytool -list -v -keystore <path-to-keystore>`

### Build masih menggunakan debug signing

- Pastikan `buildTypes.release.signingConfig` menggunakan `signingConfigs.getByName("release")`
- Pastikan file `key.properties` ada dan bisa dibaca

---

## Checklist Sebelum Upload ke Play Store

- [ ] Keystore sudah di-generate
- [ ] Keystore sudah di-backup ke lokasi yang aman
- [ ] Password keystore sudah disimpan dengan aman
- [ ] File `android/key.properties` sudah dibuat dan diisi dengan benar
- [ ] File `build.gradle.kts` sudah dikonfigurasi dengan benar
- [ ] `.gitignore` sudah include `key.properties` dan `*.jks`
- [ ] Test build APK berhasil
- [ ] Build App Bundle berhasil
- [ ] File `.aab` sudah siap untuk upload

---

## Next Steps

Setelah signing setup selesai:

1. **Update version** di `pubspec.yaml`:
   ```yaml
   version: 1.0.0+1
   ```

2. **Build App Bundle**:
   ```bash
   flutter build appbundle --release
   ```

3. **Upload ke Play Console**:
   - Buka https://play.google.com/console
   - Pilih app
   - Upload file `app-release.aab`

4. **Complete Store Listing**:
   - Screenshots
   - App description
   - Privacy policy URL
   - dll

---

## Resources

- [Flutter App Signing](https://docs.flutter.dev/deployment/android#signing-the-app)
- [Google Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
- [Keytool Documentation](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html)

