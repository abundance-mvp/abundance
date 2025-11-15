# Core ML Documentation Summary

**Source**: https://sosumi.ai/documentation/coreml
**Fetched**: 2025-11-02

Core ML is Apple's machine learning framework for integrating trained models into iOS, macOS, and other Apple platforms. The documentation provides comprehensive guidance on model loading, predictions, and app integration.

## Key Components

**Model Loading**
Core ML supports multiple loading approaches: `MLModel.load(contentsOf:configuration:)` for async loading, synchronous initialization with `init(contentsOf:)`, and completion handler-based methods. Models can be compiled using `compileModel(at:)` for optimized performance.

**Making Predictions**
The framework offers several prediction methods: `prediction(from:)` for single predictions, `predictions(fromBatch:)` for batch processing, and options to restrict computation to CPU via `MLPredictionOptions`. Models can also use custom compute units (CPU, GPU, or Neural Engine).

**Model Inspection**
Developers can examine model structure through `MLModelDescription`, accessing input/output specifications via `inputDescriptionsByName` and `outputDescriptionsByName`. Feature types include numeric, string, image, multiarray, dictionary, sequence, and state types.

**On-Device Updates**
The `MLUpdateTask` class enables model personalization through on-device training with configurable parameters like learning rate, momentum, and batch size. Progress handlers track training events including epoch completion and loss metrics.

**Feature Values**
Models handle diverse data types through `MLFeatureValue`: numeric values (int64, double), strings, images (from pixel buffers or CGImage), multiarrays, sequences, and dictionaries. Shaped arrays provide flexible tensor handling with various construction methods.

**App Integration**
Comprehensive examples cover tabular data, image classification, semantic segmentation, object detection, pose detection, text classification, and question-answering tasks.
