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

// MARK: - Adaptive Glass Modifier (Unified)

/// Unified glass modifier that handles iOS version detection and accessibility
/// Replaces duplicated implementations across UI components
@available(iOS 17.0, macOS 14.0, *)
public struct AdaptiveGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let shape: AnyShape?
    let tint: Color?

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(cornerRadius: CGFloat = 16, shape: AnyShape? = nil, tint: Color? = nil) {
        self.cornerRadius = cornerRadius
        self.shape = shape
        self.tint = tint
    }

    public func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(Color.backgroundDefault, in: resolvedShape)
        } else {
            glassContent(content)
        }
    }

    private var resolvedShape: AnyShape {
        if let shape = shape {
            return shape
        }
        return AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    @ViewBuilder
    private func glassContent(_ content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            if let shape = shape {
                if let tint = tint {
                    content.glassEffect(.regular.tint(tint), in: shape)
                } else {
                    content.glassEffect(in: shape)
                }
            } else {
                if let tint = tint {
                    content.brandGlass(cornerRadius: cornerRadius, tint: tint)
                } else {
                    content.brandGlass(cornerRadius: cornerRadius)
                }
            }
        } else {
            content
                .background(.thickMaterial, in: resolvedShape)
        }
    }
}

// MARK: - View Extension for AdaptiveGlass

@available(iOS 17.0, macOS 14.0, *)
public extension View {
    /// Apply adaptive glass background with automatic iOS version detection
    /// - Parameters:
    ///   - cornerRadius: Corner radius for the glass shape (default: 16)
    ///   - tint: Optional color tint for iOS 26+ glass effect
    /// - Returns: View with glass effect (iOS 26+) or material fallback (iOS 17-25)
    func adaptiveGlass(cornerRadius: CGFloat = 16, tint: Color? = nil) -> some View {
        modifier(AdaptiveGlassModifier(cornerRadius: cornerRadius, tint: tint))
    }

    /// Apply adaptive glass background with custom shape
    /// - Parameters:
    ///   - shape: Custom shape for the glass effect
    ///   - tint: Optional color tint for iOS 26+ glass effect
    /// - Returns: View with glass effect in custom shape
    func adaptiveGlass<S: Shape>(in shape: S, tint: Color? = nil) -> some View {
        modifier(AdaptiveGlassModifier(shape: AnyShape(shape), tint: tint))
    }
}
