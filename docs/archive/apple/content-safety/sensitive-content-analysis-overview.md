# Sensitive Content Analysis Documentation

**Source**: https://sosumi.ai/documentation/sensitivecontentanalysis
**Fetched**: 2025-11-02

## Overview

Apple's SensitiveContentAnalysis framework enables developers to detect and respond to sensitive media content within their applications. The framework provides tools for analyzing both static media files and live video streams.

## Key Components

### Image and Video File Analysis

The `SCSensitivityAnalyzer` class handles analysis of stored media. Developers can instantiate it with `init()` and configure behavior through the `analysisPolicy` property. The framework supports analyzing images via `CGImage` objects or file URLs, with results delivered through completion handlers.

For video files, the `VideoAnalysisHandler` provides asynchronous analysis capabilities. The handler includes a "var progress: Progress" property for tracking analysis completion and the `hasSensitiveContent()` async method for determining results.

### Video Stream Analysis

The `SCVideoStreamAnalyzer` class processes live video streams. Developers initialize it with a participant UUID and stream direction (incoming or outgoing). The analyzer accepts pixel buffers through the `analyze(_:)` method and can integrate with capture devices or decompression sessions.

Real-time detection updates flow through the "var analysisChanges: some AsyncSequence" property, enabling reactive UI updates.

## Analysis Results

The `SCSensitivityAnalysis` object contains:
- Detection indicator: "var isSensitive: Bool"
- User intervention guidance through three boolean properties directing whether to display warnings, interrupt playback, or mute audio

## Analysis Policies

Three configuration levels exist:
- **Disabled**: No analysis performed
- **Simple Interventions**: Basic detection responses
- **Descriptive Interventions**: Enhanced guidance mechanisms

## Authorization

Implementation requires the "com.apple.developer.sensitivecontentanalysis.client" entitlement for bundle configuration.

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
