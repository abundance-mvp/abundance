# Core Data Documentation

**Source**: https://sosumi.ai/documentation/coredata
**Fetched**: 2025-11-02

## Overview

Core Data is Apple's framework for object modeling and management in macOS and iOS applications. The documentation provides comprehensive coverage of data persistence, object management, and store coordination.

## Key Sections

### Essentials

The foundational topics include:
- Creating a Core Data model
- Setting up a Core Data stack with `NSPersistentContainer`
- Legacy stack setup options for backward compatibility

### Stack Setup

**NSPersistentContainer** serves as the primary interface for configuring and managing the Core Data stack. It provides:
- Container initialization with managed object models
- Access to the view context and background contexts
- Methods for performing background tasks asynchronously

### Object Modeling

The framework includes several key classes for defining your data structure:

**NSManagedObjectModel** represents the schema and supports:
- Loading models from files or creating programmatically
- Merging multiple models together
- Managing entities and configurations
- Working with fetch request templates

**NSEntityDescription** defines individual entities with:
- Property management (attributes and relationships)
- Inheritance hierarchies
- Indexes and uniqueness constraints
- Versioning information

**NSPropertyDescription** serves as the base for properties, supporting:
- Validation predicates
- Spotlight indexing
- Version hashing for migrations

**NSAttributeDescription** defines specific attributes with support for multiple types including string, integer, date, decimal, UUID, and transformable types.

**NSRelationshipDescription** defines connections between entities, supporting:
- One-to-one and one-to-many relationships
- Delete rules (cascade, deny, nullify, no action)
- Ordered relationships

### Object Management

**NSManagedObjectContext** manages the lifecycle of objects in memory:
- Supports main queue and private queue concurrency types
- Provides fetching, insertion, and deletion operations
- Handles change tracking and notifications
- Manages save operations and undo functionality

**NSManagedObject** represents individual data objects with:
- Identity through `NSManagedObjectID`
- State tracking (inserted, updated, deleted, fault status)
- Key-value coding support
- Change event callbacks (`awakeFromFetch()`, `willSave()`, etc.)
- Data validation methods

### Store Coordination

**NSPersistentStoreCoordinator** manages the connection between contexts and persistent stores:
- Adds, removes, and migrates stores
- Manages store metadata
- Supports multiple store types (SQLite, binary, XML, in-memory)
- Handles persistent history tracking

**NSPersistentStore** represents individual data stores with:
- Configuration management
- Metadata handling
- Read-only modes
- Core Spotlight integration

**NSPersistentStoreDescription** configures store behavior including:
- Cloud Kit container options
- Migration settings
- SQLite pragmas
- File protection options

### Batch Operations

The framework supports efficient bulk modifications:
- Batch insert requests
- Batch update requests
- Batch delete requests

### Store Types Available

The framework supports several persistent store implementations:
- `sqlite`: SQLite-based relational storage
- `binary`: Binary format storage
- `xml`: XML-based storage
- `inMemory`: Temporary in-memory storage

### Validation and Error Handling

Core Data provides extensive validation support with numerous error codes covering:
- Constraint violations
- Missing mandatory properties
- Relationship cardinality violations
- Numeric and string validation errors
- Migration-related errors

### Advanced Features

**NSAtomicStore** and **NSIncrementalStore** allow custom store implementations for specialized data sources.

**NSCoreDataCoreSpotlightDelegate** integrates Core Data with the system's search functionality.

The framework supports deferred lightweight migrations and persistent history tracking for change management.

## Data Modeling

Core Data provides tools for:
- Defining entities with attributes and relationships
- Configuring indexes for performance optimization
- Setting up uniqueness constraints
- Generating code from models
- Implementing data validation rules
