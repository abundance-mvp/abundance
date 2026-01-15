// AdaptiveGlassModifierTests.swift
// Tests for AdaptiveGlassModifier unified glass implementation
//
// Created: 2026-01-14
// References: Stage 2.7 @Observable Migration & Glass Consolidation

import XCTest
import SwiftUI
@testable import Core

@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class AdaptiveGlassModifierTests: XCTestCase {

    // MARK: - Modifier Instantiation Tests

    func testAdaptiveGlassModifierExists() {
        // Verify the modifier can be instantiated
        let modifier = AdaptiveGlassModifier(cornerRadius: 20)
        XCTAssertNotNil(modifier)
    }

    func testAdaptiveGlassModifierWithDefaultParameters() {
        // Verify default parameter initialization
        let modifier = AdaptiveGlassModifier()
        XCTAssertNotNil(modifier)
    }

    func testAdaptiveGlassModifierWithTint() {
        // Verify tint parameter works
        let modifier = AdaptiveGlassModifier(cornerRadius: 16, tint: .blue)
        XCTAssertNotNil(modifier)
    }

    // MARK: - View Extension Tests

    func testAdaptiveGlassViewExtension() {
        // Verify the view extension compiles and applies
        let view = Text("Test").adaptiveGlass(cornerRadius: 12)
        XCTAssertNotNil(view)
    }

    func testAdaptiveGlassViewExtensionDefaultCornerRadius() {
        // Verify default corner radius extension
        let view = Text("Test").adaptiveGlass()
        XCTAssertNotNil(view)
    }

    func testAdaptiveGlassViewExtensionWithTint() {
        // Verify tint variant
        let view = Text("Test").adaptiveGlass(cornerRadius: 16, tint: .orange)
        XCTAssertNotNil(view)
    }

    func testAdaptiveGlassWithCustomShape() {
        // Verify custom shape variant works
        let view = Text("Test").adaptiveGlass(in: Capsule())
        XCTAssertNotNil(view)
    }

    func testAdaptiveGlassWithCustomShapeAndTint() {
        // Verify custom shape with tint
        let view = Text("Test").adaptiveGlass(in: RoundedRectangle(cornerRadius: 24), tint: .mint)
        XCTAssertNotNil(view)
    }

    // MARK: - API Availability Verification

    /// Verify adaptiveGlass is available on iOS 17+/macOS 14+
    func testAdaptiveGlassAPIAvailability() {
        // This test verifies that the API compiles and is available
        let view = Text("Test").adaptiveGlass(cornerRadius: 16)
        XCTAssertNotNil(view, "adaptiveGlass should be available on iOS 17+/macOS 14+")
    }

    /// Verify custom shape variant availability
    func testAdaptiveGlassCustomShapeAPIAvailability() {
        let view = Text("Test").adaptiveGlass(in: Capsule())
        XCTAssertNotNil(view, "adaptiveGlass(in:) should be available on iOS 17+/macOS 14+")
    }
}
