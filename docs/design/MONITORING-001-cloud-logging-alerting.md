# MONITORING-001: Cloud Logging & Alerting

**Created**: 2025-11-10
**Stage**: 3.2 - Backend Implementation Research
**References**: CLOUD-FUNCTIONS-001, RESEARCH-VALIDATION-stage-3.2, CODE-EXAMPLE-005
**Status**: Complete

## Overview

Production-ready monitoring and alerting patterns for Abundance backend on GCP:

- **Structured Logging**: JSON format with severity levels
- **Cloud Monitoring Dashboards**: Function metrics, AI pipeline health
- **Alert Policies**: Error rate, latency, quota near limit
- **Budget Alerts**: Cost overruns (50%, 90%, 100%)
- **Log-Based Metrics**: Custom metrics from logs

All patterns verified against Cloud Logging and Cloud Monitoring documentation.

## 1. Structured Logging

### Logging Pattern (Node.js)

```javascript
/**
 * Structured logging for Cloud Logging
 * Use console.log/error with JSON objects
 * Automatically indexed and searchable
 */

// INFO level
console.log({
  severity: 'INFO',
  message: 'AI pipeline started',
  userId: 'user123',
  itemId: 'item456',
  timestamp: new Date().toISOString(),
  metadata: {
    hasBarcode: true,
    imageSize: 1024000
  }
});

// WARNING level
console.warn({
  severity: 'WARNING',
  message: 'Gemini API retry attempt',
  attempt: 2,
  maxRetries: 5,
  delay: 2000,
  error: 'Rate limit exceeded'
});

// ERROR level
console.error({
  severity: 'ERROR',
  message: 'AI pipeline failed',
  itemId: 'item456',
  userId: 'user123',
  error: error.message,
  stack: error.stack,
  layer: 'layer2a',
  duration: 3500
});

// CRITICAL level (for catastrophic failures)
console.error({
  severity: 'CRITICAL',
  message: 'Firestore connection lost',
  error: error.message,
  affectedUsers: 1500,
  timestamp: new Date().toISOString()
});
```

### Logging Utility (Reusable)

```javascript
// utils/logger.js

/**
 * Structured logger for Cloud Functions
 * Provides consistent formatting and metadata
 */
class Logger {
  constructor(functionName) {
    this.functionName = functionName;
  }

  info(message, metadata = {}) {
    console.log({
      severity: 'INFO',
      function: this.functionName,
      message,
      timestamp: new Date().toISOString(),
      ...metadata
    });
  }

  warn(message, metadata = {}) {
    console.warn({
      severity: 'WARNING',
      function: this.functionName,
      message,
      timestamp: new Date().toISOString(),
      ...metadata
    });
  }

  error(message, error, metadata = {}) {
    console.error({
      severity: 'ERROR',
      function: this.functionName,
      message,
      error: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString(),
      ...metadata
    });
  }

  critical(message, error, metadata = {}) {
    console.error({
      severity: 'CRITICAL',
      function: this.functionName,
      message,
      error: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString(),
      ...metadata
    });
  }

  /**
   * Log AI API usage for cost tracking
   */
  aiUsage(provider, tokens, cost, metadata = {}) {
    console.log({
      severity: 'INFO',
      function: this.functionName,
      message: 'AI API usage',
      provider, // 'gemini', 'claude', 'serpapi'
      tokens,
      cost,
      timestamp: new Date().toISOString(),
      ...metadata
    });
  }

  /**
   * Log performance metrics
   */
  performance(operation, duration, metadata = {}) {
    console.log({
      severity: 'INFO',
      function: this.functionName,
      message: 'Performance metric',
      operation,
      duration,
      timestamp: new Date().toISOString(),
      ...metadata
    });
  }
}

module.exports = Logger;
```

### Usage in Cloud Functions

```javascript
const Logger = require('./utils/logger');

exports.analyzeItem = functions.https.onRequest(async (req, res) => {
  const logger = new Logger('analyzeItem');
  const startTime = Date.now();

  try {
    const userId = req.user.uid;
    const itemId = req.body.itemId;

    logger.info('Request received', { userId, itemId });

    // Process AI pipeline...
    const result = await orchestrateAIPipeline(itemId);

    const duration = Date.now() - startTime;
    logger.performance('analyzeItem', duration, {
      userId,
      itemId,
      estimatedValue: result.estimatedValue
    });

    logger.aiUsage('gemini', 500, 0.001, { itemId });
    logger.aiUsage('claude', 1200, 0.018, { itemId });

    res.json({ success: true, result });
  } catch (error) {
    logger.error('Request failed', error, {
      userId: req.user?.uid,
      duration: Date.now() - startTime
    });

    res.status(500).json({ error: error.message });
  }
});
```

## 2. Cloud Monitoring Dashboards

### Dashboard Configuration (JSON)

```json
{
  "displayName": "Abundance Backend Monitoring",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Function Invocations",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"cloud_function\" AND resource.labels.function_name=\"analyzeItem\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_RATE"
                  }
                }
              }
            }],
            "yAxis": {
              "label": "Invocations/sec",
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Function Latency (p95)",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"cloud_function\" AND resource.labels.function_name=\"analyzeItem\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_times\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_DELTA",
                    "crossSeriesReducer": "REDUCE_PERCENTILE_95"
                  }
                }
              }
            }],
            "yAxis": {
              "label": "Latency (ms)",
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Error Rate",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"cloud_function\" AND severity=\"ERROR\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_RATE"
                  }
                }
              }
            }],
            "yAxis": {
              "label": "Errors/sec",
              "scale": "LINEAR"
            },
            "thresholds": [{
              "value": 0.05,
              "color": "RED",
              "label": "SLO Threshold (5%)"
            }]
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "AI Pipeline Duration",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"cloud_function\" AND jsonPayload.message=\"Performance metric\" AND jsonPayload.operation=\"analyzeItem\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_MEAN"
                  }
                }
              }
            }],
            "yAxis": {
              "label": "Duration (ms)",
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "AI Costs (Hourly)",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"cloud_function\" AND jsonPayload.message=\"AI API usage\"",
                  "aggregation": {
                    "alignmentPeriod": "3600s",
                    "perSeriesAligner": "ALIGN_SUM",
                    "groupByFields": ["jsonPayload.provider"]
                  }
                }
              }
            }],
            "yAxis": {
              "label": "Cost (USD)",
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Firestore Document Reads",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"firestore_database\" AND metric.type=\"firestore.googleapis.com/document/read_count\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_RATE"
                  }
                }
              }
            }],
            "yAxis": {
              "label": "Reads/sec",
              "scale": "LINEAR"
            }
          }
        }
      }
    ]
  }
}
```

### Create Dashboard (gcloud CLI)

```bash
# Create dashboard from JSON
gcloud monitoring dashboards create --config-from-file=dashboard.json \
  --project=abundance-prod

# Or use Cloud Console:
# https://console.cloud.google.com/monitoring/dashboards
# → Create Dashboard → Import from JSON
```

## 3. Alert Policies

### Error Rate Alert

```bash
# Create alert policy (gcloud CLI)
gcloud alpha monitoring policies create \
  --notification-channels=projects/abundance-prod/notificationChannels/CHANNEL_ID \
  --display-name="High Error Rate" \
  --condition-display-name="Error rate > 5%" \
  --condition-threshold-value=0.05 \
  --condition-threshold-duration=300s \
  --condition-threshold-comparison=COMPARISON_GT \
  --condition-filter='resource.type="cloud_function" AND severity="ERROR"' \
  --project=abundance-prod
```

### Error Rate Alert (YAML)

```yaml
# alert-error-rate.yaml
displayName: "High Error Rate"
documentation:
  content: "Error rate exceeds 5% for 5 minutes. Check Cloud Logging for details."
conditions:
  - displayName: "Error rate > 5%"
    conditionThreshold:
      filter: 'resource.type="cloud_function" AND severity="ERROR"'
      aggregations:
        - alignmentPeriod: 60s
          perSeriesAligner: ALIGN_RATE
      comparison: COMPARISON_GT
      thresholdValue: 0.05
      duration: 300s
notificationChannels:
  - projects/abundance-prod/notificationChannels/SLACK_CHANNEL
  - projects/abundance-prod/notificationChannels/EMAIL_CHANNEL
alertStrategy:
  autoClose: 86400s # 24 hours
```

### Latency Alert (p95 > 10s)

```yaml
# alert-latency.yaml
displayName: "High Latency (p95)"
documentation:
  content: "p95 latency exceeds 10 seconds. Check function performance and AI API response times."
conditions:
  - displayName: "p95 latency > 10s"
    conditionThreshold:
      filter: 'resource.type="cloud_function" AND metric.type="cloudfunctions.googleapis.com/function/execution_times"'
      aggregations:
        - alignmentPeriod: 60s
          perSeriesAligner: ALIGN_DELTA
          crossSeriesReducer: REDUCE_PERCENTILE_95
      comparison: COMPARISON_GT
      thresholdValue: 10000 # milliseconds
      duration: 300s
notificationChannels:
  - projects/abundance-prod/notificationChannels/SLACK_CHANNEL
```

### Dead Letter Queue Alert

```yaml
# alert-dlq.yaml
displayName: "Dead Letter Queue Growing"
documentation:
  content: "More than 10 items in dead letter queue. Review failed items in Firestore."
conditions:
  - displayName: "DLQ size > 10"
    conditionThreshold:
      filter: 'resource.type="cloud_function" AND jsonPayload.message="AI pipeline failed"'
      aggregations:
        - alignmentPeriod: 3600s
          perSeriesAligner: ALIGN_COUNT
      comparison: COMPARISON_GT
      thresholdValue: 10
      duration: 0s
notificationChannels:
  - projects/abundance-prod/notificationChannels/SLACK_CHANNEL
```

### Quota Alert (Gemini API)

```yaml
# alert-quota.yaml
displayName: "Gemini API Quota Near Limit"
documentation:
  content: "Gemini API usage at 90% of quota. Consider upgrading or optimizing usage."
conditions:
  - displayName: "Quota usage > 90%"
    conditionThreshold:
      filter: 'metric.type="serviceruntime.googleapis.com/quota/allocation/usage" AND resource.labels.service="generativelanguage.googleapis.com"'
      aggregations:
        - alignmentPeriod: 300s
          perSeriesAligner: ALIGN_MAX
      comparison: COMPARISON_GT
      thresholdValue: 0.9
      duration: 0s
notificationChannels:
  - projects/abundance-prod/notificationChannels/EMAIL_CHANNEL
```

### Apply Alert Policies

```bash
# Create alert from YAML
gcloud alpha monitoring policies create --policy-from-file=alert-error-rate.yaml \
  --project=abundance-prod

gcloud alpha monitoring policies create --policy-from-file=alert-latency.yaml \
  --project=abundance-prod

gcloud alpha monitoring policies create --policy-from-file=alert-dlq.yaml \
  --project=abundance-prod

gcloud alpha monitoring policies create --policy-from-file=alert-quota.yaml \
  --project=abundance-prod
```

## 4. Budget Alerts

### Create Budget (gcloud CLI)

```bash
# Create $100/month budget with alerts at 50%, 90%, 100%
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="Abundance Backend Budget" \
  --budget-amount=100 \
  --threshold-rule=percent=50 \
  --threshold-rule=percent=90 \
  --threshold-rule=percent=100 \
  --all-updates-rule-pubsub-topic=projects/abundance-prod/topics/budget-alerts
```

### Budget Alert (YAML)

```yaml
# budget-alert.yaml
displayName: "Abundance Backend Budget"
budgetFilter:
  projects:
    - projects/abundance-prod
amount:
  specifiedAmount:
    currencyCode: USD
    units: "100"
thresholdRules:
  - thresholdPercent: 0.5
    spendBasis: CURRENT_SPEND
  - thresholdPercent: 0.9
    spendBasis: CURRENT_SPEND
  - thresholdPercent: 1.0
    spendBasis: CURRENT_SPEND
allUpdatesRule:
  pubsubTopic: projects/abundance-prod/topics/budget-alerts
  schemaVersion: "1.0"
```

### Budget Alert Handler (Cloud Function)

```javascript
// Handle budget alert Pub/Sub messages
exports.handleBudgetAlert = functions.pubsub
  .topic('budget-alerts')
  .onPublish(async (message) => {
    const data = JSON.parse(Buffer.from(message.data, 'base64').toString());
    const costAmount = data.costAmount;
    const budgetAmount = data.budgetAmount;
    const percent = (costAmount / budgetAmount) * 100;

    console.log({
      severity: 'WARNING',
      message: 'Budget alert triggered',
      costAmount,
      budgetAmount,
      percent,
      timestamp: new Date().toISOString()
    });

    // Send Slack notification
    await axios.post(process.env.SLACK_WEBHOOK_URL, {
      text: `⚠️ Budget Alert: ${percent.toFixed(0)}% of monthly budget used ($${costAmount}/$${budgetAmount})`
    });

    // If 100% exceeded, disable non-critical functions
    if (percent >= 100) {
      console.error({
        severity: 'CRITICAL',
        message: 'Budget exceeded - disabling non-critical functions',
        costAmount,
        budgetAmount
      });

      // Disable scheduled retry job
      await admin.firestore().collection('config').doc('features').update({
        retryJobEnabled: false
      });
    }
  });
```

## 5. Log-Based Metrics

### Create Custom Metrics

```bash
# Metric: AI pipeline success rate
gcloud logging metrics create ai_pipeline_success_rate \
  --description="AI pipeline success rate" \
  --log-filter='resource.type="cloud_function" AND jsonPayload.message="AI pipeline completed"' \
  --value-extractor='EXTRACT(jsonPayload.confidence)' \
  --project=abundance-prod

# Metric: AI cost per item
gcloud logging metrics create ai_cost_per_item \
  --description="AI cost per item analyzed" \
  --log-filter='resource.type="cloud_function" AND jsonPayload.message="AI API usage"' \
  --value-extractor='EXTRACT(jsonPayload.cost)' \
  --project=abundance-prod

# Metric: Failed items count
gcloud logging metrics create failed_items_count \
  --description="Count of failed items" \
  --log-filter='resource.type="cloud_function" AND severity="ERROR" AND jsonPayload.message="AI pipeline failed"' \
  --metric-kind=DELTA \
  --project=abundance-prod
```

### Custom Metric Alert

```yaml
# alert-custom-metric.yaml
displayName: "AI Pipeline Success Rate < 95%"
documentation:
  content: "AI pipeline success rate below 95%. Check error logs and AI API status."
conditions:
  - displayName: "Success rate < 95%"
    conditionThreshold:
      filter: 'metric.type="logging.googleapis.com/user/ai_pipeline_success_rate"'
      aggregations:
        - alignmentPeriod: 300s
          perSeriesAligner: ALIGN_MEAN
      comparison: COMPARISON_LT
      thresholdValue: 0.95
      duration: 300s
notificationChannels:
  - projects/abundance-prod/notificationChannels/SLACK_CHANNEL
```

## 6. Notification Channels

### Slack Webhook

```bash
# Create Slack notification channel
gcloud alpha monitoring channels create \
  --display-name="Abundance Slack" \
  --type=slack \
  --channel-labels=url=https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  --project=abundance-prod
```

### Email

```bash
# Create email notification channel
gcloud alpha monitoring channels create \
  --display-name="On-Call Team" \
  --type=email \
  --channel-labels=email_address=oncall@abundance.com \
  --project=abundance-prod
```

### PagerDuty (for critical alerts)

```bash
# Create PagerDuty notification channel
gcloud alpha monitoring channels create \
  --display-name="PagerDuty Critical" \
  --type=pagerduty \
  --channel-labels=service_key=YOUR_PAGERDUTY_SERVICE_KEY \
  --project=abundance-prod
```

## 7. Log Queries (Cloud Logging)

### Query Examples

```sql
-- All errors in last 24 hours
resource.type="cloud_function"
severity="ERROR"
timestamp>="2025-11-09T00:00:00Z"

-- AI pipeline failures
resource.type="cloud_function"
jsonPayload.message="AI pipeline failed"
timestamp>="2025-11-09T00:00:00Z"

-- Slow requests (>10s)
resource.type="cloud_function"
jsonPayload.duration>10000
timestamp>="2025-11-09T00:00:00Z"

-- Gemini API errors
resource.type="cloud_function"
jsonPayload.message="Gemini extraction failed"
timestamp>="2025-11-09T00:00:00Z"

-- Cost tracking (AI usage)
resource.type="cloud_function"
jsonPayload.message="AI API usage"
timestamp>="2025-11-09T00:00:00Z"

-- User actions
resource.type="cloud_function"
jsonPayload.userId="user123"
timestamp>="2025-11-09T00:00:00Z"
```

### Export Logs to BigQuery

```bash
# Create log sink to BigQuery
gcloud logging sinks create abundance-logs-bigquery \
  bigquery.googleapis.com/projects/abundance-prod/datasets/logs \
  --log-filter='resource.type="cloud_function"' \
  --project=abundance-prod
```

## 8. SLO Monitoring

### Service Level Objectives

```yaml
# slo-availability.yaml
displayName: "Availability SLO (99.9%)"
goal: 0.999
rollingPeriod: 2592000s # 30 days
serviceLevelIndicator:
  requestBased:
    goodTotalRatio:
      goodServiceFilter: 'resource.type="cloud_function" AND metric.type="cloudfunctions.googleapis.com/function/execution_count" AND metric.labels.status="ok"'
      totalServiceFilter: 'resource.type="cloud_function" AND metric.type="cloudfunctions.googleapis.com/function/execution_count"'
```

### Create SLO

```bash
# Create SLO
gcloud monitoring slos create availability-slo \
  --service=abundance-backend \
  --slo-from-file=slo-availability.yaml \
  --project=abundance-prod
```

## 9. Operational Runbook

### Incident Response

```markdown
## Alert: High Error Rate

**Trigger**: Error rate > 5% for 5 minutes

**Investigation Steps**:
1. Check Cloud Logging for error messages
2. Identify failing function (analyzeItem, retryFailedItems, etc)
3. Check AI API status (Gemini, Claude, SerpAPI)
4. Verify Firestore/Storage connectivity
5. Check recent deployments (potential bad deploy)

**Mitigation**:
1. Rollback to previous deployment if recent deploy
2. Disable scheduled jobs if quota exceeded
3. Scale down max instances if cost concern
4. Contact on-call engineer if critical

**Escalation**:
- Primary: oncall@abundance.com
- Secondary: PagerDuty #abundance-backend
```

## Cross-References

- **CODE-EXAMPLE-005**: See logging in Cloud Functions
- **CODE-EXAMPLE-006**: See performance logging in queries
- **CODE-EXAMPLE-007**: See AI pipeline logging
- **INFRASTRUCTURE-001**: See deployment monitoring
- **RESEARCH-VALIDATION-stage-3.2**: Verified Cloud Logging pricing

## Notes

- Use structured JSON logging (automatically parsed by Cloud Logging)
- Log at appropriate severity levels (INFO, WARNING, ERROR, CRITICAL)
- Include userId, itemId in all logs for traceability
- Set alert thresholds based on SLOs (99.9% availability = <0.1% error rate)
- Use log-based metrics for custom business metrics (cost, success rate)
- Export logs to BigQuery for long-term analysis
- Create runbooks for all alert policies
- Test alert policies in staging environment
- Review dashboards weekly in team meetings
