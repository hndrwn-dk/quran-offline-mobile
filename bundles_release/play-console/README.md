# Play Console release plan

| Version | AAB | What's new | Status |
|---------|-----|------------|--------|
| **1.0.24+72** | `../v1.0.24+72/quran-offline-1.0.24+72.aab` | [PLAY_CONSOLE_1.0.24+72.txt](PLAY_CONSOLE_1.0.24+72.txt) | **Ready to upload** |
| 1.0.23+71 | `../release-name/quran-offline-1.0.23+71.aab` | [PLAY_CONSOLE_1.0.23+71.txt](PLAY_CONSOLE_1.0.23+71.txt) | Superseded by 1.0.24+72 |
| 1.0.22+70 | `../v1.0.22+70/quran-offline-1.0.22+70.aab` | [PLAY_CONSOLE_1.0.22+70.txt](PLAY_CONSOLE_1.0.22+70.txt) | Internal testing only; superseded (never promoted to production) |
| 1.0.21+69 | `../release-name/quran-offline-1.0.21+69.aab` | [PLAY_CONSOLE_1.0.21+69.txt](PLAY_CONSOLE_1.0.21+69.txt) | Superseded |
| 1.0.21+68 | `../release-name/quran-offline-1.0.21+68.aab` | [PLAY_CONSOLE_1.0.21+68.txt](PLAY_CONSOLE_1.0.21+68.txt) | Superseded |
| 1.0.19+65 | `../release-name/quran-offline-1.0.19+65.aab` | [PLAY_CONSOLE_1.0.19+65.txt](PLAY_CONSOLE_1.0.19+65.txt) | Superseded |
| 1.0.19+64 | `../release-name/quran-offline-1.0.19+64.aab` | [PLAY_CONSOLE_1.0.19+64.txt](PLAY_CONSOLE_1.0.19+64.txt) | Uploaded |
| **1.0.5+31** | `../release-name/quran-offline-1.0.5+31.aab` | [PLAY_CONSOLE_1.0.5+31.txt](PLAY_CONSOLE_1.0.5+31.txt) | Superseded |
| 1.0.5+30 | `../release-name/quran-offline-1.0.5+30.aab` | [PLAY_CONSOLE_1.0.5+30.txt](PLAY_CONSOLE_1.0.5+30.txt) | Superseded |
| 1.0.5+29 | `../release-name/quran-offline-1.0.5+29.aab` | [PLAY_CONSOLE_1.0.5+29.txt](PLAY_CONSOLE_1.0.5+29.txt) | Superseded |
| 1.0.4+28 | `../release-name/quran-offline-1.0.4+28.aab` | [PLAY_CONSOLE_1.0.4+28.txt](PLAY_CONSOLE_1.0.4+28.txt) | Previous |

## What `bash scripts/qo.sh submit` overwrites vs preserves

| Artifact | On rebuild |
|----------|------------|
| `release-name/quran-offline-{version}+{build}.aab` | Replaced; previous file copied to `.bak.{timestamp}` |
| `PLAY_CONSOLE_{version}+{build}.txt` | **Never touched** — edit manually only |
| `QA_CHECKLIST_{version}+{build}.md` | **Never touched** |
| `WHATS_NEW_{version}+{build}.md` | **Never touched** |
| `RELEASE_{version}+{build}.manifest.json` | **Never touched** — update sha256 after finalizing notes |
| `data/bundled/` (Quran backup) | **Never touched** — sync only copies bundled → `assets/` |
| `assets/` | Restored from `data/bundled/` before build (not a destructive wipe) |

Version must match everywhere before submit:

- `pubspec.yaml` → `1.0.5+31`
- `lib/core/constants/app_version.dart` → `1.0.5` / `31`
- `PLAY_CONSOLE_1.0.5+31.txt` (same build number in filename)

## Upload (1.0.5+31)

1. `bash scripts/qo.sh submit` — rebuild AAB with latest code + verify 131 assets inside bundle
2. Manual QA: [QA_CHECKLIST_1.0.5+31.md](QA_CHECKLIST_1.0.5+31.md)
3. [Google Play Console](https://play.google.com/console) → **Quran Offline** (`com.tursinalabs.quranoffline`)
4. **Release** → **Production** (or Internal testing first)
5. Upload `quran-offline-1.0.5+31.aab`
6. **Release notes** — copy between `<locale>` … `</locale>` from [PLAY_CONSOLE_1.0.5+31.txt](PLAY_CONSOLE_1.0.5+31.txt)
7. Review → **Start rollout**

New releases: start from [PLAY_CONSOLE_TEMPLATE.txt](PLAY_CONSOLE_TEMPLATE.txt)

