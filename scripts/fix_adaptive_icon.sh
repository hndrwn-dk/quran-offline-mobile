#!/bin/bash

# Script to fix adaptive icon configuration after flutter_launcher_icons regenerate
# This ensures monochrome icon is included in adaptive icon

ICON_XML="android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml"

if [ ! -f "$ICON_XML" ]; then
    echo "Error: $ICON_XML not found!"
    exit 1
fi

# Check if monochrome already exists
if grep -q "<monochrome" "$ICON_XML"; then
    echo "Monochrome already configured in adaptive icon"
    exit 0
fi

# Add monochrome to adaptive icon
echo "Adding monochrome to adaptive icon configuration..."

# Create backup
cp "$ICON_XML" "$ICON_XML.bak"

# Add monochrome line before closing tag
sed -i 's|</adaptive-icon>|    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n</adaptive-icon>|' "$ICON_XML"

echo "✓ Monochrome added to adaptive icon"
echo "Note: Run this script after each 'flutter pub run flutter_launcher_icons'"

