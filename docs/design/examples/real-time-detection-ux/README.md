# Real-time Object Detection UX Flow

**Purpose:** Visual reference for Sprint 3 Layer 1 real-time detection user experience

**Context:** These mockups guided the architectural pivot from single-photo capture to continuous real-time detection with visual feedback.

---

## User Experience Flow

### Current Architecture
```
Preview → [Capture Button] → Single Photo → Detect Objects
```

### Target Architecture (Sprint 3)
```
Preview → [Continuous Frames] → Real-time Detection → Draw Bounding Border + Classification
```

---

## Experience Phases

The user walks around cataloging items in a frictionless experience. The app provides real-time visual feedback when objects are detected.

### Phase 1: Continuous Object Detection

**File:** `test-01-p1.jpg`

Camera continuously scans for objects as the user moves around. No visual feedback yet - passive detection mode.

### Phase 2: Object Detected - Grey Glowing Border

**File:** `test-01-p2.jpg`

When an object is detected, a glowing grey border appears (similar to iOS Photos app selection). This signals the app is analyzing the object.

**Behavior:**
- Grey border pulses with subtle glow animation
- Indicates "object detected, classification in progress"
- User can continue moving or hold position for better classification

### Phase 3: Successfully Classified - Mint Green Border

**File:** `test-01-p3-success.png`

When classification confidence exceeds threshold, border transitions to bright mint green (`#B3FFE1`).

**Behavior:**
- Green border confirms "successfully cataloged"
- Same logic applies to barcode detection
- User can move on to next object

**Confidence Threshold Logic:**
- Object detected but low confidence → grey border (or no border if very low)
- Confidence exceeds threshold → mint green border
- Timeout after ~5 seconds → mint green even if classification below threshold
- Cropped image passes to Layer 2 regardless (with or without ideal classification)

### Phase 4: Background Pipeline Processing

**Files:** `test-01-p4_obj-1.png`, `test-01-p4_obj-2.png`

Behind the scenes, Layer 1 completes:
1. Crop detected objects into separate images
2. Extract classification metadata
3. Pass cropped images + metadata to Layer 2

**Example:** `test-01_boxes.jpeg` shows multiple objects detected simultaneously, each cropped separately.

---

## Technical Implementation

**Detection API:** Apple Vision framework with YOLOv11n CoreML model
**Confidence Threshold:** Real-time uses 0.40 (vs 0.60 for single-photo)
**Performance Target:** <30ms per frame for smooth UX
**Border Animation:** SwiftUI overlay with glow effect

**Related Code:**
- `Sources/VisionCore/Services/HouseholdItemDetector.swift:detectInStream()`
- Sprint 3 ViewModels for real-time state management

---

## Test Assets

- `test-household-item.jpg` - Original test image for single-photo detection
- `test-desk-items.jpg` - Multi-object desk scene
- `test-detection.swift` - Swift code snippet for detection logic
- `test-yolo11n.py` - Python script for YOLO model testing
- `yolo11n.pt` - YOLOv11n model weights for testing

---

**Created:** 2025-11-15
**Sprint:** Sprint 3 - Real-time Detection Layer 1
**Status:** Reference documentation for implemented feature
