#!/bin/bash
set -e
cd "$(dirname "$0")"
APP="NOVA CLICKER.app"
mkdir -p "$APP/Contents/MacOS"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>NOVA CLICKER</string>
  <key>CFBundleDisplayName</key><string>NOVA CLICKER</string>
  <key>CFBundleIdentifier</key><string>com.nova.autoclicker</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
swiftc -O -framework SwiftUI -framework AppKit -framework ApplicationServices AutoClicker.swift -o "$APP/Contents/MacOS/NOVA-CLICKER"
echo "Built $APP"
open "$APP"
