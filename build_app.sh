#!/bin/bash
# Build the LM KPI macOS native app and create a proper .app bundle
set -e

PROJECT_DIR="$HOME/AI Projects/LMKPI"
APP_NAME="LM KPI DEV BUILD"
BUILD_DIR="$PROJECT_DIR/.build"
APP_BUNDLE="$PROJECT_DIR/LM KPI DEV BUILD.app"

echo "→ Building LM KPI macOS app..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

echo "→ Creating .app bundle structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy the built binary
cp "$BUILD_DIR/release/LMKPI" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.nousresearch.lmkpi</string>
    <key>CFBundleName</key>
    <string>LM KPI</string>
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
        <string>LM_KPI_Icon</string>
    </dict>
</plist>
PLIST

# Copy the export helper HTML into the Resources
cp "$PROJECT_DIR/Sources/LMKPI/Services/export_helper.html" "$APP_BUNDLE/Contents/Resources/"

# Copy the app icon
cp "$PROJECT_DIR/Resources/LM_KPI_Icon.icns" "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || cp /tmp/LM_KPI_Icon.icns "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true

echo ""
echo "✓ App built and bundled at: $APP_BUNDLE"
echo ""
echo "  To open it:  open \"$APP_BUNDLE\""
echo ""
echo "  To migrate your existing data from the web app:"
echo "  1. Open 'LM KPI New.html' in Safari"
echo "  2. Open this file in your browser (or copy URL from Safari):"
echo "     $APP_BUNDLE/Contents/Resources/export_helper.html"
echo "  3. Click 'Export & Download Data'"
echo "  4. In the native app, go File > Import from Web App (JSON)..."
echo "     (or press Cmd+Shift+I)"
echo ""
