# MLModelConfiguration API Reference

**Source**: https://sosumi.ai/documentation/coreml/mlmodelconfiguration
**Fetched**: 2025-11-02

## Overview

`MLModelConfiguration` is a class that establishes settings for creating or updating machine learning models in CoreML. It enables developers to customize how models load and execute on Apple platforms.

**Availability:** iOS 12.0+, iPadOS 12.0+, macOS 10.14+, tvOS 12.0+, visionOS 1.0+, watchOS 5.0+, Mac Catalyst 13.1+

## Primary Use Cases

The configuration class allows you to:

1. **Set or override model parameters** – Customize parameter values during model initialization
2. **Designate computational devices** – Direct model inference to specific hardware (GPU, CPU, Neural Engine)
3. **Restrict device categories** – Limit processing to particular computational unit types

## Key Configuration Properties

### Compute Unit Selection
- **`computeUnits`** – Specifies which processing units (CPU, GPU, Neural Engine, or combinations) the model uses for predictions
- **`MLComputeUnits`** – Enumeration defining available processing-unit configurations

### GPU Optimization
- **`preferredMetalDevice`** – Designates the specific Metal device for inference and model updates
- **`allowLowPrecisionAccumulationOnGPU`** – Boolean flag enabling reduced-precision GPU accumulation for performance optimization

### Parameter Configuration
- **`parameters`** – Dictionary allowing runtime override of model configuration settings
- **`MLParameterKey`** – Keys for accessing the parameter dictionary

### Model Metadata
- **`functionName`** – Specifies which function the model executes
- **`modelDisplayName`** – Human-readable identifier for UI presentation

### Performance Hints
- **`optimizationHints`** – Group of optimization directives for CoreML engine

## Typical Usage Pattern

Initialize the configuration and apply it when loading a model:

```swift
MLModel.init(contentsOf:configuration:)
```

Or when creating update tasks for on-device personalization workflows.

## Class Structure

**Inherits from:** NSObject

**Protocols:** NSCoding, NSCopying, NSSecureCoding, Equatable, Hashable, and others

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
