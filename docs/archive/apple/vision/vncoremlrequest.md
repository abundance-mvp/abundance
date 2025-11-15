# VNCoreMLRequest API Documentation

**Source**: https://sosumi.ai/documentation/vision/vncoremlrequest
**Fetched**: 2025-11-02

## Overview

`VNCoreMLRequest` is a Vision framework class that enables image analysis using Core ML models. It allows developers to process images with trained machine learning models in iOS and macOS applications.

**Purpose:** "An image-analysis request that uses a Core ML model to process images."

## Availability

- iOS 11.0+
- iPadOS 11.0+
- Mac Catalyst 13.1+
- macOS 10.13+
- tvOS 11.0+
- visionOS 1.0+

## Inheritance & Conformance

**Inherits from:** `VNImageBasedRequest`

**Conforms to:** CVarArg, CustomDebugStringConvertible, CustomStringConvertible, Equatable, Hashable, NSCopying, NSObjectProtocol

## Initialization Methods

1. **`init(model:)`** - Creates a model container for image analysis based on the provided Core ML model
2. **`init(model:completionHandler:)`** - Creates a model container with an optional completion handler

## Core Properties

- **`model`** - The Core ML model that powers the image analysis request
- **`imageCropAndScaleOption`** - Configuration for how Vision scales input images

## Result Types

The observation type returned depends on model characteristics:

1. **Classification models** - Returns `VNClassificationObservation` objects when the model predicts a single feature
2. **Image-to-image models** - Returns `VNPixelBufferObservation` objects with image-type outputs
3. **General predictor models** - Returns `VNCoreMLFeatureValueObservation` objects

## Important Usage Notes

⚠️ **Confidence Values:** "Vision forwards all confidence values from Core ML models as-is and doesn't normalize them to `[0, 1]`."

## Related Resources

- `VNCoreMLModel` - Container wrapper for Core ML models
- `VNImageCropAndScaleOption` - Image preprocessing options
- Reference tutorials on flower classification and image classification with Vision

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
