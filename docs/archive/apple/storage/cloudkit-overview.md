# CloudKit Documentation

**Source**: https://sosumi.ai/documentation/cloudkit
**Fetched**: 2025-11-02

## Overview

CloudKit is Apple's framework for managing cloud-based data synchronization across iCloud. The documentation provides comprehensive guidance on implementing cloud storage, record management, and synchronization capabilities in Apple applications.

## Essential Starting Points

The framework documentation begins with foundational concepts:

- **Decision Making**: Guidance on whether CloudKit suits your application's needs
- **Setup**: Instructions for enabling CloudKit functionality within your app

## Core Concepts

### Record Zones
Record zones are organizational containers within CloudKit databases. Developers can create custom zones using `CKRecordZone` with specified names or zone IDs. The framework provides a default zone for simpler use cases.

### Records
Records represent individual data objects. They are created with specific record types and can contain multiple fields with various data types. Records support metadata tracking including creation dates, modification dates, and user information.

### Assets
The `CKAsset` class manages file-based data, initialized with file URLs and providing access to those URLs for retrieval.

## Database Operations

### Transactions
- **Zone Modifications**: `CKModifyRecordZonesOperation` handles creating, updating, or deleting record zones
- **Record Modifications**: `CKModifyRecordsOperation` manages save and delete operations for records with configurable save policies

### Queries
Developers can retrieve data using `CKQuery` with predicates and sort descriptors. `CKQueryOperation` executes queries and processes results with customizable limits.

### Fetching
Fetch operations retrieve zones and records from the database, supporting progress tracking and per-record completion handlers.

## Synchronization Features

### Change Tracking
The framework monitors database and record zone changes through subscriptions and fetch operations, enabling applications to stay current with remote modifications.

### Sync Engine
`CKSyncEngine` provides automated synchronization of local and remote data. It manages pending changes, handles account transitions, and delivers events through a delegate pattern.

**Event handling**: "func handleEvent(CKSyncEngine.Event, syncEngine: CKSyncEngine) async"

## Sharing & Collaboration

Records support sharing through references, allowing users to collaborate on shared data. The framework distinguishes between simple references and zone-wide sharing capabilities.

## Notifications

Push notifications alert applications about remote changes, triggered by subscriptions to database, zone, or query-based events.

## State Management

The sync engine maintains serializable state for persistence across app sessions, tracking pending changes and synchronization progress.
