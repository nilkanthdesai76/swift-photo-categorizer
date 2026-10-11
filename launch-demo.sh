#!/bin/bash
set -e

# PhotoCategoryKit iOS Demo App Launcher
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "==================================================================="
echo "  📱 PhotoCategoryKit — iOS Demo App Launcher"
echo "  On-Device Apple Vision AI Categorization • Zero-Thermal Pacing"
echo "==================================================================="

echo "🔨 Verifying iOS Demo build in Xcode..."
xcodebuild -project Demo/Demo.xcodeproj -scheme Demo -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build

echo ""
echo "✅ Build Succeeded!"
echo "📂 Opening Demo project in Xcode..."
open Demo/Demo.xcodeproj
echo "🚀 Ready to run in iPhone Simulator or on a connected iOS device."
