# Apple Vision Framework Documentation

**Source**: https://sosumi.ai/documentation/vision
**Fetched**: 2025-11-02

## Overview

The Vision framework provides computer vision capabilities for analyzing images and video sequences. It includes tools for image classification, object detection, text recognition, pose estimation, and more.

## Still-Image Analysis

### Image Classification

**ClassifyImageRequest** enables image categorization and search functionality. Create requests using:
- `init(ClassifyImageRequest.Revision?)`
- Supported revision: `case revision2`

The framework offers crop and scale actions including `centerCrop`, `scaleToFit`, `scaleToFill`, and rotation variants.

**ClassificationObservation** provides results with properties like `identifier` and `confidence`. It supports precision-recall curve analysis through methods like `hasMinimumPrecision(_:forRecall:)`.

### Lens Smudge Detection

**DetectLensSmudgeRequest** identifies lens obstructions with:
- Revision: `case revision1`
- Returns **SmudgeObservation** with confidence scores

## Image Sequence Analysis

### Person Segmentation and Instance Masking

**GeneratePersonSegmentationRequest** creates pixel-level person masks with quality levels: `accurate`, `balanced`, and `fast`. Supports frame analysis spacing configuration.

**GeneratePersonInstanceMaskRequest** generates instance-level masks, allowing per-person identification.

**DetectDocumentSegmentationRequest** segments document regions, returning **DetectedDocumentObservation** with global segmentation masks.

### Supporting Types

**PixelBufferObservation** provides pixel data access through:
- `cgImage` property
- `pixel(at:)` method for individual pixel queries
- `withUnsafePointer(_:)` for direct memory access

## Image Aesthetics Analysis

**CalculateImageAestheticsScoresRequest** evaluates image quality with properties:
- `isUtility`: Indicates utility-focused images
- `overallScore`: Composite quality metric

## Saliency Analysis

**GenerateAttentionBasedSaliencyImageRequest** produces attention-based heatmaps showing regions of visual interest, returning **SaliencyImageObservation** with a `heatMap` property.

## Request Handling

### ImageRequestHandler

Create handlers for various image sources:
- `init(URL, orientation:)`
- `init(Data, orientation:)`
- `init(CGImage, orientation:)`
- `init(CVPixelBuffer, depthData:, orientation:)`
- `init(CMSampleBuffer, depthData:, orientation:)`
- `init(CIImage, orientation:)`

Execute requests using:
- `perform<T>(T)` for single requests
- `perform(repeat each T)` for multiple requests
- `performAll(some Collection)` for async sequences

## Request Base Types

**VisionRequest** provides compute device management through `computeDevice(for:)` and `setComputeDevice(_:for:)` methods supporting `main` and `postProcessing` stages.

**VisionObservation** is the base type for all results, offering `uuid`, `confidence`, `description`, and `originatingRequestDescriptor` properties.

## Result Handling

**VisionResult** is an enum capturing request outcomes across multiple categories including still-image, sequence, aesthetics, saliency, tracking, detection, and pose analysis results, plus error cases.
