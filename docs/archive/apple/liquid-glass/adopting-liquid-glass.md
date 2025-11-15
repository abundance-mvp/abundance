# Adopting Liquid Glass

**Source**: https://sosumi.ai/documentation/technologyoverviews/adopting-liquid-glass
**Fetched**: 2025-11-02

## Overview

Building your app with the latest Xcode version allows you to see how your interface appears with Liquid Glass. Apps using standard SwiftUI, UIKit, or AppKit components automatically adopt the updated design when built against the latest SDKs across iOS, iPadOS, macOS, tvOS, and watchOS.

## Visual Refresh

Liquid Glass is a dynamic material combining "the optical properties of glass with a sense of fluidity," forming a functional layer for controls and navigation. Key implementation strategies include:

- **Leverage system frameworks**: Standard components like bars, sheets, and controls automatically adopt this material
- **Reduce custom backgrounds**: Remove custom effects from navigation and control elements that may interfere with system-provided effects
- **Test with accessibility settings**: Verify that interfaces adapt properly when users enable transparency or motion reduction
- **Use sparingly**: Apply Liquid Glass effects to custom controls minimally to avoid distracting from content

## App Icons

Icons now feature dynamic, expressive designs with layered elements that respond to lighting effects. Design principles include:

- Create visually balanced designs across platforms with solid, overlapping semi-transparent shapes
- Let the system handle masking, blurring, and visual effects automatically
- Use Icon Composer to preview designs with system effects before submission

## Controls

Refreshed controls respond fluidly during interaction, with knobs transforming into Liquid Glass and buttons morphing into menus. Implementation guidance:

- Review appearance updates and avoid hard-coding layout metrics
- Use system colors for legibility in light and dark contexts
- Maintain standard spacing instead of overcrowding elements
- Adopt new button style APIs rather than creating custom Liquid Glass effects

## Navigation

Navigation elements like tab bars and sidebars float in the Liquid Glass layer. Recommendations:

- Establish clear separation between navigation and content layers
- Use standard APIs for tab bar-to-sidebar adaptation
- Implement split views for sidebar and inspector layouts
- Configure tab bar minimization behavior in iOS

## Menus and Toolbars

Both elements adopt Liquid Glass with updated visual treatments. Best practices:

- Use standard selectors for menu items to automatically apply appropriate icons
- Match top menu actions with swipe actions for consistency
- Group toolbar items by function and use icons instead of text
- Always provide accessibility labels for icons

## Windows and Modals

Windows feature rounder corners supporting fluid resizing. Modal considerations:

- Allow arbitrary window sizing with content adjustment
- Use split views to support continuous resizing with fluid transitions
- Sheets feature increased corner radius with half sheets inset from display edges
- Action sheets now originate from their initiating element rather than the bottom

## Organization and Layout

Lists and tables employ larger row heights and increased section corner radius. Key updates:

- Update section headers to title-style capitalization
- Use grouped SwiftUI forms for consistent layout across platforms

## Search

Search interfaces optimize for platform conventions. Consider:

- Testing keyboard layout behavior when activating search
- Using semantic search tabs with standard system APIs

## Platform Considerations

- **watchOS**: Adopt standard button styles and toolbar APIs
- **tvOS**: Use standard focus APIs for custom controls gaining focus
- **All platforms**: Combine custom effects using Glass Effect Container for performance optimization and profile apps regularly
