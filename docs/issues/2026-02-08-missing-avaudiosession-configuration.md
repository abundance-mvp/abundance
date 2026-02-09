---
date: 2026-02-08
status: Open
priority: P0
type: bug
component: ios
source: code-review
related-files:
  - Sources/CameraFeature/Services/CameraService.swift
screenshots: []
axiom-agent: axiom:camera-auditor
branch: null
design-doc: null
---

## Summary

Missing AVAudioSession configuration in CameraService blocks future video recording and risks app freezes.

## Description

CameraService initializes and configures AVCaptureSession for photo/video capture but has no AVAudioSession configuration. NSMicrophoneUsageDescription exists in Info.plist (line 7), indicating future audio intent. Without proper audio session setup, any attempt to add audio input will fail silently or freeze during `AVCaptureSession.startRunning()`.

## Expected Behavior

AVAudioSession should be configured early in the camera lifecycle with `.playAndRecord` category to support future video recording and prevent conflicts with other audio sources.

## Actual Behavior

No AVAudioSession configuration exists. Adding audio input to the capture session will fail.

## Technical Context

- Found by: `axiom:camera-auditor` during code review
- File: `CameraService.swift` — no `AVAudioSession.sharedInstance()` calls
- Info.plist already declares `NSMicrophoneUsageDescription`
- Other apps' audio sessions may leave the system in an incompatible state

## Proposed Solution

Add `setupAudioSession()` in `CameraService.init()` with `.playAndRecord` category and `.duckOthers` option.
