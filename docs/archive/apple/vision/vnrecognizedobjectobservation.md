# VNRecognizedObjectObservation API Documentation

**Source**: https://sosumi.ai/documentation/vision/vnrecognizedobjectobservation
**Fetched**: 2025-11-02

## Overview

`VNRecognizedObjectObservation` represents detected objects with classification data.

**Availability**: iOS 12.0+, macOS 10.14+

## Purpose

Extends object detection by adding "an array of classification labels that classify the recognized object." Framework ensures that "the confidence of the classifications sum up to 1.0," which developers should multiply by the observation's confidence for accurate scoring.

## Class Hierarchy

- **Inherits from:** `VNDetectedObjectObservation`
- **Key Protocols:** NSCoding, NSSecureCoding, Hashable, Equatable, CVarArg

## Key Components

**Labels Property:** The `labels` property contains an array of `VNClassificationObservation` objects, each representing classification information produced by image-analysis requests.

## Usage Pattern

1. Execute object detection request
2. Receive array of `VNRecognizedObjectObservation` results
3. Access `labels` array for classifications
4. Multiply label confidence by observation confidence for final score

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
