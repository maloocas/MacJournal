#!/bin/bash
# Build the MacJournal macOS native app and create a proper .app bundle
set -e

PROJECT_DIR="$HOME/AI Projects (Coding)/MacJournal"
APP_NAME="MacJournal"
BUILD_DIR="$PROJECT_DIR/.build"
APP_BUNDLE="$PROJECT_DIR/MacJournal.app"

echo "→ Building MacJournal macOS app..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

echo "→ Creating .app bundle structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy the built binary
cp "$BUILD_DIR/release/MacJournal" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.nousresearch.macjournal</string>
    <key>CFBundleName</key>
    <string>MacJournal</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
        <true/>
        <key>NSAppTransportSecurity</key>
        <dict><key>NSAllowsArbitraryLoads</key><true/></dict>
        <key>CFBundleIconFile</key>
        <string>MacJournal_Icon</string>
    </dict>
</plist>
PLIST

# Copy the export helper HTML into the Resources
cp "$PROJECT_DIR/Sources/MacJournal/Services/export_helper.html" "$APP_BUNDLE/Contents/Resources/"

# Copy the app icon
cp "$PROJECT_DIR/Resources/MacJournal_Icon.icns" "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || cp /tmp/MacJournal_Icon.icns "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true

echo "→ Ad-hoc signing and cleaning quarantine flags..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true
xattr -cr "$APP_BUNDLE"

echo "→ Creating distributable Disk Image..."
rm -rf "$PROJECT_DIR/dist"
mkdir -p "$PROJECT_DIR/dist"

STAGING="$PROJECT_DIR/DMG-TEMP"
rm -rf "$STAGING"
mkdir "$STAGING"
cp -R "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/"

DMG_PATH="$PROJECT_DIR/dist/MacJournal.dmg"
hdiutil create -volname "MacJournal" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "$DMG_PATH" 2>&1

rm -rf "$STAGING"

echo ""
echo "✓ App bundle:  $APP_BUNDLE"
echo "✓ Disk Image:  $DMG_PATH"
echo ""
echo "  Send the .dmg to others. They just:"
echo "  1. Open the .dmg"
echo "  2. Drag MacJournal to Applications"
echo "  3. Right-click → Open (first time only)"
echo ""
echo "  To migrate existing data from the web app:"
echo "  1. Open 'MacJournal.html' in Safari"
echo "  2. Open this file in your browser (or copy URL from Safari):"
echo "     $APP_BUNDLE/Contents/Resources/export_helper.html"
echo "  3. Click 'Export & Download Data'"
echo "  4. In the native app, go File > Import from Web App (JSON)..."
echo "     (or press Cmd+Shift+I)"
echo ""
