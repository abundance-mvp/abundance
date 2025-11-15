# VNImageRequestHandler API Documentation

**Source**: https://sosumi.ai/documentation/vision/vnimagerequesthandler
**Fetched**: 2025-11-02

## Overview

`VNImageRequestHandler` processes one or more image-analysis requests pertaining to a single image.

**Availability**: iOS 11.0+, iPadOS 11.0+, macOS 10.13+

## Image Source Support

Handler supports multiple image input formats:

- **Core Graphics images** via `init(cgImage:options:)`
- **Core Image data** through `init(ciImage:options:)`
- **Core Video pixel buffers** using `init(cvPixelBuffer:options:)`
- **CMSampleBuffer objects** with `init(cmSampleBuffer:options:)`
- **Image data** via `init(data:options:)`
- **URL-based images** using `init(url:options:)`

Each initializer offers orientation variants for cases where image rotation metadata is known.

## Workflow

1. Instantiate handler with image source
2. Optionally provide completion handler
3. Invoke `perform(_:)` method to execute requests

## Key Features

- Supports depth data integration for advanced imaging scenarios
- Configuration through image options via `VNImageOption` parameters
- Can execute multiple Vision requests on single image

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
