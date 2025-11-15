# App Design and UI

**Source**: https://sosumi.ai/documentation/technologyoverviews/app-design-and-ui
**Fetched**: 2025-11-02

## Overview

Apple's App Design and UI documentation guides developers through selecting programming approaches, building interfaces, and implementing essential app behaviors across platforms.

## Programming Approaches

### SwiftUI
SwiftUI represents the modern option for Apple development. As Apple states, it's "the best option when you're learning to program for Apple platforms, or when you want to create a new app." The framework uses declarative programming—developers describe desired behaviors and appearance, while SwiftUI manages the interface automatically. Data-driven updates refresh the UI when state variables change.

SwiftUI supports iOS, iPadOS, macOS, tvOS, visionOS, and watchOS development using Swift.

### UIKit and AppKit
These frameworks employ traditional object-oriented design. Developers assemble reusable objects and customize them to achieve specific behaviors. Interface components come from standard and custom views, with interaction logic residing in custom controller objects. Each object manages its own behavior independently.

UIKit targets iOS, iPadOS, tvOS, visionOS, and Mac Catalyst. AppKit serves macOS. Both support Swift and Objective-C.

## Interface Design Elements

### Core Components
Most UI components remain consistent across app-builder technologies. Developers should familiarize themselves with available components and platform-specific implementations before designing interfaces.

### Liquid Glass
A new dynamic material combines optical glass properties with fluidity, appearing across Apple platforms. This design element helps ensure interfaces feel native to Apple's ecosystem.

## Resources
Documentation covers SwiftUI apps, UIKit/AppKit alternatives, interface fundamentals, and Liquid Glass implementation strategies.
