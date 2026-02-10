#!/usr/bin/env bash
# device-monitor.sh — Continuous device log + screenshot correlation
#
# Watches the iCloud screenshots folder. When a new screenshot appears,
# pulls the on-device debug logs, extracts the ~10s window before the
# screenshot timestamp, and writes a combined issue file.
#
# Usage:
#   ./scripts/device-monitor.sh [--device NAME] [--bundle-id ID]
#
# Requirements: fswatch (brew install fswatch)

set -euo pipefail

DEVICE="${1:-w-16e}"
BUNDLE_ID="com.abundance.mvp"
SCREENSHOTS_DIR="/Users/w/Library/Mobile Documents/com~apple~CloudDocs/02 - screenshots"
ISSUES_DIR="/Users/w/code/abundance-mvp/.debug/issues"
LOG_CACHE_DIR="/Users/w/code/abundance-mvp/.debug/device-logs"
POLL_INTERVAL=5  # seconds between log pulls

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

mkdir -p "$ISSUES_DIR" "$LOG_CACHE_DIR"

# --- Preflight ---
if ! command -v fswatch &>/dev/null; then
    echo -e "${RED}Error: fswatch not found. Install with: brew install fswatch${NC}"
    exit 1
fi

if ! xcrun devicectl list devices 2>/dev/null | grep -q "$DEVICE"; then
    echo -e "${RED}Error: Device '$DEVICE' not found. Connect via USB.${NC}"
    exit 1
fi

echo -e "${GREEN}=== Device Monitor ===${NC}"
echo -e "Device:      ${CYAN}$DEVICE${NC}"
echo -e "Bundle ID:   ${CYAN}$BUNDLE_ID${NC}"
echo -e "Screenshots: ${CYAN}$SCREENSHOTS_DIR${NC}"
echo -e "Issues:      ${CYAN}$ISSUES_DIR${NC}"
echo ""
echo -e "${YELLOW}Monitoring for new screenshots... Take screenshots on device to generate issues.${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop.${NC}"
echo ""

# --- Log Puller (background) ---
# Continuously pulls the latest session log from device every POLL_INTERVAL seconds
CURRENT_LOG_FILE="$LOG_CACHE_DIR/current-session.jsonl"

pull_device_logs() {
    local tmp_dir
    tmp_dir=$(mktemp -d)

    # Copy the debug logs directory from device
    xcrun devicectl device copy from \
        --device "$DEVICE" \
        --domain-type appDataContainer \
        --domain-identifier "$BUNDLE_ID" \
        --source "Documents/.debug/logs/" \
        --destination "$tmp_dir/" 2>/dev/null || true

    # Find the most recent session log
    local latest
    latest=$(ls -t "$tmp_dir/"*.jsonl 2>/dev/null | head -1)

    if [[ -n "$latest" ]]; then
        cp "$latest" "$CURRENT_LOG_FILE"
    fi

    rm -rf "$tmp_dir"
}

# Background log puller
(
    while true; do
        pull_device_logs
        sleep "$POLL_INTERVAL"
    done
) &
LOG_PULLER_PID=$!

cleanup() {
    echo ""
    echo -e "${YELLOW}Stopping monitor...${NC}"
    kill "$LOG_PULLER_PID" 2>/dev/null || true
    wait "$LOG_PULLER_PID" 2>/dev/null || true
    echo -e "${GREEN}Done.${NC}"
    exit 0
}
trap cleanup INT TERM

# --- Screenshot Watcher ---
# When a new image file appears in the screenshots folder, correlate with logs

# Track processed screenshot markers to avoid duplicates
PROCESSED_MARKERS_FILE="$LOG_CACHE_DIR/.processed-markers"
touch "$PROCESSED_MARKERS_FILE"

# Count of screenshot markers seen so far (for dedup)
LAST_MARKER_COUNT=0

process_screenshot_marker() {
    local marker_timestamp="$1"  # ISO8601 from device
    local marker_screen="$2"

    echo -e "${CYAN}📸 Screenshot detected on device at $marker_timestamp (screen: $marker_screen)${NC}"

    # Extract logs within ±15 seconds of the marker timestamp
    # Convert ISO8601 to epoch for comparison
    local marker_epoch
    marker_epoch=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$marker_timestamp" "+%s" 2>/dev/null || echo "0")
    local window_start=$((marker_epoch - 15))
    local window_end=$((marker_epoch + 2))

    # Filter JSONL lines by timestamp window
    local relevant_logs=""
    if [[ -f "$CURRENT_LOG_FILE" ]]; then
        while IFS= read -r line; do
            # Extract timestamp from JSON line
            local ts
            ts=$(echo "$line" | python3 -c "
import sys, json
try:
    obj = json.loads(sys.stdin.read())
    print(obj.get('metadata', {}).get('timestamp', ''))
except: pass
" 2>/dev/null)
            if [[ -n "$ts" ]]; then
                local line_epoch
                line_epoch=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$ts" "+%s" 2>/dev/null || echo "0")
                if [[ "$line_epoch" -ge "$window_start" && "$line_epoch" -le "$window_end" ]]; then
                    relevant_logs+="$line"$'\n'
                fi
            fi
        done < "$CURRENT_LOG_FILE"
    fi

    # Find the matching screenshot file (most recent image in screenshots dir)
    # Allow up to 60s for iCloud sync
    local screenshot_path=""
    local attempts=0
    while [[ $attempts -lt 12 ]]; do
        # Look for files modified within 60s of the marker
        local candidate
        candidate=$(find "$SCREENSHOTS_DIR" -maxdepth 1 \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.heic" -o -name "*.PNG" \) -newer "$PROCESSED_MARKERS_FILE" 2>/dev/null | head -1)
        if [[ -n "$candidate" ]]; then
            screenshot_path="$candidate"
            break
        fi
        sleep 5
        ((attempts++))
    done

    local filename="no-screenshot-synced"
    if [[ -n "$screenshot_path" ]]; then
        filename=$(basename "$screenshot_path")
        echo -e "${GREEN}  📱 Matched screenshot: $filename${NC}"
    else
        echo -e "${YELLOW}  ⚠ No screenshot file synced within 60s (iCloud delay?)${NC}"
    fi

    # Generate issue file
    local issue_ts
    issue_ts=$(echo "$marker_timestamp" | sed 's/[-T:]//g' | cut -c1-15)
    local issue_file="$ISSUES_DIR/issue-${issue_ts}-${marker_screen}.md"

    local log_line_count
    log_line_count=$(echo "$relevant_logs" | grep -c . || echo "0")

    cat > "$issue_file" << ISSUE_EOF
# Device Test Issue — $marker_timestamp

## Screenshot
$(if [[ -n "$screenshot_path" ]]; then echo "![screenshot]($screenshot_path)"; else echo "_Screenshot not yet synced from device_"; fi)

**File:** \`$filename\`
**Device Timestamp:** $marker_timestamp
**Screen:** $marker_screen
**Device:** $DEVICE

## Device Logs (±15 seconds of screenshot)

\`\`\`json
${relevant_logs:-No log entries in window}
\`\`\`

## Triage

- **Severity:**
- **Category:**
- **Description:**

---
*Generated by device-monitor.sh (marker-correlated)*
ISSUE_EOF

    # Update processed markers timestamp
    touch "$PROCESSED_MARKERS_FILE"

    echo -e "${GREEN}  ✅ Issue created: $(basename "$issue_file")${NC}"
    echo -e "     Logs: $log_line_count lines in ±15s window"
    echo ""
}

# --- Main Loop ---
# Poll device logs and check for new SCREENSHOT_MARKER entries

echo -e "${CYAN}Polling device logs every ${POLL_INTERVAL}s for screenshot markers...${NC}"
echo ""

while true; do
    pull_device_logs

    if [[ -f "$CURRENT_LOG_FILE" ]]; then
        # Count SCREENSHOT_MARKER lines
        local_marker_count=$(grep -c "SCREENSHOT_MARKER" "$CURRENT_LOG_FILE" 2>/dev/null || echo "0")

        if [[ "$local_marker_count" -gt "$LAST_MARKER_COUNT" ]]; then
            # New markers found — process each new one
            local new_markers
            new_markers=$(grep "SCREENSHOT_MARKER" "$CURRENT_LOG_FILE" | tail -n $((local_marker_count - LAST_MARKER_COUNT)))

            while IFS= read -r marker_line; do
                # Parse timestamp and screen from the JSON line
                local parsed
                parsed=$(echo "$marker_line" | python3 -c "
import sys, json
try:
    obj = json.loads(sys.stdin.read())
    ts = obj.get('metadata', {}).get('timestamp', 'unknown')
    screen = obj.get('metadata', {}).get('screen', 'unknown')
    print(f'{ts}|{screen}')
except: print('unknown|unknown')
" 2>/dev/null)

                local ts="${parsed%%|*}"
                local screen="${parsed##*|}"

                process_screenshot_marker "$ts" "$screen"
            done <<< "$new_markers"

            LAST_MARKER_COUNT=$local_marker_count
        fi
    fi

    sleep "$POLL_INTERVAL"
done
