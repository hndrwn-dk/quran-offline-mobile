# Quran Fonts

To add proper Quran fonts, download and place these files:

## Required Fonts

1. **KFGQPC-Uthmanic-Script-HAFS.ttf**
   - Download from: https://fonts.qurancomplex.gov.sa/
   - This is the preferred font for Mushaf layout

2. **ScheherazadeNew-Regular.ttf**
   - Download from: https://software.sil.org/scheherazade/
   - This is a fallback font for Arabic text

## Installation Steps

1. Download the font files
2. Place them in this directory (`assets/fonts/`)
3. Uncomment the font configuration in `pubspec.yaml`
4. Update the font family names in the Quran reader code

## Current Status

- Font configuration is active in `pubspec.yaml`
- Using 'UthmaniHafs' and 'UthmanicHafsV22' for Arabic text
- RTL direction and proper styling are implemented
- Quran fonts are properly configured and working