# Apple Intelligence Documentation

**Source**: https://sosumi.ai/documentation/technologyoverviews/apple-intelligence
**Fetched**: 2025-11-02

## Overview

Apple Intelligence represents "the personal intelligence system that drives built-in experiences, like Writing Tools, Image Playground, Visual Intelligence, and Genmoji." Most developers receive support automatically through system frameworks, though customization options exist for tailored implementations.

## Key Features

**Visual Search Capabilities**
Developers can integrate Visual Intelligence to enable users to discover information about surrounding objects through Camera Control. The framework detects objects and exchanges data via App Intents.

**Writing Enhancement Tools**
The Writing Tools API allows developers to add proofreading and rewriting features. Implementation recommendations include:
- Using attributed strings for text storage
- Leveraging standard system text views when feasible
- Customizing behavior through configuration options

**Image Generation**
Image Playground framework enables users to create personalized images through descriptive input or by pairing existing images with descriptions. Apps can implement asynchronous image generation through the Image Creator feature.

**Custom Emoji (Genmoji)**
Genmoji are user-created custom emoji that integrate into text content. Standard text views handle these automatically by saving them as NSAdaptiveImageGlyph objects. Developers working with custom text views must account for Genmoji attachments when persisting content.

## Foundation Models Access

For enhanced functionality using the on-device language model, developers should consult foundation model documentation resources.
