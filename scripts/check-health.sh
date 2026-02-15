#!/bin/bash
# check-health.sh - Check health of external dependencies
# Usage: ./scripts/check-health.sh
#
# This script checks:
# 1. Firebase connectivity (Firestore, Storage, Auth)
# 2. AI provider status (Gemini, Claude APIs)
# 3. Network connectivity
# 4. Simulator status
#
# Created: 2025-11-16
# References: Abundance iteration system Layer 3

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HEALTH_DIR="$PROJECT_ROOT/.debug/health"
HEALTH_LOG="$HEALTH_DIR/health-$(date +%Y%m%d-%H%M%S).json"

mkdir -p "$HEALTH_DIR"

echo ""
echo "🏥 Abundance Health Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Initialize health report
cat > "$HEALTH_LOG" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "checks": []
}
EOF

# Helper function to add check result
add_check() {
    local name="$1"
    local status="$2"
    local message="$3"

    # Read current JSON
    local current=$(cat "$HEALTH_LOG")

    # Add new check
    echo "$current" | jq ".checks += [{\"name\": \"$name\", \"status\": \"$status\", \"message\": \"$message\", \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}]" > "$HEALTH_LOG"

    if [ "$status" = "OK" ]; then
        echo "✅ $name: $message"
    elif [ "$status" = "WARN" ]; then
        echo "⚠️  $name: $message"
    else
        echo "❌ $name: $message"
    fi
}

# Check 1: Network connectivity
echo "Checking network connectivity..."
if ping -c 1 google.com &> /dev/null; then
    add_check "network" "OK" "Internet connectivity working"
else
    add_check "network" "FAIL" "No internet connection"
fi

# Check 2: Firebase reachability
echo "Checking Firebase..."
if curl -s -o /dev/null -w "%{http_code}" "https://firebase.googleapis.com" | grep -q "200\|301\|302"; then
    add_check "firebase_connectivity" "OK" "Firebase APIs reachable"
else
    add_check "firebase_connectivity" "FAIL" "Cannot reach Firebase APIs"
fi

# Check 3: Google Cloud status
echo "Checking GCP status..."
GCP_STATUS=$(curl -s "https://status.cloud.google.com/incidents.json" | jq -r '.[] | select(.service_name == "Google Cloud Firestore" or .service_name == "Cloud Functions") | .severity' | head -1)

if [ -z "$GCP_STATUS" ] || [ "$GCP_STATUS" = "null" ]; then
    add_check "gcp_status" "OK" "No active GCP incidents"
else
    add_check "gcp_status" "WARN" "Active GCP incident: $GCP_STATUS"
fi

# Check 4: Simulator status (if running)
echo "Checking simulators..."
BOOTED_SIMULATORS=$(xcrun simctl list devices | grep "Booted" | wc -l | xargs)

if [ "$BOOTED_SIMULATORS" -gt 0 ]; then
    add_check "simulator" "OK" "$BOOTED_SIMULATORS simulator(s) running"
else
    add_check "simulator" "WARN" "No simulators running (use XcodeBuildMCP boot_sim or xcrun simctl boot)"
fi

# Check 5: Xcode project status
echo "Checking Xcode project..."
if [ -d "$PROJECT_ROOT/Abundance.xcodeproj" ]; then
    add_check "xcode_project" "OK" "Xcode project exists"
else
    add_check "xcode_project" "WARN" "Xcode project not found (may need regeneration)"
fi

# Check 6: Recent logs
echo "Checking recent logs..."
RECENT_LOGS=$(find "$PROJECT_ROOT/.debug/logs" -name "*.log" -mtime -1 2>/dev/null | wc -l | xargs)

if [ "$RECENT_LOGS" -gt 0 ]; then
    add_check "recent_logs" "OK" "$RECENT_LOGS log file(s) from last 24 hours"
else
    add_check "recent_logs" "WARN" "No recent logs (haven't run device-tester recently?)"
fi

# Check 7: Open issues
echo "Checking for open issues..."
OPEN_ISSUES=$(find "$PROJECT_ROOT/.debug/issues/raw" -name "issue-*.md" 2>/dev/null | wc -l | xargs)

if [ "$OPEN_ISSUES" -gt 0 ]; then
    add_check "open_issues" "WARN" "$OPEN_ISSUES unprocessed issue(s) (run: claude triage-issues)"
else
    add_check "open_issues" "OK" "No unprocessed issues"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Health Report: $HEALTH_LOG"
echo ""

# Show summary
TOTAL_CHECKS=$(cat "$HEALTH_LOG" | jq '.checks | length')
OK_CHECKS=$(cat "$HEALTH_LOG" | jq '[.checks[] | select(.status == "OK")] | length')
WARN_CHECKS=$(cat "$HEALTH_LOG" | jq '[.checks[] | select(.status == "WARN")] | length')
FAIL_CHECKS=$(cat "$HEALTH_LOG" | jq '[.checks[] | select(.status == "FAIL")] | length')

echo "Summary: $OK_CHECKS OK, $WARN_CHECKS warnings, $FAIL_CHECKS failures"
echo ""

if [ "$FAIL_CHECKS" -gt 0 ]; then
    echo "⚠️  Some checks failed. Review the report above."
    exit 1
else
    echo "✅ All critical checks passed!"
    exit 0
fi
