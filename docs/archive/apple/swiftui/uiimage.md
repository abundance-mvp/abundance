# UIImage API Documentation

**Source**: https://sosumi.ai/documentation/uikit/uiimage
**Fetched**: 2025-11-02

## Overview

UIImage is a foundational class for managing image data across Apple platforms. As stated in the documentation, it is "an object that manages image data in your app." The class handles all platform-native image formats and provides extensive capabilities for loading, manipulating, and rendering images.

**Availability:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS (undefined), visionOS 1.0+, watchOS 2.0+

## Key Characteristics

- **Immutable Design:** Image objects cannot be modified after creation, making them thread-safe
- **Format Support:** Optimized for PNG and JPEG; supports all platform-native formats
- **No Empty Canvas:** Cannot create blank images for drawing; requires existing image data

## Initialization Methods

### From Named Assets & Bundles
- `init(named:)` - Creates from specified named asset
- `init(named:in:compatibleWith:)` - Creates with trait collection compatibility
- `init(named:in:with:)` - Creates with specific configuration
- `init(imageLiteralResourceName:)` - Returns image for specified resource

### From System Symbols
- `init(systemName:)` - Creates standard symbol image
- `init(systemName:withConfiguration:)` - Symbol with custom configuration
- `init(systemName:variableValue:configuration:)` - Symbol with variable values

### From File & Data Sources
- `init(contentsOfFile:)` - Loads from file path
- `init(data:)` - Creates from NSData object
- `init(data:scale:)` - Creates with specified scale factor
- `init(cgImage:)`, `init(cgImage:scale:orientation:)` - From Core Graphics
- `init(ciImage:)`, `init(ciImage:scale:orientation:)` - From Core Image

### Animated Images
- `animatedImage(with:duration:)` - From image sequence
- `animatedImageNamed(_:duration:)` - From named assets
- `animatedResizableImageNamed(_:capInsets:duration:)` - With cap insets

## Image Manipulation Methods

### Resizing & Stretchable Images
- `resizableImage(withCapInsets:)` - Creates stretchable image
- `resizableImage(withCapInsets:resizingMode:)` - With specific mode

### Orientation & Layout
- `imageFlippedForRightToLeftLayoutDirection()` - RTL-aware flipping
- `withHorizontallyFlippedOrientation()` - Mirror image horizontally
- `withBaselineOffset(fromBottom:)` - Adjust baseline position
- `imageWithoutBaseline()` - Remove baseline information

### Rendering & Styling
- `withRenderingMode(_:)` - Apply rendering mode
- `withTintColor(_:)` - Apply tint color
- `withTintColor(_:renderingMode:)` - Tint with mode
- `withConfiguration(_:)` - Replace configuration attributes
- `applyingSymbolConfiguration(_:)` - Apply symbol attributes

### Alignment
- `withAlignmentRectInsets(_:)` - Set alignment metadata

## Format Conversion & Export

- `jpegData(compressionQuality:)` - Export as JPEG with quality control
- `pngData()` - Export as PNG (lossless)
- `heicData()` - Export as HEIC format
- `cgImage` property - Access Core Graphics representation
- `ciImage` property - Access Core Image representation

## Performance Optimization

### Display Preparation
- `preparingForDisplay()` - Synchronous decoding for immediate use
- `prepareForDisplay(completionHandler:)` - Asynchronous decoding
- `preparingThumbnail(of:)` - Synchronous thumbnail generation
- `prepareThumbnail(of:completionHandler:)` - Async thumbnail on background thread

## Drawing Methods

- `draw(at:)` - Draw at specified point
- `draw(at:blendMode:alpha:)` - Draw with compositing options
- `draw(in:)` - Draw scaled to rectangle
- `draw(in:blendMode:alpha:)` - Rectangle with compositing
- `drawAsPattern(in:)` - Tiled pattern drawing

## Image Properties

### Dimensions & Scale
- `size` - Logical dimensions in points
- `scale` - Scale factor of image

### Attributes
- `imageOrientation` - Display orientation
- `duration` - Animation display interval
- `capInsets` - End-cap inset values
- `alignmentRectInsets` - Layout positioning metadata
- `isSymbolImage` - Boolean for symbol image detection
- `isHighDynamicRange` - Boolean for HDR capability

### Configuration
- `configuration` - Configuration details
- `symbolConfiguration` - Symbol-specific configuration
- `traitCollection` - Describes image variant
- `renderingMode` - Rendering mode setting
- `resizingMode` - Image resizing mode

## Standard System Images

Predefined constants for common UI elements:
- `add` - Addition indicator
- `remove` - Removal indicator
- `actions` - User action indicator
- `checkmark` - Checkmark on filled circle
- `strokedCheckmark` - Checkmark with stroked border

## Important Usage Patterns

1. **Caching Strategy:** Use `init(named:)` for frequently-used images; it caches automatically
2. **Dynamic Loading:** Use `init(contentsOfFile:)` for one-time loads; reloads from disk each time
3. **Comparison:** The "only reliable way" to determine equality between images is using `isEqual(_:)`
4. **Image Assets:** Recommended for managing app images; supports variants for platforms, trait environments, and scale factors
5. **User-Supplied Images:** Use `UIImagePickerController` to request user permission and access camera/photo library

## Inheritance & Conformance

**Inherits from:** NSObject

**Conforms to:** CVarArg, Copyable, Equatable, Hashable, NSCoding, NSSecureCoding, Sendable, and multiple UIKit/Foundation protocols

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
