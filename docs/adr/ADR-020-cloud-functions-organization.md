# ADR-020: Cloud Functions Organization

**Status**: Approved
**Date**: 2025-11-08
**Decision Makers**: Cloud Backend Architect
**Related Documents**:
- docs/design/CLOUD-FUNCTIONS-001-function-structure.md
- docs/adr/ADR-007-api-architecture.md

---

## Context

The backend needs serverless compute for REST API and AI pipeline. Options:
- Cloud Functions (serverless, event-driven)
- App Engine (PaaS, always-on)
- Cloud Run (containers, serverless)

Also need to decide:
- Function granularity (one function per endpoint vs monolith)
- Trigger strategy (HTTP vs Firestore vs Pub/Sub)

---

## Decision

Use **Cloud Functions 2nd gen** with **one function per endpoint** and **Firestore triggers** for AI pipeline.

**Categories**:
1. HTTP endpoints (8 functions) - REST API
2. Firestore triggers (3 functions) - AI pipeline
3. Scheduled jobs (2 functions) - Maintenance

---

## Rationale

### Why Cloud Functions Over App Engine

**Cloud Functions Advantages**:
- Pay-per-invocation (not always-on)
- Auto-scaling (0 to millions)
- Firebase integration (Auth, Firestore)

**App Engine Disadvantages**:
- Always-on (costs even when idle)
- Less flexible scaling

### Why Cloud Functions Over Cloud Run

**Cloud Functions Advantages**:
- Simpler deployment (no Docker)
- Firebase CLI integration
- Automatic HTTPS endpoints

**Cloud Run Disadvantages**:
- Requires container management
- More complex deployment

### Why One Function Per Endpoint

**Decision**: Separate functions (not monolith HTTP handler)

**Rationale**:
- Independent scaling (busy endpoints scale separately)
- Easier debugging (isolated logs)
- Faster deployments (deploy single function)

**Trade-off**: More functions = more cold starts (acceptable for MVP)

### Why Firestore Triggers for AI Pipeline

**Decision**: `onItemCreated`, `onLayer2aComplete`, `onLayer2bComplete`

**Rationale**:
- Automatic invocation (no polling)
- Guaranteed execution (at-least-once delivery)
- Decoupled architecture (layers don't call each other directly)

**Alternative**: Pub/Sub triggers (more complex setup, not needed for MVP)

---

## Alternatives Considered

### Alternative 1: Monolith HTTP Handler

**Approach**: Single Cloud Function with Express.js router

**Pros**:
- Fewer cold starts (one function stays warm)
- Shared dependencies

**Cons**:
- All endpoints scale together (inefficient)
- Harder to debug (shared logs)
- Slower deployments (entire app)

**Why Rejected**: Independent scaling is more valuable

### Alternative 2: Cloud Run

**Approach**: Containerized Node.js app

**Pros**:
- Full control (custom runtime)
- More mature ecosystem

**Cons**:
- Requires Docker expertise
- More complex deployment

**Why Rejected**: Cloud Functions simpler for MVP

---

## Implications

**Positive**:
- Independent scaling per endpoint
- Simple deployment (Firebase CLI)
- Automatic HTTPS endpoints

**Negative**:
- Cold starts (1-3s latency on first request)
- More functions to manage

**Mitigation**: Use Cloud Functions 2nd gen (faster cold starts), implement minimum instances for critical endpoints

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial ADR, Cloud Functions organization rationale | Cloud Backend Architect |
