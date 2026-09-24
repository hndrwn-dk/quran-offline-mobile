# Release notes — 1.0.6+47

Feature: Temukan di Al-Qur'an (`kAiSearchEnabled = true`).
Phase G eval gate waived by maintainer; Phase D (hybrid ranking) deferred.

The previous chat prompt did not include ready-to-paste id/en store copy.
This text matches what shipped in v47.

## id

- Temukan di Al-Qur'an: cari ayat, tafsir, doa, dan Asmaul Husna dengan bahasa sehari-hari.
- Jelajahi untuk menjelajah katalog; pencarian ada di tab Cari.
- Doa dari Al-Qur'an: 99 ayat doa yang sudah ditinjau (34 belum ada di katalog doa lama).
- Kartu bacaan terakhir di Beranda bisa diketuk seluruhnya untuk lanjut membaca.

## en

- Find in the Qur'an: search verses, tafsir, dua, and the Names of Allah in everyday language.
- Explore is for browsing catalogs; search lives on the Search tab.
- Duas from the Qur'an: 99 reviewed verses (34 not in the older dua catalog).
- Tap anywhere on the Home last-read card to continue reading.

## Play Console

Paste file (gitignored): `bundles_release/play-console/PLAY_CONSOLE_1.0.6+47.txt`

## Catalog

- 99 approved `quran_dua` entries (0 pending, 0 overlap).
- 17:24-24 rejected as a duplicate of narrowed 17:23-24.
- Search index includes `quran_dua` (198 id+en docs).
