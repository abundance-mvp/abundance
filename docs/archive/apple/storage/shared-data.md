# Shared Data - Apple Developer Documentation

**Source**: https://sosumi.ai/documentation/technologyoverviews/shared-data
**Fetched**: 2025-11-02

## Overview

The documentation explains how to distribute information across multiple devices using iCloud or facilitate data exchange between an app and its extensions.

## Multi-Device Data Sharing

Apple provides several approaches for synchronizing content:

**Game Save Framework**: Developers can implement the Game Save framework to synchronize gaming progress across devices, handling "conflict resolution and offline play" automatically.

**iCloud Key-Value Storage**: Use NSUbiquitousKeyValueStore to maintain preferences and configuration settings. This method supports "scalar values and property-list object types" with a limit of 1024 keys and 1MB total storage.

**iCloud Drive**: Access "an app-specific directory in the person's iCloud storage" through the FileManager method for document persistence.

**CloudKit Integration**: Leverage CloudKit or SwiftData/CoreData syncing to store structured data with "up to 1PB of storage for your app's public data."

## Same-Device Sharing

Apps operate within sandboxes for security. To share files between your app and extensions, configure "app groups" that create "a shared space on disk for multiple processes to share files."

## Remote Server Solutions

Developers managing their own servers can deploy a File Provider extension to oversee remote document access and synchronization between local and server storage.

## File Coordination

Implement file coordinators to prevent conflicts when multiple processes access shared files simultaneously.

## Custom Document Design

When developing proprietary formats:
- Use file packages for efficient network transfers
- Maintain platform consistency
- Include version numbers
- Store relevant state information
