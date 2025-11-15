# SwiftUI Documentation Summary

**Source**: https://sosumi.ai/documentation/swiftui
**Fetched**: 2025-11-02

## Overview
SwiftUI is Apple's declarative UI framework for building user interfaces across iOS, iPadOS, macOS, watchOS, and tvOS. The documentation provides comprehensive guidance on app structure, navigation, presentations, and platform-specific features.

## Core Concepts

### App Structure
The framework organizes applications through several key architectural components:

- **App Protocol**: Defines the entry point with a `body` property and lifecycle methods like `main()`
- **Scenes**: Container types that organize content, supporting various configurations like `WindowGroup`, `ImmersiveSpace`, and `DocumentGroup`
- **Views**: Reusable UI components built with declarative syntax

### Navigation Patterns

SwiftUI offers modern navigation approaches replacing older methods:

- **NavigationStack**: "Stacking views in one column" for linear navigation flows
- **NavigationSplitView**: Multi-column layouts for sidebar-detail interfaces
- **NavigationLink**: Creating connections between views with value-based routing
- **TabView with Tab**: Tab-based organization with customization support

### Presentation Types

The framework supports various modal presentation styles:

- Sheets and full-screen covers
- Popovers with anchor points
- Alerts and confirmation dialogs
- Custom presentation sizing and detents

## Platform-Specific Features

### Window Management
- Window groups with identifiers and data-driven configurations
- Sizing, positioning, and resizability controls
- Window styles (default, plain, titled, volumetric)

### Immersive Spaces (visionOS)
- Full, mixed, and progressive immersion styles
- World alignment and scaling behaviors
- Surface snapping capabilities

### Document-Based Apps
- `FileDocument` and `ReferenceFileDocument` protocols
- `DocumentGroup` for file management
- Read/write configurations with type support

## Advanced Features

**Environment and State Management**:
- Scene phase monitoring (active, inactive, background)
- Model container and context configuration
- Environment value propagation

**Customization**:
- Toolbar styling and placement
- Command integration for menus
- Keyboard shortcuts and accessibility

**Data Persistence**:
- SwiftData integration with model containers
- App storage through UserDefaults
- Document-based storage options

The documentation emphasizes modern patterns like value-based navigation and environment-driven configuration over older deprecated approaches.
