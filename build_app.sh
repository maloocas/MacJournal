    #!/bin/bash
# Build the MacJournal macOS native app and create a proper .app bundle
#   Usage:  ./build_app.sh
#   Depends: swift, python3 (Pillow), iconutil, hdiutil

set -euo pipefail

PROJECT_DIR="$HOME/AI Projects (Coding)/MacJournal"
APP_NAME="MacJournal"
BUILD_DIR="$PROJECT_DIR/.build"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"
DMG_PATH="$PROJECT_DIR/dist/$APP_NAME.dmg"

# ── 1. Build ────────────────────────────────────────────────────────────────
echo "→ Building $APP_NAME (release)..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

if [ ! -f "$BUILD_DIR/release/$APP_NAME" ]; then
    echo "✗ Build failed — binary not found at $BUILD_DIR/release/$APP_NAME"
    exit 1
fi

# ── 2. Generate icon if .icns is missing ────────────────────────────────────
ICNS="$PROJECT_DIR/Resources/${APP_NAME}_Icon.icns"
ICON_PY="$PROJECT_DIR/Resources/generate_icon.py"

if [ ! -f "$ICNS" ]; then
    if [ -f "$ICON_PY" ]; then
        echo "→ .icns not found — generating from $ICON_PY ..."
        python3 "$ICON_PY" || {
            echo "⚠  Icon generation failed (Pillow missing?); building without icon."
        }
    else
        echo "⚠  No icon generator found at $ICON_PY — building without icon."
    fi
fi

# ── 3. Create .app bundle ───────────────────────────────────────────────────
echo "→ Creating .app bundle structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacJournal</string>
    <key>CFBundleIdentifier</key>
    <string>com.nousresearch.macjournal</string>
    <key>CFBundleName</key>
    <string>MacJournal</string>
    <key>CFBundleVersion</key>
    <string>1.0.2</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.2</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>CFBundleIconFile</key>
    <string>MacJournal_Icon</string>
</dict>
</plist>
PLIST

# Copy resources
if [ -f "$PROJECT_DIR/Resources/${APP_NAME}_Icon.icns" ]; then
    cp "$PROJECT_DIR/Resources/${APP_NAME}_Icon.icns" \
       "$APP_BUNDLE/Contents/Resources/"
fi

if [ -f "$PROJECT_DIR/Sources/$APP_NAME/Services/export_helper.html" ]; then
    cp "$PROJECT_DIR/Sources/$APP_NAME/Services/export_helper.html" \
       "$APP_BUNDLE/Contents/Resources/"
else
    echo "⚠  export_helper.html not found — skipping."
fi

# ── 4. Ad-hoc sign + strip quarantine ──────────────────────────────────────
echo "→ Ad-hoc signing and clearing quarantine flags..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true
xattr -cr "$APP_BUNDLE" 2>/dev/null || true

# ── 5. Distributable .dmg ──────────────────────────────────────────────────
echo "→ Creating distributable Disk Image..."
rm -rf "$PROJECT_DIR/dist"
mkdir -p "$PROJECT_DIR/dist"

STAGING="$(mktemp -d)"
cp -R "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "$DMG_PATH" 2>&1

rm -rf "$STAGING"

# ── 6. Summary ─────────────────────────────────────────────────────────────
echo ""
echo "✓ $APP_NAME built successfully!"
echo "  App bundle:  $APP_BUNDLE"
echo "  Disk Image:  $DMG_PATH"
echo ""
echo "  Send the .dmg to others. They just:"
echo "  1. Open the .dmg"
echo "  2. Drag MacJournal to Applications"
echo "  3. Right-click → Open (first time only)"
echo ""
echo "  To migrate existing data from the web app:"
echo "  1. Open the export helper in Safari:"
echo "     $APP_BUNDLE/Contents/Resources/export_helper.html"
echo "  2. Click 'Export & Download Data'"
echo "  3. In the native app, go File > Import from Web App (JSON)..."
echo "     (or press Cmd+Shift+I)"
echo ""
