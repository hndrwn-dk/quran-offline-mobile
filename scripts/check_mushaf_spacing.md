# Checklist untuk Verifikasi Spacing Mushaf

Setelah perubahan spacing (`fontSize * 0.2`), cek ayat-ayat berikut sebagai sample representatif:

## Ayat Representatif untuk Di-Cek

### 1. Ayat Pendek (1-2 kata)
- **Surah 1, Ayat 1** (Al-Fatihah:1) - "بِسْمِ"
- **Surah 112, Ayat 1** (Al-Ikhlas:1) - "قُلْ"
- **Surah 108, Ayat 1** (Al-Kawthar:1) - "إِنَّا"

### 2. Ayat Sedang (3-5 kata)
- **Surah 1, Ayat 2** (Al-Fatihah:2) - "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ"
- **Surah 2, Ayat 1** (Al-Baqarah:1) - "الم"

### 3. Ayat Panjang (multi-line)
- **Surah 2, Ayat 2** (Al-Baqarah:2) - Ayat panjang yang biasanya wrap
- **Surah 2, Ayat 255** (Ayat Kursi) - Ayat sangat panjang

### 4. Edge Cases
- **Ayah pertama surah** (setelah Bismillah) - cek spacing setelah Bismillah
- **Ayah terakhir di halaman** - cek spacing sebelum page break
- **Ayah di tengah halaman** - cek spacing normal flow

### 5. Halaman Representatif
- **Halaman 1** (Al-Fatihah) - Ayat pendek
- **Halaman 2** (Al-Baqarah awal) - Mix ayat pendek dan panjang
- **Halaman 300** (tengah mushaf) - Ayat normal flow
- **Halaman 604** (terakhir) - Ayat terakhir

## Yang Harus Di-Cek

1. ✅ **Spacing antar ayat tidak terlalu besar** - Ayat terlihat rapat seperti mushaf fisik
2. ✅ **Spacing tidak terlalu kecil** - Masih bisa dibedakan antar ayat
3. ✅ **Ayah number tidak terlalu dekat dengan teks** - Masih ada breathing room
4. ✅ **Tidak ada overlap** - Teks tidak saling menumpuk
5. ✅ **Line break natural** - Ayat panjang wrap dengan baik

## Cara Cek Cepat

1. Buka mushaf mode
2. Scroll ke halaman-halaman di atas
3. Screenshot beberapa halaman
4. Bandingkan dengan aplikasi referensi (quran.com, muslim pro, nusuk)
5. Jika spacing terlihat konsisten dan compact → ✅ Good
6. Jika ada yang terlalu besar/kecil → Adjust lagi

## Catatan

- Spacing `fontSize * 0.2` adalah minimal spacing
- Jika masih terlalu besar di beberapa tempat, mungkin karena:
  - Line break natural dari justify text
  - WidgetSpan (ayah number) yang tinggi
  - Ini normal dan tidak perlu diubah
