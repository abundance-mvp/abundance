# Structured Data Models

**Source**: https://sosumi.ai/documentation/technologyoverviews/structured-data-models
**Fetched**: 2025-11-02

## Overview

Apple provides frameworks for building and persisting structured data models in applications. The documentation covers three primary approaches:

## Key Frameworks

**Swift Data**
- Designed for SwiftUI-based applications
- "Infers information about your data structures from the structures themselves"
- Supports local disk storage and cross-device synchronization
- Includes undo/redo functionality and concurrency support
- Uses Model Container for organizing objects

**Core Data**
- Compatible with Objective-C and non-SwiftUI interfaces
- Visual schema modeling through Xcode
- Manages NSManagedObject instances
- Provides undo support and CloudKit integration
- Uses NSManagedObjectContext for coordination

**SQLite**
- Lightweight relational database available on all Apple platforms
- Suitable for applications already familiar with SQL
- Handles large datasets and network content delivery

## Key Capabilities

Both Swift Data and Core Data provide:
- Object-level data management
- Query-based data retrieval
- Data integrity features
- Undo/redo support
- Multi-threaded operation support

The choice depends on your development approach: Swift Data for modern SwiftUI apps, Core Data for broader compatibility, or SQLite for SQL-familiar developers managing substantial datasets.
