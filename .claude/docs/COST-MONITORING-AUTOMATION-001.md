# Cost Monitoring Automation

**ID**: COST-MONITORING-AUTOMATION-001
**Created**: 2025-11-14
**Status**: Approved
**Scope**: Automated cost tracking and alerting for Abundance MVP

## Overview

Cost monitoring automation ensures the Abundance MVP stays within the $554/month budget through proactive alerts, daily tracking, and automated reporting.

**Budget baseline**: COST-MODEL-001 ($554/month)

---

## Architecture

### Components

1. **cost-watchdog agent**: Claude Code agent for cost analysis
2. **Daily GitHub Action**: Automated cost fetching and alerting
3. **Slack integration**: Real-time notifications
4. **Budget dashboard**: Weekly reports in GitHub Issues

---

## 1. cost-watchdog Agent

**Location**: `.claude/agents/cost-watchdog.md`

**Trigger modes**:
- Daily: GitHub Actions cron (6 AM UTC)
- On-demand: `/check-costs` command
- PR review: Estimate cost impact of changes

### Behavior

**Inputs**:
- Budget: COST-MODEL-001 ($554/month breakdown)
- Actual: GCP Billing API, Firebase usage metrics
- Thresholds: 10% warn, 20% critical

**Process**:
1. Fetch current month costs via `gcloud billing` API
2. Calculate pro-rated expected spend (e.g., Day 15 → $277)
3. Compare actual vs expected, compute variance %
4. Break down by service (Firestore, Functions, Storage, etc.)
5. Identify top cost drivers
6. Generate recommendations based on ADRs

**Output format**:
```
📊 Cost Report: 2025-11-14 (Day 14 of 30)

Budget Status: ✅ ON TRACK
  Actual: $245 (44% of budget)
  Expected: $259 (pro-rated for 14 days)
  Variance: -$14 (-5.4%)

Breakdown by Service:
  ✅ Firestore: $12 (budget: $15, -20%)
  ✅ Cloud Functions: $22 (budget: $25, -12%)
  ✅ Cloud Storage: $14 (budget: $15, -7%)
  ✅ Authentication: $8 (budget: $10, -20%)
  ✅ Cloud Run (AI): $180 (budget: $200, -10%)
  ⚠️  Logging: $9 (budget: $5, +80%) ← INVESTIGATE

Recommendations:
  1. Logging costs high: Review retention policies (ADR-012)
  2. Cloud Run optimized: Cold start reduction working (ADR-008)
  3. Firestore under-utilized: Expected to increase as users onboard

Next Check: 2025-11-15 06:00 UTC
```

---

## 2. Daily GitHub Action

**Location**: `.github/workflows/cost-monitoring-daily.yml`

**Schedule**: Every day at 6 AM UTC

**Workflow**:

```yaml
name: Daily Cost Monitoring

on:
  schedule:
    - cron: '0 6 * * *'  # 6 AM UTC daily
  workflow_dispatch:      # Manual trigger

jobs:
  cost-check:
    runs-on: ubuntu-latest
    permissions:
      issues: write
      contents: read

    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SERVICE_ACCOUNT }}

      - name: Fetch current costs
        id: costs
        run: |
          # Fetch billing data
          COSTS=$(gcloud billing accounts list \
            --billing-account=${{ secrets.GCP_BILLING_ACCOUNT }} \
            --format=json)

          # Extract total
          TOTAL=$(echo "$COSTS" | jq '.total')
          echo "total=$TOTAL" >> $GITHUB_OUTPUT

          # Save full report
          echo "$COSTS" > costs-$(date +%Y-%m-%d).json

      - name: Run cost-watchdog agent
        run: |
          # Invoke Claude Code agent
          claude agent run cost-watchdog \
            --input costs-$(date +%Y-%m-%d).json \
            --output cost-report.md

      - name: Check thresholds
        id: alert
        run: |
          # Parse report for alerts
          if grep -q "🚨 CRITICAL" cost-report.md; then
            echo "severity=critical" >> $GITHUB_OUTPUT
          elif grep -q "⚠️  WARNING" cost-report.md; then
            echo "severity=warning" >> $GITHUB_OUTPUT
          else
            echo "severity=ok" >> $GITHUB_OUTPUT
          fi

      - name: Post to Slack (critical only)
        if: steps.alert.outputs.severity == 'critical'
        uses: slackapi/slack-github-action@v1.25.0
        with:
          webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
          payload: |
            {
              "text": "🚨 CRITICAL: Budget exceeded!",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Cost Alert*\n$(cat cost-report.md)"
                  }
                }
              ]
            }

      - name: Create GitHub Issue (warning/critical)
        if: steps.alert.outputs.severity != 'ok'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs')
            const report = fs.readFileSync('cost-report.md', 'utf8')
            const severity = '${{ steps.alert.outputs.severity }}'

            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `Cost Alert: ${severity.toUpperCase()} - ${new Date().toISOString().split('T')[0]}`,
              body: report,
              labels: ['cost-monitoring', severity]
            })

      - name: Update dashboard
        run: |
          # Append to weekly dashboard issue
          gh issue comment ${{ secrets.COST_DASHBOARD_ISSUE }} \
            --body "$(cat cost-report.md)"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Cost**: ~$0.50/day ($15/month) for agent invocations

---

## 3. Alerting Thresholds

### 10% Warning

**Trigger**: Actual spend 10% above pro-rated budget

**Actions**:
- Post to GitHub Issue with `warning` label
- Include recommendations from cost-watchdog
- Tag team lead for review

**Example**:
```
Day 15: Budget $277, Actual $305 (+10.1%)
Action: Review service breakdown, identify optimization opportunities
```

---

### 20% Critical

**Trigger**: Actual spend 20% above pro-rated budget

**Actions**:
- Post to Slack `#abundance-alerts` channel
- Create GitHub Issue with `critical` label
- Email tech lead (via Slack integration)
- Block new feature PRs until resolved

**Example**:
```
Day 15: Budget $277, Actual $332 (+19.9%)
Action: URGENT - Investigate cost spike, pause non-critical deployments
```

---

### 50% Severe

**Trigger**: Actual spend 50% above budget

**Actions**:
- All critical actions PLUS:
- Page on-call engineer (via PagerDuty, if configured)
- Automatic cost-reduction measures:
  - Scale down Cloud Run to minimum instances
  - Increase Firestore cache TTL
  - Disable non-critical Cloud Functions

**Example**:
```
Day 15: Budget $277, Actual $415 (+49.8%)
Action: EMERGENCY - Auto-scaling to minimum, immediate investigation required
```

---

## 4. Cost Breakdown by Service

### Monitoring Queries

**Firestore**:
```bash
gcloud logging read "resource.type=firestore.googleapis.com" \
  --format="table(timestamp, jsonPayload.cost)" \
  --freshness=1d
```

**Cloud Functions**:
```bash
gcloud functions list --format="table(name, runtime, triggerHttps)" \
gcloud alpha billing budgets describe BUDGET_ID --billing-account=ACCOUNT_ID
```

**Cloud Run (AI Pipeline)**:
```bash
gcloud run services list --format="table(name, region, latestRevision)"
gcloud logging read "resource.type=cloud_run_revision" \
  --format="table(timestamp, resource.labels.service_name, jsonPayload.cost)"
```

**Cloud Storage**:
```bash
gsutil du -sh gs://abundance-mvp.appspot.com
```

---

## 5. Budget Dashboard

**Location**: Pinned GitHub Issue (created manually)

**Title**: "📊 Monthly Cost Dashboard - November 2025"

**Template**:
```markdown
# Monthly Cost Dashboard

**Budget**: $554/month
**Period**: 2025-11-01 to 2025-11-30
**Last Updated**: 2025-11-14 06:00 UTC

## Current Status

| Metric | Value | Status |
|--------|-------|--------|
| Days Elapsed | 14 / 30 | 47% |
| Budget Used | $245 / $554 | 44% ✅ |
| Variance | -$14 | -5.4% |

## Daily Reports

<!-- Automated reports appended below by GitHub Action -->

### 2025-11-14
[Automated cost-watchdog report pasted here]

### 2025-11-13
[Automated cost-watchdog report pasted here]

...
```

**Update frequency**: Daily (appended by GitHub Action)

---

## 6. Cost Optimization Recommendations

### Automated Recommendations

Based on ADR references, cost-watchdog suggests:

**High Firestore costs**:
```
⚠️  Firestore: $18 (budget: $15, +20%)
Recommendation: Enable offline persistence (ADR-011) to reduce reads
Action: Review query patterns, add indexes per ADR-006
```

**High Cloud Functions costs**:
```
⚠️  Cloud Functions: $30 (budget: $25, +20%)
Recommendation: Optimize cold starts per ADR-008 (min instances = 1)
Action: Review function timeout settings, reduce from 60s to 30s
```

**High Cloud Run costs**:
```
🚨 Cloud Run: $250 (budget: $200, +25%)
Recommendation: Review batch processing (ADR-005), reduce P95 latency
Action: Implement request coalescing to reduce API calls
```

---

## 7. Manual Cost Review Workflow

### Weekly Review (Every Monday)

**Process**:
1. Review cost dashboard GitHub Issue
2. Compare weekly trend: Week 1 vs Week 2 vs Week 3
3. Identify anomalies (unexpected spikes)
4. Correlate with deployment timeline (did new feature cause spike?)
5. Update COST-MODEL-001 if baseline shifts

**Questions to ask**:
- Which service had the biggest variance?
- Were there any one-time spikes (e.g., migration, bulk upload)?
- Are we on track to stay within monthly budget?
- Do we need to adjust feature scope to reduce costs?

---

### Monthly Review (End of Month)

**Process**:
1. Generate final cost report for the month
2. Compare actual vs budgeted for each service
3. Document lessons learned
4. Update ADRs if cost assumptions changed
5. Adjust next month's budget if needed

**Output**: Monthly cost postmortem in `docs/cost-postmortems/YYYY-MM.md`

---

## 8. Integration with Development Workflow

### PR Cost Estimation

**Goal**: Estimate cost impact before merging

**Workflow**:
1. PR opened with backend/AI changes
2. GitHub Action invokes cost-watchdog in "estimate" mode
3. Agent analyzes:
   - New Cloud Functions added
   - New API calls (Claude/Gemini)
   - New Firestore queries
4. Posts comment with estimated monthly impact

**Example comment**:
```
💰 Estimated Cost Impact: +$12/month (+2.2% of budget)

Breakdown:
  - New Cloud Function (processImage): +$5/month (estimated 10K invocations)
  - Additional Claude API calls: +$7/month (500 requests/day)

Recommendations:
  - Consider batching image processing per ADR-005
  - Add request caching to reduce Claude calls

Status: ✅ Within acceptable range (<5% increase)
```

---

## 9. Emergency Cost Reduction

### Auto-Scaling Down

**Trigger**: 50% over budget

**Actions** (via GitHub Action):
```bash
# Scale Cloud Run to minimum
gcloud run services update ai-pipeline \
  --min-instances=0 \
  --max-instances=1 \
  --region=us-central1

# Increase Firestore cache TTL
firebase firestore:indexes:set firestore.indexes.json \
  --cache-control "public, max-age=3600"

# Disable non-critical Functions
gcloud functions delete processAnalytics --region=us-central1 --quiet
```

**Notification**:
```
🚨 EMERGENCY: Auto-scaling activated
  - Cloud Run scaled to 0-1 instances
  - Firestore cache TTL increased to 1 hour
  - Non-critical functions disabled

Impact: Reduced capacity, slower response times
Action Required: Investigate cost spike immediately
```

---

## 10. Cost Attribution

### Tagging Strategy

**Labels for all GCP resources**:
```bash
gcloud run services update SERVICE_NAME \
  --update-labels=env=production,feature=image-analysis,cost-center=ai-pipeline
```

**Labels**:
- `env`: production, staging, development
- `feature`: image-analysis, auth, recommendations, etc.
- `cost-center`: ios, backend, ai-pipeline

**Benefits**:
- Filter costs by feature: "How much does image analysis cost?"
- Compare environments: "Is staging costing more than expected?"
- Attribute costs to teams: "What's the AI pipeline burn rate?"

---

## References

- **COST-MODEL-001**: Budget baseline ($554/month)
- **AI-AGENT-BEHAVIORS-001**: cost-watchdog agent specification
- **ADR-005**: AI pipeline latency/cost tradeoffs
- **ADR-008**: Cloud Functions cold start optimization
- **ADR-011**: Firestore offline persistence
- **ADR-012**: Data retention and lifecycle policies

## Changelog

- **2025-11-14**: Initial version with daily monitoring and 3-tier alerting
