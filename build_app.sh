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

echo ""
echo "✓ App built and bundled at: $APP_BUNDLE"
echo ""
echo "  To open it:  open \"$APP_BUNDLE\""
echo ""
echo "  To migrate your existing data from the web app:"
echo "  1. Open 'MacJournal.html' in Safari"
echo "  2. Open this file in your browser (or copy URL from Safari):"
echo "     $APP_BUNDLE/Contents/Resources/export_helper.html"
echo "  3. Click 'Export & Download Data'"
echo "  4. In the native app, go File > Import from Web App (JSON)..."
echo "     (or press Cmd+Shift+I)"
echo ""
