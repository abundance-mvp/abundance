# VisionKit Documentation Overview

**Source**: https://sosumi.ai/documentation/visionkit
**Fetched**: 2025-11-02

## Overview
VisionKit provides APIs for content recognition and interaction in images, barcode/text scanning via camera, and document scanning capabilities across Apple platforms.

## Core Components

### Image Analysis (`ImageAnalyzer`)
Analyzes images to recognize text, machine-readable codes, and visual subjects. Key features:

- **Availability checking**: `isSupported` property and `supportedTextRecognitionLanguages`
- **Analysis types**: Text recognition, barcode detection, and visual lookup
- **Configuration**: Customizable analysis types and language locales
- **Multiple input formats**: Supports UIImage, NSImage, CGImage, CVPixelBuffer, CIImage, and URLs

**Key method**: `analyze()` function accepts various image formats with optional orientation parameters, returning `ImageAnalysis` results asynchronously.

### Image Interaction (`ImageAnalysisInteraction`)
Enables user interactions with analyzed image content on iOS/iPadOS:

- Text selection and data detector interactions
- Image subject highlighting and extraction
- Customizable interaction types (automatic, text-only, visual lookup)
- Interface state querying and supplementary UI customization

### Overlay Views (`ImageAnalysisOverlayView`)
macOS counterpart providing similar functionality with additional features:

- Context menu management with framework-provided items
- Menu tag system for copy, share, and lookup operations
- Key and menu event handling through delegate methods

## Data Scanner (`DataScannerViewController`)

Real-time barcode and text recognition through the device camera:

**Supported recognition types**:
- Text with specific content types (URLs, emails, phone numbers, addresses, etc.)
- Barcodes with configurable symbologies

**Configuration options**:
- Quality levels: balanced, fast, accurate
- Features: pinch-to-zoom, guidance display, highlighting
- Multiple item recognition and high frame rate tracking

**Methods**: `startScanning()`, `stopScanning()`, and async `recognizedItems` stream for real-time results.

## Document Camera (`VNDocumentCameraViewController`)

Specialized scanning for document capture and processing:

- Platform support checking via `isSupported`
- Delegate pattern for handling scan results
- Page management through `VNDocumentCameraScan` with `pageCount` and image extraction
- Error handling through delegate callbacks

## Key Interfaces

**Delegation patterns** enable custom interface behavior and event handling across all components, allowing developers to customize highlighting, respond to user interactions, and manage specialized UI elements.

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
