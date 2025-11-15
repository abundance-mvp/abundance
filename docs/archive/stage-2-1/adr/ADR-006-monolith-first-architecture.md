# ADR-006: Monolith-First Backend Architecture

**Status:** Approved
**Date:** 2025-10-24
**Decision Makers:** Engineering Leadership, Backend Lead
**Related Documents:** TECH-STACK-001, ADR-005

---

## Context

Backend architecture decision for Abundance MVP: monolith vs. microservices

---

## Decision

**We will use a monolith-first architecture with Firebase Cloud Functions, following Martin Fowler's "Monolith First" pattern.**

### Architecture

```
Single Cloud Functions Deployment:
├── enrichItem() - Product enrichment
├── retryFailedEnrichments() - Scheduled retry
└── Future functions as needed
```

**NOT microservices:**
- ❌ Separate services for auth, enrichment, notifications
- ❌ Service mesh, API gateway
- ❌ Inter-service communication

---

## Rationale

### 1. Team Size (3-4 Engineers)

**Martin Fowler:** "Almost all successful microservice stories started with a monolith that got too big."

- Small team = monolith is faster
- Single codebase = easier code reviews
- No inter-service contracts to maintain

---

### 2. Unknown Boundaries

**Problem:** Don't know service boundaries yet (MVP is exploratory)

**Monolith:**
- Easy to refactor (single codebase)
- Extract microservices later when boundaries are clear

**Microservices:**
- Hard to change service boundaries (requires API versioning)
- Premature optimization

---

### 3. Deployment Simplicity

**Monolith:**
- Single deployment (`firebase deploy --only functions`)
- One version to test
- Rollback is instant (`firebase functions:delete`, redeploy previous)

**Microservices:**
- Multiple deployments (5-10 services)
- Version coordination (service A v2 requires service B v3)
- Complex rollback

---

## Alternatives Considered

### Alternative: Microservices (Separate Functions per Domain)

**Approach:**
- Separate Cloud Functions: `auth-service`, `enrichment-service`, `marketplace-service`
- API Gateway (Cloud Endpoints or Apigee)

**Pros:**
- Better separation of concerns
- Independent scaling (enrichment function can scale independently)

**Cons:**
- **Premature:** Marketplace doesn't exist yet (Phase 2)
- **Overkill:** 2 functions (enrichment + retry) don't need microservices
- **Slower:** More deployment complexity

**Why Rejected:** Team size + unknown boundaries = monolith is better

---

## Future Migration Path

**When to Extract Microservices (Month 12+):**
- Team grows to 8+ engineers (need parallel work)
- Functions exceed 10K lines of code
- Different scaling needs (e.g., marketplace traffic 10× higher than enrichment)

**Extraction Strategy:**
- Keep monolith as "enrichment service"
- Extract new service: "marketplace-service" (offers, transactions)
- Use Cloud Tasks for async communication

---

## Stakeholder Sign-Off

- [ ] **Engineering Leadership**

**Timeline:** Finalized by 2025-10-31

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-24 | 1.0 | Initial monolith-first decision | Stage 2.1 Execution |
