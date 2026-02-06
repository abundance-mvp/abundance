#!/bin/bash
# parallel-test-setup.sh - Setup and manage multiple iOS simulators for parallel AXe testing
#
# Creates 3 simulator instances, builds the app once, and installs on all simulators.
# Each simulator gets a unique window position so coordinate mapping doesn't conflict.
#
# Usage:
#   ./scripts/parallel-test-setup.sh create    # Create 3 test simulators
#   ./scripts/parallel-test-setup.sh boot       # Boot all test simulators
#   ./scripts/parallel-test-setup.sh install     # Build & install app on all simulators
#   ./scripts/parallel-test-setup.sh positions   # Set unique window positions
#   ./scripts/parallel-test-setup.sh status      # Show status of test simulators
#   ./scripts/parallel-test-setup.sh teardown    # Delete test simulators
#   ./scripts/parallel-test-setup.sh all         # Run create + boot + install + positions
#
# The script creates simulators named:
#   - AXe-Worker-1 (Scenarios 1-5)
#   - AXe-Worker-2 (Scenarios 6-9)
#   - AXe-Worker-3 (Scenarios 10-13)

set -euo pipefail

# Configuration
DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro"
# Find the latest available runtime
RUNTIME=$(xcrun simctl list runtimes -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
ios_runtimes = [r for r in data['runtimes'] if r['name'].startswith('iOS') and r['isAvailable']]
if ios_runtimes:
    print(ios_runtimes[-1]['identifier'])
else:
    sys.exit(1)
" 2>/dev/null) || {
    echo "ERROR: No available iOS runtime found"
    exit 1
}

WORKER_NAMES=("AXe-Worker-1" "AXe-Worker-2" "AXe-Worker-3")

# Scenario partitioning (for reference in Claude commands)
# Worker 1: Scenarios 1-5 (Tab Navigation, Empty State, Grid/Scroll, Search, Detail)
# Worker 2: Scenarios 6-9 (Edit Flow, Multi-Select, Context Menu, Profile)
# Worker 3: Scenarios 10-13 (Frame Check, ID Audit, Deep Catalog, Processing States)

# Window positions (left-to-right, no overlap for 402pt-wide simulator windows)
# Format: "x,y" for screen coordinates
WINDOW_POSITIONS=("50,50" "520,50" "990,50")

# --- Helper Functions ---

get_udid() {
    local name=$1
    xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['name'] == '$name':
            print(d['udid'])
            sys.exit(0)
sys.exit(1)
" 2>/dev/null
}

get_status() {
    local name=$1
    xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['name'] == '$name':
            print(d['state'])
            sys.exit(0)
print('NotFound')
" 2>/dev/null
}

# --- Commands ---

cmd_create() {
    echo "Creating test simulators with runtime: $RUNTIME"
    for name in "${WORKER_NAMES[@]}"; do
        existing=$(get_status "$name")
        if [ "$existing" != "NotFound" ]; then
            echo "  $name already exists (state: $existing)"
        else
            udid=$(xcrun simctl create "$name" "$DEVICE_TYPE" "$RUNTIME")
            echo "  Created $name ($udid)"
        fi
    done
    echo "Done."
}

cmd_boot() {
    echo "Booting test simulators..."
    for name in "${WORKER_NAMES[@]}"; do
        status=$(get_status "$name")
        if [ "$status" = "Booted" ]; then
            echo "  $name already booted"
        elif [ "$status" = "NotFound" ]; then
            echo "  $name not found — run 'create' first"
        else
            udid=$(get_udid "$name")
            xcrun simctl boot "$udid" 2>/dev/null || true
            echo "  Booted $name ($udid)"
        fi
    done
    # Open Simulator.app to show the windows
    open -a Simulator
    echo "Waiting for simulators to fully boot..."
    sleep 5
    echo "Done."
}

cmd_install() {
    echo "Building app for simulator..."
    # Build once
    xcodebuild build \
        -scheme AbundanceApp \
        -destination "generic/platform=iOS Simulator" \
        -derivedDataPath .build/DerivedData \
        -quiet 2>&1 | tail -5

    # Find the .app bundle
    APP_PATH=$(find .build/DerivedData -name "AbundanceApp.app" -path "*/Debug-iphonesimulator/*" | head -1)
    if [ -z "$APP_PATH" ]; then
        echo "ERROR: Could not find built .app bundle"
        exit 1
    fi
    echo "Found app: $APP_PATH"

    echo "Installing on all test simulators..."
    for name in "${WORKER_NAMES[@]}"; do
        udid=$(get_udid "$name")
        if [ -z "$udid" ]; then
            echo "  $name not found — skip"
            continue
        fi
        xcrun simctl install "$udid" "$APP_PATH"
        echo "  Installed on $name ($udid)"
    done
    echo "Done."
}

cmd_positions() {
    echo "Setting window positions..."
    # Wait for Simulator app to have windows
    sleep 2

    for i in "${!WORKER_NAMES[@]}"; do
        local name="${WORKER_NAMES[$i]}"
        local pos="${WINDOW_POSITIONS[$i]}"
        local x="${pos%%,*}"
        local y="${pos##*,}"

        osascript -e "
tell application \"System Events\"
    tell process \"Simulator\"
        repeat with w in windows
            if name of w contains \"$name\" then
                set position of w to {$x, $y}
                set size of w to {402, 902}
            end if
        end repeat
    end tell
end tell
" 2>/dev/null && echo "  $name → position ($x, $y)" || echo "  $name — window not found"
    done
    echo "Done. Windows positioned left-to-right."
}

cmd_status() {
    echo "Test Simulator Status:"
    echo "========================"
    printf "%-16s %-12s %s\n" "Name" "State" "UDID"
    printf "%-16s %-12s %s\n" "----" "-----" "----"
    for name in "${WORKER_NAMES[@]}"; do
        status=$(get_status "$name")
        if [ "$status" = "NotFound" ]; then
            printf "%-16s %-12s %s\n" "$name" "NotFound" "-"
        else
            udid=$(get_udid "$name")
            printf "%-16s %-12s %s\n" "$name" "$status" "$udid"
        fi
    done
    echo ""
    echo "Scenario Partitioning:"
    echo "  Worker-1: Scenarios 1-5  (Tab Nav, Empty State, Grid, Search, Detail)"
    echo "  Worker-2: Scenarios 6-9  (Edit Flow, Multi-Select, Context Menu, Profile)"
    echo "  Worker-3: Scenarios 10-13 (Frame Check, ID Audit, Deep Catalog, Processing)"
}

cmd_teardown() {
    echo "Tearing down test simulators..."
    for name in "${WORKER_NAMES[@]}"; do
        udid=$(get_udid "$name")
        if [ -n "$udid" ]; then
            xcrun simctl shutdown "$udid" 2>/dev/null || true
            xcrun simctl delete "$udid"
            echo "  Deleted $name ($udid)"
        else
            echo "  $name not found — skip"
        fi
    done
    echo "Done."
}

cmd_all() {
    cmd_create
    cmd_boot
    cmd_install
    cmd_positions
    echo ""
    cmd_status
}

# --- Main ---

case "${1:-help}" in
    create)    cmd_create ;;
    boot)      cmd_boot ;;
    install)   cmd_install ;;
    positions) cmd_positions ;;
    status)    cmd_status ;;
    teardown)  cmd_teardown ;;
    all)       cmd_all ;;
    help|*)
        echo "Usage: $0 {create|boot|install|positions|status|teardown|all}"
        echo ""
        echo "Commands:"
        echo "  create     Create 3 test simulators (AXe-Worker-1..3)"
        echo "  boot       Boot all test simulators"
        echo "  install    Build app and install on all simulators"
        echo "  positions  Set unique window positions (left-to-right)"
        echo "  status     Show status and scenario partitioning"
        echo "  teardown   Shutdown and delete test simulators"
        echo "  all        Run create + boot + install + positions"
        ;;
esac
