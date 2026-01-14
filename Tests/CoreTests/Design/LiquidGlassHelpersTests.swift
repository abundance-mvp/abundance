// LiquidGlassHelpersTests.swift
// Tests for Liquid Glass helper extensions
//
// Created: 2026-01-14
// References: Stage 2.6 UI/UX Refactoring with Liquid Glass

import XCTest
import SwiftUI
@testable import Core

@MainActor
final class LiquidGlassHelpersTests: XCTestCase {

    // MARK: - iOS 26+ / macOS 26+ Liquid Glass Tests

    @available(iOS 26.0, macOS 26.0, *)
    func testBrandGlassModifierExists() {
        let view = Text("Test")
            .brandGlass()
        XCTAssertNotNil(view)
    }

    @available(iOS 26.0, macOS 26.0, *)
    func testBrandGlassWithCornerRadius() {
        let view = Text("Test")
            .brandGlass(cornerRadius: 16)
        XCTAssertNotNil(view)
    }

    @available(iOS 26.0, macOS 26.0, *)
    func testBrandGlassInteractive() {
        let view = Text("Test")
            .brandGlass(interactive: true)
        XCTAssertNotNil(view)
    }

    @available(iOS 26.0, macOS 26.0, *)
    func testBrandGlassWithTint() {
        let view = Text("Test")
            .brandGlass(tint: .blue)
        XCTAssertNotNil(view)
    }

    @available(iOS 26.0, macOS 26.0, *)
    func testBrandGlassWithCornerRadiusAndTint() {
        let view = Text("Test")
            .brandGlass(cornerRadius: 20, tint: .orange)
        XCTAssertNotNil(view)
    }

    @available(iOS 26.0, macOS 26.0, *)
    func testBrandGlassWithAllOptions() {
        let view = Text("Test")
            .brandGlass(cornerRadius: 24, tint: .mint, interactive: true)
        XCTAssertNotNil(view)
    }

    // MARK: - iOS 17-25 / macOS 14-25 Fallback Tests

    func testBrandGlassFallbackExists() {
        let view = Text("Test")
            .brandGlassFallback()
        XCTAssertNotNil(view)
    }

    func testBrandGlassFallbackWithCornerRadius() {
        let view = Text("Test")
            .brandGlassFallback(cornerRadius: 20)
        XCTAssertNotNil(view)
    }

    // MARK: - API Availability Verification

    /// Verify that brandGlass is available on iOS 26+/macOS 26+
    /// This test documents the availability requirements
    func testBrandGlassAPIAvailability() {
        // This test verifies that the API compiles and is available
        // at runtime on iOS 26+/macOS 26+

        if #available(iOS 26.0, macOS 26.0, *) {
            // On iOS 26+/macOS 26+, brandGlass should be available
            let view = Text("Test").brandGlass()
            XCTAssertNotNil(view, "brandGlass should be available on iOS 26+/macOS 26+")
        } else {
            // On older versions, brandGlassFallback should be used
            let view = Text("Test").brandGlassFallback()
            XCTAssertNotNil(view, "brandGlassFallback should be available on iOS 17+/macOS 14+")
        }
    }

    /// Verify corner radius variant availability
    func testBrandGlassCornerRadiusAPIAvailability() {
        if #available(iOS 26.0, macOS 26.0, *) {
            let view = Text("Test").brandGlass(cornerRadius: 16)
            XCTAssertNotNil(view, "brandGlass(cornerRadius:) should be available on iOS 26+/macOS 26+")
        } else {
            let view = Text("Test").brandGlassFallback(cornerRadius: 16)
            XCTAssertNotNil(view, "brandGlassFallback(cornerRadius:) should be available on iOS 17+/macOS 14+")
        }
    }

    /// Verify interactive variant availability
    func testBrandGlassInteractiveAPIAvailability() {
        if #available(iOS 26.0, macOS 26.0, *) {
            let view = Text("Test").brandGlass(interactive: true)
            XCTAssertNotNil(view, "brandGlass(interactive:) should be available on iOS 26+/macOS 26+")
        }
        // No fallback equivalent for interactive - passes if not available
    }

    /// Verify tint variant availability
    func testBrandGlassTintAPIAvailability() {
        if #available(iOS 26.0, macOS 26.0, *) {
            let view = Text("Test").brandGlass(tint: .blue)
            XCTAssertNotNil(view, "brandGlass(tint:) should be available on iOS 26+/macOS 26+")
        }
        // No fallback equivalent for tint - passes if not available
    }
}
