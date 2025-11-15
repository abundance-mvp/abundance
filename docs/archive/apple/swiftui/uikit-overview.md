# UIKit Documentation Overview

**Source**: https://sosumi.ai/documentation/uikit
**Fetched**: 2025-11-02

This document provides a comprehensive reference for Apple's UIKit framework, which is the foundational framework for building iOS applications with a graphical user interface.

## Core Structure

UIKit is organized around several primary components:

### App Management
The framework centers on `UIApplication`, described as "the shared application instance" that manages the app's overall behavior and state. Developers access this through `class var shared: UIApplication`.

### Application Lifecycle
UIKit defines several key lifecycle states:
- **Active**: App is running and receiving events
- **Inactive**: App is running but not receiving events
- **Background**: App is not visible to the user
- **Unattached**: Scene is not connected

### Scene Architecture
Modern UIKit apps use scenes to manage multiple windows. `UIWindowScene` represents a window and its associated interface, supporting features like multiple windows on iPad and external displays.

## Key Delegate Patterns

**UIApplicationDelegate** handles app-level events including:
- Launch initialization (`willFinishLaunching`, `didFinishLaunching`)
- Lifecycle transitions (foreground/background)
- Remote notifications
- URL handling
- State restoration

**UISceneDelegate** manages scene-specific lifecycle events and user interactions.

## Notable Features

- **State Restoration**: Apps can preserve and restore UI across launches
- **Background Tasks**: Support for background fetching and processing
- **Interface Orientation**: Management of portrait/landscape modes
- **Content Size Categories**: Dynamic type support for accessibility
- **Window Management**: Control over window geometry and presentation styles

## Modern Additions

Recent UIKit updates introduce:
- Liquid Glass design adoption support
- Enhanced privacy protections
- Improved windowing controls for macOS/visionOS
- Advanced scene activation and placement options

This framework remains essential for developers building native iOS experiences.
