# AVCaptureSession API Documentation

**Source**: https://sosumi.ai/documentation/avfoundation/avcapturesession
**Fetched**: 2025-11-02

## Overview

`AVCaptureSession` is a foundational class in AVFoundation that serves to "configure capture behavior and coordinate the flow of data from input devices to capture outputs."

## Availability

- iOS 4.0+
- iPadOS 4.0+
- Mac Catalyst 14.0+
- macOS 10.7+
- tvOS 17.0+
- visionOS 1.0+

## Core Purpose

The class manages real-time media capture by orchestrating connections between input devices (microphones, cameras) and outputs (video writers, preview displays). Developers instantiate a session, add appropriate inputs and outputs, then control the data flow through lifecycle methods.

## Session Lifecycle Management

### Starting and Stopping

- **startRunning()** — Initiates the flow of data through the capture pipeline
- **stopRunning()** — Halts the flow of data through the capture pipeline

### Critical Threading Requirement

"The startRunning() method is a blocking call which can take some time, therefore start the session on a serial dispatch queue so that you don't block the main queue (which keeps the UI responsive)."

## Configuration Methods

- **beginConfiguration()** — Marks the start of atomic changes to a running session
- **commitConfiguration()** — Applies one or more changes in a single atomic update

## Input Management

- **canAddInput(_:)** — Validates whether an input can be added
- **addInput(_:)** — Adds a capture input to the session
- **removeInput(_:)** — Removes an input from the session
- **inputs** — Property containing all session inputs

## Output Management

- **canAddOutput(_:)** — Validates whether an output can be added
- **addOutput(_:)** — Adds an output to the session
- **removeOutput(_:)** — Removes an output from the session
- **outputs** — Property containing all session outputs

## Connection Management

- **connections** — Contains all input-output connections
- **canAddConnection(_:)** — Validates connection feasibility
- **addConnection(_:)** — Establishes input-output connections
- **addInputWithNoConnections(_:)** — Adds input without automatic connections
- **addOutputWithNoConnections(_:)** — Adds output without automatic connections
- **removeConnection(_:)** — Removes a connection

## Session Presets

The **sessionPreset** property customizes output quality, bitrate, and other settings. Presets provide common configurations; use **canSetSessionPreset(_:)** to verify compatibility before applying.

Specialized options like high frame rate require direct format configuration on `AVCaptureDevice` instances rather than presets.

## Session State Monitoring

- **isRunning** — Boolean indicating active capture state
- **isInterrupted** — Boolean indicating interruption status
- **didStartRunningNotification** — Posted when session starts
- **didStopRunningNotification** — Posted when session stops
- **wasInterruptedNotification** — Posted during interruption
- **interruptionEndedNotification** — Posted when interruption ends
- **runtimeErrorNotification** — Posted when capture errors occur

## Audio Session Integration

- **usesApplicationAudioSession** — Enables shared audio session usage
- **automaticallyConfiguresApplicationAudioSession** — Auto-configures app audio settings
- **configuresApplicationAudioSessionToMixWithOthers** — Allows audio mixing
- **configuresApplicationAudioSessionForBluetoothHighQualityRecording** — Enables Bluetooth optimization

## Performance & Hardware

- **hardwareCost** — Percentage of available hardware budget in use
- **isMultitaskingCameraAccessSupported** — Indicates multitasking camera capability
- **isMultitaskingCameraAccessEnabled** — Controls camera access during multitasking

## Class Hierarchy

- **Inherits from:** NSObject
- **Inherited by:** AVCaptureMultiCamSession
- **Conforms to:** CVarArg, CustomDebugStringConvertible, CustomStringConvertible, Equatable, Hashable, NSObjectProtocol

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
