# ADR-019: Firestore Data Model Rationale

**Status**: Approved
**Date**: 2025-11-08
**Decision Makers**: Cloud Backend Architect
**Related Documents**:
- docs/specs/SPEC-DATA-001-firestore-schema.md
- docs/adr/ADR-006-database-selection.md

---

## Context

The backend needs a data storage solution for catalog items, user profiles, and capture sessions. Stage 2.1 selected Firestore (ADR-006), but specific data model decisions remain:
- Collection structure (top-level vs nested)
- Index strategy
- NoSQL vs SQL trade-offs

---

## Decision

Use **top-level Firestore collections** with **composite indexes** for common query patterns.

**Collections**:
- `users/{userId}` - User profiles
- `items/{itemId}` - Catalog items (with `userId` field for ownership)
- `sessions/{sessionId}` - Capture sessions (multi-item capture workflows, with `userId` field for ownership)

**Indexes**:
- `userId` + `createdAt` (list items by date)
- `userId` + `category` (filter by category)
- `userId` + `status` (pending items)

---

## Rationale

### Why NoSQL Over SQL

**Requirement**: Real-time sync, offline-first, flexible schema

**Firestore Advantages**:
- Built-in real-time listeners (iOS SDK)
- Automatic offline persistence
- Flexible schema (AI results evolve over time)
- Scales automatically (no manual sharding)

**SQL Disadvantages**:
- Requires polling or WebSockets for real-time sync
- Complex offline sync implementation
- Rigid schema (AI fields change frequently)

### Why Firestore Over DynamoDB

**Firestore Advantages**:
- Firebase ecosystem integration (Auth, Storage, Functions)
- Simpler security rules (row-level access)
- Better offline support (iOS SDK)

**DynamoDB Disadvantages**:
- Requires custom sync logic
- More complex access control (IAM + application layer)

### Why Top-Level Collections

**Decision**: `items/{itemId}` (not `users/{userId}/items/{itemId}`)

**Rationale**:
- Simpler queries (no collection group queries needed)
- Better performance (direct document access by ID)
- Easier to implement marketplace (query all items globally in Phase 2)

**Trade-off**: Security rules must check `userId` field (not relying on collection path)

---

## Alternatives Considered

### Alternative 1: Nested Subcollections

**Approach**: `users/{userId}/items/{itemId}`

**Pros**:
- Automatic ownership (path implies user)
- Easier security rules

**Cons**:
- Requires collection group queries (slower)
- Cannot query across all users (marketplace limitation)

**Why Rejected**: Phase 2 marketplace needs global item queries

### Alternative 2: SQL Database (Cloud SQL PostgreSQL)

**Approach**: Relational schema with foreign keys

**Pros**:
- ACID transactions
- Complex joins
- Mature ecosystem

**Cons**:
- No built-in real-time sync
- Complex offline implementation
- Rigid schema

**Why Rejected**: Real-time sync is core requirement, SQL doesn't support this natively

---

## Implications

**Positive**:
- Real-time catalog updates (iOS listeners)
- Offline-first (automatic persistence)
- Flexible schema (AI results evolve)

**Negative**:
- No complex joins (must fetch related data separately)
- Security rules must validate ownership manually

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial ADR, Firestore data model rationale | Cloud Backend Architect |
| 2026-02-08 | 1.1 | Replace `subscriptions` with `sessions` collection, fix spec reference path | Documentation Update |
