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

# Create Info.plist
echo "Creating Info.plist..."
cat > "${INFO_PLIST}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
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

echo "Done! App built at ${APP_BUNDLE}"
