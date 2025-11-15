# Files and Directories - Apple Developer Documentation

**Source**: https://sosumi.ai/documentation/technologyoverviews/files-and-directories
**Fetched**: 2025-11-02

## Overview
Apple's file system documentation guides developers on navigating file systems across Apple devices, locating essential directories, and managing app documents and files effectively.

## Core Concepts

### File System Fundamentals
"The file system stores data files, apps, and the operating system itself." Most Apple disks use APFS (Apple File System), which provides modern features including cloning, snapshots, and atomic safe-save operations. Developers should leverage system frameworks like Foundation to ensure consistent file access across different disk formats.

### File Path Best Practices
When constructing file paths, developers should:
- Begin paths from well-known directories rather than the root or current working directory
- Use forward-slash characters to separate path components
- Treat directory and filenames as case-sensitive
- Include filename extensions for all files
- Display only user-friendly display names in interfaces

### Well-Known Directories
The system organizes content into designated locations, each serving specific purposes. The Foundation framework's URL and FileManager types provide access to these standardized directory paths.

### Bundles
Bundles are directories presented as single files to users. "Bundles simplify people's interactions with apps, app extensions, and other bundled items." Xcode automatically generates bundle structures during build time.

### File Packages
Unlike bundles, file packages lack predefined structures. They enable custom document formats containing multiple resource types and require developer-defined organization.

### Asset Catalogs
These organize images, icons, colors, and resources, allowing the system to serve appropriate resource versions based on device specifications and user settings.

## File Management

### Reading and Writing Files
System-provided objects like FileDocument, UIDocument, and NSDocument handle file operations automatically. The FileManager type provides fundamental file system access, while Data and FileHandle objects enable custom file operations.

### Background Downloads
The Background Assets framework supports scheduling large file downloads after app installation, enabling faster initial delivery of essential content.

### File Protection
Developers should assign URLFileProtection values to encrypt files on disk, selecting protection levels appropriate to data sensitivity. "Enable automatic encryption for files you create by assigning an appropriate URLFileProtection to each one."
