# Perintah otomasi data & build

Satu pintu masuk: **`bash scripts/qo.sh`** (atau `make`, atau `qo.bat` di Windows).

## Setup sekali per mesin

Setelah `assets/` berisi data lengkap (lihat [DATA_SOURCES.md](../DATA_SOURCES.md)):

```bash
bash scripts/qo.sh setup
```

Ini otomatis:
1. Backup `assets/` → `data/bundled/` (aman dari Git)
2. Pasang git hooks (auto-sync setelah `pull` / checkout)
3. Sync + verifikasi semua file wajib

Alternatif Makefile:

```bash
make setup
```

## Perintah harian

| Perintah | Fungsi |
|----------|--------|
| `bash scripts/qo.sh sync` | Pulihkan `assets/` dari `data/bundled/` |
| `bash scripts/qo.sh verify` | Cek data lengkap (gagal = ada yang hilang) |
| `bash scripts/qo.sh run` | sync + verify + `flutter run` |
| `bash scripts/qo.sh test` | sync + `flutter test` |
| `bash scripts/qo.sh qa` | sync + verify + integration test emulator |

## Release production (wajib)

| Perintah | Output |
|----------|--------|
| `bash scripts/qo.sh aab` | `build/app/outputs/bundle/release/app-release.aab` |
| `bash scripts/qo.sh apk` | `build/app/outputs/flutter-apk/app-release.apk` |

Makefile:

```bash
make aab
make apk
```

Windows (CMD):

```cmd
qo.bat aab
qo.bat apk
```

**Jangan** pakai `flutter build appbundle` langsung untuk Play Store.

## Setelah `git pull`

Otomatis jika sudah `qo setup`. Manual:

```bash
bash scripts/qo.sh sync
```

## Backup ulang data

Setelah mengganti / memperbarui file di `assets/`:

```bash
bash scripts/qo.sh seed
```

## Folder backup custom

```bash
export QURAN_OFFLINE_DATA_DIR=D:/quran-offline-data
bash scripts/qo.sh seed
bash scripts/qo.sh sync
```

## Ringkasan alur

```
git commit (hanya kode)  →  aman
git pull                 →  hook auto sync assets/
qo aab / qo apk          →  sync → verify → build (gagal jika data kosong)
```

Detail: [DATA_WORKFLOW.md](DATA_WORKFLOW.md)
