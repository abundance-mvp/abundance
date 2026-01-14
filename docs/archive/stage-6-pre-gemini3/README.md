# Stage 6 Archive (Pre-Gemini 3 Pro)

**Archived**: 2026-01-14
**Reason**: Superseded by Stage 7.0 (Gemini 3 Pro with native tool calling)

## What Was Archived

Stage 6 defined a validation framework for the original 4-model AI pipeline:
- Layer 1: iOS Vision + YOLO (on-device)
- Layer 2a: Gemini Flash-Lite (attribute extraction)
- Layer 2b: SerpAPI + Claude Haiku (product search + parsing)
- Layer 3: Claude Sonnet (synthesis)

## Why Archived

Stage 7.0 replaced the 4-model pipeline with a unified Gemini 3 Pro approach
that uses native tool calling (google_lens, barcode_lookup, web_search).
The validation framework for 4 separate layers is no longer applicable.

## Contents

- `VALIDATION-MASTER-001.md` - Master validation strategy for 4-model pipeline
- `layer1/` - iOS Layer 1 validation docs (still relevant for VisionCore)
- `RESEARCH-VALIDATION-stage-6.*.md` - Research validation reports

## Note on Layer 1

Layer 1 (iOS Vision Framework) validation is still relevant since on-device
object detection remains part of the architecture. Consider extracting
`layer1/` contents for use in future iOS validation work.
