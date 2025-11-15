# AVFoundation Documentation

**Source**: https://sosumi.ai/documentation/avfoundation
**Fetched**: 2025-11-02

AVFoundation is Apple's framework for working with audiovisual media on iOS, macOS, and related platforms.

## Core Components

### Media Assets
The framework centers on the `AVAsset` class, which represents a collection of media data. You can create assets from URLs using `AVURLAsset` and access their properties asynchronously.

**Key Asset Properties:**
- Duration and timing information
- Track data (audio, video, metadata)
- Metadata and creation information
- Playability and compatibility status
- Media selections and chapter information

### Asset Tracks
Individual media streams within an asset are represented by `AVAssetTrack` objects. These tracks contain:
- Format descriptions and decodability status
- Temporal information (timeRange, frameRate)
- Language support and characteristics
- Visual and audible properties
- Associated metadata

### Metadata Management
The framework provides comprehensive metadata handling through:
- `AVMetadataItem` for reading metadata
- `AVMutableMetadataItem` for creating/modifying metadata
- Extensive identifier constants for common, iTunes, QuickTime, ID3, and format-specific metadata
- Filtering and language-based selection capabilities

## Asynchronous Loading

Modern AVFoundation uses `AVAsyncProperty` for non-blocking property access. This allows applications to load media information without blocking the main thread, improving responsiveness.

## Supported Features

- Protected content handling
- Fragmented media support
- Asset caching for offline playback
- Resource loading customization
- Multiple media selection options
- Chapter metadata extraction
