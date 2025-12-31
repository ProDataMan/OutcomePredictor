#!/bin/bash
# Build script for StatShark Android APK
# Run this outside of Claude Code if you encounter sandbox restrictions

set -e

echo "Building StatShark Android APK..."

cd StatSharkAndroid

# Clean previous builds
./gradlew clean

# Build debug APK
echo "Building debug APK..."
./gradlew assembleDebug

# Build release APK (requires signing configuration)
# echo "Building release APK..."
# ./gradlew assembleRelease

# Copy APKs to Android directory
echo "Copying APKs to Android directory..."
mkdir -p ../Android
cp app/build/outputs/apk/debug/app-debug.apk ../Android/StatShark-debug.apk
# cp app/build/outputs/apk/release/app-release.apk ../Android/StatShark-release.apk

echo "✅ Build complete!"
echo "Debug APK: Android/StatShark-debug.apk"
ls -lh ../Android/*.apk
