import Foundation
import Testing

/// Helpers for accessibility assertion tests.
/// Reads Swift source files and checks for required accessibility patterns.
enum AXeTestHelpers {

    /// Project root derived from this file's location.
    static let projectRoot: String = {
        // Tests/AXeTests/AXeTestHelpers.swift → project root is 3 levels up
        let filePath = #filePath
        let url = URL(fileURLWithPath: filePath)
        return url
            .deletingLastPathComponent() // AXeTests/
            .deletingLastPathComponent() // Tests/
            .deletingLastPathComponent() // project root
            .path
    }()

    /// Read a source file relative to project root.
    static func readSource(at relativePath: String) throws -> SourceFile {
        let fullPath = (projectRoot as NSString).appendingPathComponent(relativePath)
        let content = try String(contentsOfFile: fullPath, encoding: .utf8)
        return SourceFile(path: relativePath, content: content)
    }
}

/// A parsed source file with line-based query helpers.
struct SourceFile: Sendable {
    let path: String
    let content: String
    let lines: [String]

    init(path: String, content: String) {
        self.path = path
        self.content = content
        self.lines = content.components(separatedBy: "\n")
    }

    /// Check if any line matches the regex pattern (outside comments).
    func containsPattern(_ pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("//") || trimmed.hasPrefix("/*") || trimmed.hasPrefix("*") { continue }
            let range = NSRange(line.startIndex..., in: line)
            if regex.firstMatch(in: line, range: range) != nil {
                return true
            }
        }
        return false
    }

    /// Return all line numbers (1-based) matching the pattern (outside comments).
    func linesMatching(_ pattern: String) -> [Int] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        var results: [Int] = []
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("//") || trimmed.hasPrefix("/*") || trimmed.hasPrefix("*") { continue }
            let range = NSRange(line.startIndex..., in: line)
            if regex.firstMatch(in: line, range: range) != nil {
                results.append(index + 1)
            }
        }
        return results
    }

    /// Check if a pattern appears within N lines after another pattern.
    func hasPatternWithin(_ needle: String, after anchor: String, withinLines: Int) -> Bool {
        guard let needleRegex = try? NSRegularExpression(pattern: needle),
              let anchorRegex = try? NSRegularExpression(pattern: anchor) else { return false }
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("//") { continue }
            let range = NSRange(line.startIndex..., in: line)
            if anchorRegex.firstMatch(in: line, range: range) != nil {
                let searchEnd = min(index + withinLines, lines.count)
                for searchIndex in index..<searchEnd {
                    let searchLine = lines[searchIndex]
                    let searchRange = NSRange(searchLine.startIndex..., in: searchLine)
                    if needleRegex.firstMatch(in: searchLine, range: searchRange) != nil {
                        return true
                    }
                }
            }
        }
        return false
    }

    /// Count occurrences of a pattern (outside comments).
    func countPattern(_ pattern: String) -> Int {
        linesMatching(pattern).count
    }
}

// MARK: - System Color Assertions

extension SourceFile {

    /// System colors that should be brand tokens (excludes .primary, .secondary, .clear, .black, .white).
    static let systemColorPattern = #"\.(blue|gray|purple|red|green|orange|yellow|pink|mint|cyan|indigo|teal|brown)\b"#

    /// Find system color violations (excluding camera views which are exempt for black/white).
    func systemColorViolations() -> [Int] {
        linesMatching(Self.systemColorPattern)
    }

    /// Deprecated foregroundColor API.
    func deprecatedForegroundColorLines() -> [Int] {
        linesMatching(#"\.foregroundColor\("#)
    }
}

// MARK: - Accessibility Assertions

extension SourceFile {

    /// Buttons without accessibilityLabel within 10 lines.
    func buttonsWithoutLabel() -> [Int] {
        let buttonLines = linesMatching(#"Button\s*[\(\{]"#)
        return buttonLines.filter { lineNum in
            !hasPatternWithin(
                #"\.accessibilityLabel"#,
                after: #"Button\s*[\(\{]"#,
                withinLines: 10
            )
        }
    }

    /// Images without accessibilityLabel or accessibilityHidden.
    func imagesWithoutAccessibility() -> [Int] {
        let imageLines = linesMatching(#"Image\("#)
        return imageLines.filter { lineNum in
            let searchEnd = min(lineNum + 5, lines.count)
            for i in (lineNum - 1)..<searchEnd {
                let line = lines[i]
                if line.contains(".accessibilityLabel") || line.contains(".accessibilityHidden") {
                    return false
                }
            }
            return true
        }
    }

    /// Fixed font sizes that don't support Dynamic Type.
    /// Excludes sizes using @ScaledMetric variables (which DO scale).
    func fixedFontSizeLines() -> [Int] {
        // Match .font(.system(size: <literal number>)) — NOT @ScaledMetric variables
        linesMatching(#"\.font\(\.system\(size:\s*\d"#)
    }

    /// Check for accessibilityIdentifier on testable elements.
    func accessibilityIdentifierCount() -> Int {
        countPattern(#"\.accessibilityIdentifier\("#)
    }
}

// MARK: - Animation Assertions

extension SourceFile {

    /// Raw animation curves (not brand curves).
    func rawAnimationCurves() -> [Int] {
        let rawCurves = linesMatching(#"\.animation\(\.(easeIn|easeOut|easeInOut|linear)\b"#)
        let rawWithAnimation = linesMatching(#"withAnimation\(\.(easeIn|easeOut|easeInOut|linear)\b"#)
        return rawCurves + rawWithAnimation
    }

    /// Check for reduceMotion environment usage.
    func hasReduceMotionCheck() -> Bool {
        containsPattern(#"accessibilityReduceMotion"#)
    }

    /// Brand animation usage count.
    func brandAnimationCount() -> Int {
        countPattern(#"\.(brandPress|brandDefault|brandReducedMotion)\b"#)
    }
}

// MARK: - Glass Assertions

extension SourceFile {

    /// Raw material usage that should use adaptiveGlass().
    func rawMaterialLines() -> [Int] {
        linesMatching(#"\.(ultraThinMaterial|thinMaterial|thickMaterial|ultraThickMaterial)\b"#)
    }

    /// Check for adaptiveGlass usage.
    func adaptiveGlassCount() -> Int {
        countPattern(#"\.adaptiveGlass\("#)
    }

    /// glassEffect without availability check — look for glassEffect not preceded by #available.
    func unguardedGlassEffectLines() -> [Int] {
        let glassLines = linesMatching(#"\.glassEffect"#)
        return glassLines.filter { lineNum in
            // Check previous 5 lines for #available
            let searchStart = max(0, lineNum - 6)
            for i in searchStart..<(lineNum - 1) {
                if lines[i].contains("#available") {
                    return false
                }
            }
            return true
        }
    }
}
