// LiquidGlassHelpers.swift
// Liquid Glass helper extensions for iOS 26+
//
// Created: 2026-01-14
// Reference: Apple docs - Applying Liquid Glass to custom views
// Stage: 2.6 UI/UX Refactoring with Liquid Glass

import SwiftUI

// MARK: - iOS 26+ Liquid Glass Extensions

/// Liquid Glass helper extensions for iOS 26+ / macOS 26+
/// These extensions provide brand-consistent Liquid Glass effects
@available(iOS 26.0, macOS 26.0, *)
public extension View {
    /// Apply brand-styled Liquid Glass effect with capsule shape (default)
    ///
    /// - Parameters:
    ///   - tint: Optional color tint to apply to the glass effect
    ///   - interactive: Whether the glass should react to touch/pointer interactions
    /// - Returns: A view with Liquid Glass effect applied
    @ViewBuilder
    func brandGlass(
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        if let tint = tint {
            if interactive {
                self.glassEffect(.regular.tint(tint).interactive())
            } else {
                self.glassEffect(.regular.tint(tint))
            }
        } else {
            if interactive {
                self.glassEffect(.regular.interactive())
            } else {
                self.glassEffect()
            }
        }
    }

    /// Apply brand-styled Liquid Glass effect with rounded rectangle shape
    ///
    /// - Parameters:
    ///   - cornerRadius: The corner radius for the rounded rectangle shape
    ///   - tint: Optional color tint to apply to the glass effect
    ///   - interactive: Whether the glass should react to touch/pointer interactions
    /// - Returns: A view with Liquid Glass effect applied in a rounded rectangle
    @ViewBuilder
    func brandGlass(
        cornerRadius: CGFloat,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        if let tint = tint {
            if interactive {
                self.glassEffect(.regular.tint(tint).interactive(), in: shape)
            } else {
                self.glassEffect(.regular.tint(tint), in: shape)
            }
        } else {
            if interactive {
                self.glassEffect(.regular.interactive(), in: shape)
            } else {
                self.glassEffect(in: shape)
            }
        }
    }
}

// MARK: - iOS 17-25 / macOS 14-25 Fallback Extensions

/// Fallback for iOS 17-25 / macOS 14-25 using material modifiers
/// This provides a visual approximation of Liquid Glass using thick material
@available(iOS 17.0, macOS 14.0, *)
@available(iOS, deprecated: 26.0, message: "Use brandGlass() for iOS 26+ with true Liquid Glass effect")
@available(macOS, deprecated: 26.0, message: "Use brandGlass() for macOS 26+ with true Liquid Glass effect")
public extension View {
    /// iOS 17-25 fallback using thick material background
    ///
    /// This provides a frosted glass appearance similar to Liquid Glass
    /// but without the dynamic light refraction and morphing capabilities.
    ///
    /// - Parameter cornerRadius: The corner radius for the background shape (default: 16)
    /// - Returns: A view with a material background approximating glass effect
    @ViewBuilder
    func brandGlassFallback(cornerRadius: CGFloat = 16) -> some View {
        self.background(.thickMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}
