#!/bin/bash
set -e

# Configuration
# Configuration
APP_NAME="FileWatcherApp" # Internal target name
BUNDLE_NAME="FileWatcher" # Display name on disk
BUNDLE_ID="com.example.filewatcher"
OUTPUT_DIR="build"
APP_BUNDLE="${OUTPUT_DIR}/${BUNDLE_NAME}.app"
EXECUTABLE_PATH="${APP_BUNDLE}/Contents/MacOS/${BUNDLE_NAME}" # Standard: Executable matches bundle name
INFO_PLIST="${APP_BUNDLE}/Contents/Info.plist"

# Clean and Build
echo "Building release configuration..."
swift build -c release

# Create Bundle Structure
echo "Creating .app bundle structure..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy Executable
echo "Copying executable..."
# We rename the binary from FileWatcherApp to FileWatcher to match the bundle
cp ".build/release/${APP_NAME}" "${EXECUTABLE_PATH}"

# Copy Resources
echo "Copying resources..."
cp -r ".build/release/${APP_NAME}_${APP_NAME}.bundle" "${APP_BUNDLE}/Contents/Resources/"

# Process App Icon
ICON_SOURCE="Sources/FileWatcherApp/Resources/Gemini_Generated_Image_yofg1syofg1syofg.png"
if [ -f "$ICON_SOURCE" ]; then
    echo "Generating AppIcon.icns..."
    ICONSET_DIR="build/AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"

    # Resize to standard icon sizes
    sips -z 16 16     "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_16x16.png" > /dev/null
    sips -z 32 32     "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_16x16@2x.png" > /dev/null
    sips -z 32 32     "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_32x32.png" > /dev/null
    sips -z 64 64     "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_32x32@2x.png" > /dev/null
    sips -z 128 128   "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_128x128.png" > /dev/null
    sips -z 256 256   "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_128x128@2x.png" > /dev/null
    sips -z 256 256   "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_256x256.png" > /dev/null
    sips -z 512 512   "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_256x256@2x.png" > /dev/null
    sips -z 512 512   "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_512x512.png" > /dev/null
    sips -z 1024 1024 "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_512x512@2x.png" > /dev/null

    iconutil -c icns "$ICONSET_DIR" -o "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
    rm -rf "$ICONSET_DIR"
else
    echo "Warning: Icon source not found at $ICON_SOURCE"
fi

# Create Info.plist
echo "Creating Info.plist..."
cat > "${INFO_PLIST}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleExecutable</key>
    <string>${BUNDLE_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${BUNDLE_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSDesktopFolderUsageDescription</key>
    <string>This app monitors your desktop for file changes to automate your workflow.</string>
    <key>NSDocumentsFolderUsageDescription</key>
    <string>This app monitors your documents for file changes to automate your workflow.</string>
    <key>NSDownloadsFolderUsageDescription</key>
    <string>This app monitors your downloads for file changes to automate your workflow.</string>
    <key>NSFileProviderDomainUsageDescription</key>
    <string>This app monitors your files to automate your workflow.</string>
</dict>
</plist>
EOF

# Ad-hoc Codesign
echo "Signing app..."
codesign --force --deep --sign - "${APP_BUNDLE}"

# Create Release ZIP
RELEASE_ZIP="${OUTPUT_DIR}/${BUNDLE_NAME}.zip"
echo "Creating release zip at ${RELEASE_ZIP}..."
ditto -c -k --sequesterRsrc --keepParent "${APP_BUNDLE}" "${RELEASE_ZIP}"

echo "Done! App built at ${APP_BUNDLE}"
echo "Release ZIP available at ${RELEASE_ZIP}"
