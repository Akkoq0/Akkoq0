#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# GhostLink — Android APK Build Script
# ─────────────────────────────────────────────────────────

set -e

echo "=== [1/3] Building Next.js Static Export (out/) ==="
npm run mobile:export

echo "=== [2/3] Syncing Capacitor Android Assets ==="
npx cap sync android

echo "=== [3/3] Compiling Android APK with Gradle ==="
cd android
chmod +x gradlew
./gradlew assembleDebug

echo ""
echo "✅ APK BAŞARIYLA ÜRETİLDİ!"
echo "📁 APK Konumu: android/app/build/outputs/apk/debug/app-debug.apk"

