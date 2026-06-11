# Data workflow (prevent silent missing assets)

## Problem

`flutter build` bundles **only files on disk**. Quran and catalog JSON are **not in Git** (open-source layout). A normal `git pull`, `checkout`, or `reset --hard` can **delete** paths that were removed from the repository tree. The next release build may ship without data — the app crashes on device.

## Solution: two layers

| Layer | Path | Role |
|-------|------|------|
| **Canonical backup** | `data/bundled/` | Git **never** tracks or deletes this (`.gitignore`). Your source of truth. |
| **Flutter bundle** | `assets/` | What the app loads; repopulated from `data/bundled/` before build. |

```
data/bundled/     ← backup (safe from Git)
      │
      │  sync_bundled_data.sh
      ▼
assets/           ← flutter build reads this
      │
      │  verify_assets.sh (fail if incomplete)
      ▼
APK / AAB
```

## One-time setup (each machine)

1. Obtain data per [DATA_SOURCES.md](../DATA_SOURCES.md) into `assets/`, **or** copy an existing `data/bundled/` tree.

2. **Run automated setup** (seed + hooks + verify):

```bash
bash scripts/qo.sh setup
# or: make setup
```

See [COMMANDS.md](COMMANDS.md) for the full command list.

Optional: store data outside the repo:

```bash
export QURAN_OFFLINE_DATA_DIR=/path/to/my-quran-data
bash scripts/seed_bundled_data.sh
```

## Daily workflow

| Action | Command |
|--------|---------|
| After `git pull` / branch switch | Automatic if `qo setup` was run; else `bash scripts/qo.sh sync` |
| Run / debug | `bash scripts/qo.sh run` |
| **Production AAB** | `bash scripts/qo.sh aab` |
| **Production APK** | `bash scripts/qo.sh apk` |
| Check only | `bash scripts/qo.sh verify` |

**Do not** run bare `flutter build appbundle` for store releases — use `qo aab` so sync + verify always run.

## If verify fails

```
ERROR: Required assets missing on disk
```

1. `bash scripts/sync_bundled_data.sh` — restores from `data/bundled/`
2. If `data/bundled/` is empty — re-obtain data per DATA_SOURCES.md, place under `assets/`, then `bash scripts/seed_bundled_data.sh`
3. Keep a copy of `data/bundled/` on external drive or cloud (not in this repo)

## What is safe to commit

- App code, fonts, icons, `.gitkeep` placeholders
- `DATA_SOURCES.md`, scripts, docs

Never commit verse JSON, sqlite tafsir/surah-info, or explore catalogs.
