# VNCoreMLModel API Documentation

**Source**: https://sosumi.ai/documentation/vision/vncoremlmodel
**Fetched**: 2025-11-02

## Overview

VNCoreMLModel is "A container for the model to use with Vision requests."

**Availability**: iOS 11.0+, iPadOS 11.0+, Mac Catalyst 13.1+, macOS 10.13+, tvOS 11.0+, visionOS 1.0+

## Purpose

Wraps Core ML models to enable their use with Vision framework recognition tasks. After training your model, instantiate this container to initialize VNCoreMLRequest objects for image recognition tasks.

## Key Members

**Initialization:**
- `init(for:)` - Creates a model container for Core ML requests

**Configuration Properties:**
- `featureProvider` - Optional object supporting inputs beyond Vision's standard capabilities
- `inputImageFeatureName` - Identifies which feature value Vision populates from the request handler

## Integration Pattern

1. Obtain trained Core ML model
2. Wrap it with VNCoreMLModel
3. Use container with Vision requests for image analysis and classification

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
