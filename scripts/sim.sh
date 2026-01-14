#!/bin/bash
# sim.sh - Fast iOS Development Loop (Simulator or Physical Device)
# Usage: ./scripts/sim.sh [options] [device-name]
#
# Options:
#   --device      Build and deploy to physical device (default: w-16e)
#   --sim         Build and run on simulator (default: 16PRO-IOS26)
#   --regenerate  Force regenerate Xcode project from scratch
#
# This script:
# 1. Regenerates Xcode project if needed (xcodegen)
# 2. Builds the app with xcodebuild
# 3. Launches on simulator or deploys to device
# 4. Captures logs to .debug/logs/

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/.debug/logs"
SESSION_LOG="$LOG_DIR/session-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "$LOG_DIR"

# Parse arguments
USE_DEVICE=false
DEVICE_NAME=""
FORCE_REGENERATE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --device)
            USE_DEVICE=true
            shift
            ;;
        --sim)
            USE_DEVICE=false
            shift
            ;;
        --regenerate)
            FORCE_REGENERATE=true
            shift
            ;;
        *)
            DEVICE_NAME="$1"
            shift
            ;;
    esac
done

# Set defaults based on mode
if [ "$USE_DEVICE" = true ]; then
    DEVICE_NAME="${DEVICE_NAME:-w-16e}"
    TARGET_TYPE="physical device"
else
    DEVICE_NAME="${DEVICE_NAME:-16PRO-IOS26}"
    TARGET_TYPE="simulator"
    # Find any available iOS 18 iPhone simulator
    SIMULATOR_ID_FALLBACK=$(xcrun simctl list devices available 2>/dev/null | grep -E "iPhone.*iOS 18" | head -1 | grep -oE '[A-F0-9-]{36}' || echo "")
fi

echo "🚀 Abundance Fast Iteration Loop"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Step 1: Generate Xcode project if needed
cd "$PROJECT_ROOT"

if [ ! -d "Abundance.xcodeproj" ]; then
    echo "⚠️  Xcode project not found. Generating..."
    xcodegen generate --spec project.yml
elif [ "$FORCE_REGENERATE" = true ]; then
    echo "🔨 Force regenerating Xcode project..."
    trash Abundance.xcodeproj 2>/dev/null || rm -rf Abundance.xcodeproj
    xcodegen generate --spec project.yml
else
    echo "🔄 Checking Xcode project..."
    xcodegen generate --spec project.yml --use-cache
fi

echo "✅ Xcode project ready"

# Step 2: Build
echo ""
echo "🔨 Building for $TARGET_TYPE..."

if [ "$USE_DEVICE" = true ]; then
    # Build for physical device
    DEVICE_ID=$(xcrun xctrace list devices 2>&1 | grep "$DEVICE_NAME" | head -1 | grep -oE '\([A-Z0-9-]+\)' | tr -d '()')

    if [ -z "$DEVICE_ID" ]; then
        echo "❌ Physical device not found: $DEVICE_NAME"
        echo ""
        echo "Available devices:"
        xcrun xctrace list devices 2>&1 | grep -E "iPhone|iPad" | grep -v "Simulator"
        exit 1
    fi

    echo "   Using device: $DEVICE_NAME (ID: $DEVICE_ID)"

    xcodebuild \
        -project Abundance.xcodeproj \
        -scheme Abundance \
        -destination "id=$DEVICE_ID" \
        -sdk iphoneos \
        -configuration Debug \
        -allowProvisioningUpdates \
        build install 2>&1 | tee "$SESSION_LOG" | grep -E "error:|warning:|Abundance|Build succeeded|Build failed|Installing" || true

    DEVICE_INSTALL_HANDLED=true
else
    # Build for simulator
    SIMULATOR_ID=$(xcrun simctl list devices | grep "$DEVICE_NAME" | head -1 | grep -oE '\([A-Z0-9-]+\)' | tr -d '()')

    if [ -z "$SIMULATOR_ID" ]; then
        echo "⚠️  Simulator name not found, using fallback ID: $SIMULATOR_ID_FALLBACK"
        SIMULATOR_ID="$SIMULATOR_ID_FALLBACK"

        if ! xcrun simctl list devices | grep -q "$SIMULATOR_ID"; then
            echo "❌ Simulator not found: $DEVICE_NAME (ID: $SIMULATOR_ID)"
            echo ""
            echo "Available simulators:"
            xcrun simctl list devices | grep -E "iPhone|iPad" | grep -v "unavailable"
            exit 1
        fi
    fi

    echo "   Using simulator: $DEVICE_NAME (ID: $SIMULATOR_ID)"

    xcodebuild \
        -project Abundance.xcodeproj \
        -scheme Abundance \
        -destination "id=$SIMULATOR_ID" \
        -sdk iphonesimulator \
        -configuration Debug \
        build 2>&1 | tee "$SESSION_LOG" | grep -E "error:|warning:|Abundance|Build succeeded|Build failed" || true

    BUILD_PRODUCT_PATH="Debug-iphonesimulator"
fi

# Check if build succeeded
if grep -q "Build failed" "$SESSION_LOG"; then
    echo ""
    echo "❌ Build failed. Check logs at: $SESSION_LOG"
    echo ""
    echo "Last 20 errors:"
    grep "error:" "$SESSION_LOG" | tail -20
    exit 1
fi

echo "✅ Build succeeded"

# Step 3: Deploy/Launch
echo ""
if [ "$USE_DEVICE" = true ]; then
    echo "✅ App installed to device via xcodebuild"
    echo ""
    echo "📱 Open the app on your device: $DEVICE_NAME"
    echo ""
    echo "To capture logs from device:"
    echo "  xcrun devicectl device monitor logs --device $DEVICE_ID"
else
    echo "🚀 Launching simulator..."

    xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || echo "   (Simulator already running)"

    APP_PATH="$(find ~/Library/Developer/Xcode/DerivedData -path "*/$BUILD_PRODUCT_PATH/Abundance.app" -type d 2>/dev/null | head -1)"
    if [ -n "$APP_PATH" ]; then
        xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
        echo "✅ App installed"
    else
        echo "⚠️  Could not find Abundance.app in DerivedData"
    fi

    BUNDLE_ID="com.abundance.mvp"
    echo ""
    echo "📱 Launching app..."
    xcrun simctl launch --console-pty "$SIMULATOR_ID" "$BUNDLE_ID" 2>&1 | tee -a "$SESSION_LOG" &
    APP_PID=$!

    open -a Simulator
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$USE_DEVICE" = true ]; then
    echo "✅ Abundance deployed to $DEVICE_NAME!"
else
    echo "✅ Abundance is running on simulator!"
    echo ""
    echo "Press Ctrl+C to stop logging..."
fi
echo ""
echo "📋 Logs: $SESSION_LOG"
echo "🐛 Found a bug? Tell Claude: 'capture this issue'"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Wait for Ctrl+C (simulator only)
if [ "$USE_DEVICE" = false ] && [ -n "$APP_PID" ]; then
    wait $APP_PID
fi
