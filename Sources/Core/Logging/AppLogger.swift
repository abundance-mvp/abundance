// AppLogger.swift
// Abundance iOS App - Structured Logging Framework
// Mirrors backend logging pattern from docs/design/MONITORING-001
//
// Created: 2025-11-16
// References: MONITORING-001, ADR-013

import OSLog
import Foundation

/// Structured event logging for Abundance iOS app
/// Mirrors backend logging pattern (MONITORING-001) for consistency
///
/// Note: @unchecked Sendable because dictionaries with [String: Any] cannot be proven Sendable at compile time,
/// but the enum is only used for logging and passed by value, making it thread-safe in practice.
public enum LogEvent: @unchecked Sendable {
    // MARK: - UI Interaction Events
    case buttonTapped(button: String, screen: String, context: [String: Any] = [:])
    case buttonUnresponsive(button: String, screen: String, reason: String)
    case screenAppeared(screen: String, duration: TimeInterval? = nil)
    case navigationFailed(from: String, to: String, error: Error?)

    // MARK: - Data Events
    case dataLoaded(type: String, count: Int, duration: TimeInterval)
    case dataLoadFailed(type: String, error: Error, context: [String: Any] = [:])
    case dataMissing(expected: String, context: String)
    case dataStale(type: String, age: TimeInterval)

    // MARK: - Firebase Events
    case firestoreQueryStarted(collection: String, filter: String)
    case firestoreQueryCompleted(collection: String, resultCount: Int, duration: TimeInterval)
    case firestoreWriteFailed(collection: String, error: Error)
    case firestoreRuleDenied(operation: String, path: String)

    // MARK: - AI Pipeline Events (Layer 1 - iOS only)
    case visionDetectionStarted(imageSize: Int)
    case visionDetectionCompleted(detectedClass: String, confidence: Double, duration: TimeInterval)
    case visionDetectionFailed(error: Error, imageSize: Int)
    case barcodeDetected(type: String, value: String)
    case barcodeDetectionFailed(reason: String)

    // MARK: - Authentication Events
    case authSignInStarted(provider: String)
    case authSignInCompleted(userId: String, duration: TimeInterval)
    case authSignInFailed(provider: String, error: Error)
    case authTokenRefreshed(userId: String)

    // MARK: - Performance Events
    case performanceMetric(operation: String, duration: TimeInterval, metadata: [String: Any] = [:])
    case memoryWarning(level: String, availableMemory: Int64)

    // MARK: - Spec Violations (ties to spec docs)
    case specViolation(
        spec: String,        // e.g., "mvp-vision-features"
        section: String,     // e.g., "Processing Time"
        expected: String,    // e.g., "< 6 seconds"
        actual: String,      // e.g., "8.2 seconds"
        severity: ViolationSeverity
    )

    // MARK: - Silent Failures (for bugs that don't crash)
    case silentFailure(
        feature: String,
        expectedBehavior: String,
        actualBehavior: String,
        reproSteps: [String]
    )

    // MARK: - Private Helpers

    /// Sanitizes user IDs for logging to prevent PII exposure.
    /// Shows first 4 chars + hash suffix for correlation without full exposure.
    private static func sanitizeUserId(_ userId: String) -> String {
        guard userId.count > 4 else {
            return String(repeating: "*", count: userId.count)
        }
        let prefix = String(userId.prefix(4))
        let hash = String(abs(userId.hashValue) % 1000000)
        return "\(prefix)***\(hash)"
    }

    // MARK: - Computed Properties

    var category: String {
        switch self {
        case .buttonTapped, .buttonUnresponsive, .screenAppeared, .navigationFailed:
            return "ui"
        case .dataLoaded, .dataLoadFailed, .dataMissing, .dataStale:
            return "data"
        case .firestoreQueryStarted, .firestoreQueryCompleted, .firestoreWriteFailed, .firestoreRuleDenied:
            return "firebase"
        case .visionDetectionStarted, .visionDetectionCompleted, .visionDetectionFailed, .barcodeDetected, .barcodeDetectionFailed:
            return "ai-pipeline"
        case .authSignInStarted, .authSignInCompleted, .authSignInFailed, .authTokenRefreshed:
            return "auth"
        case .performanceMetric, .memoryWarning:
            return "performance"
        case .specViolation:
            return "spec-violation"
        case .silentFailure:
            return "silent-failure"
        }
    }

    var severity: OSLogType {
        switch self {
        case .buttonUnresponsive, .navigationFailed, .dataLoadFailed, .firestoreWriteFailed, .firestoreRuleDenied,
             .visionDetectionFailed, .barcodeDetectionFailed, .authSignInFailed:
            return .error
        case .dataMissing, .dataStale, .memoryWarning:
            return .fault
        case .specViolation(_, _, _, _, let sev):
            return sev == .critical ? .fault : .error
        case .silentFailure:
            return .error
        default:
            return .info
        }
    }

    var message: String {
        switch self {
        case .buttonTapped(let button, let screen, _):
            return "Button tapped: \(button) on \(screen)"
        case .buttonUnresponsive(let button, let screen, let reason):
            return "Button unresponsive: \(button) on \(screen) - \(reason)"
        case .screenAppeared(let screen, _):
            return "Screen appeared: \(screen)"
        case .navigationFailed(let from, let to, let error):
            return "Navigation failed: \(from) → \(to) - \(error?.localizedDescription ?? "unknown")"
        case .dataLoaded(let type, let count, _):
            return "Data loaded: \(type) (\(count) items)"
        case .dataLoadFailed(let type, let error, _):
            return "Data load failed: \(type) - \(error.localizedDescription)"
        case .dataMissing(let expected, let context):
            return "Data missing: expected \(expected) in \(context)"
        case .dataStale(let type, let age):
            return "Data stale: \(type) (age: \(age)s)"
        case .firestoreQueryStarted(let collection, let filter):
            return "Firestore query started: \(collection) WHERE \(filter)"
        case .firestoreQueryCompleted(let collection, let count, _):
            return "Firestore query completed: \(collection) (\(count) results)"
        case .firestoreWriteFailed(let collection, let error):
            return "Firestore write failed: \(collection) - \(error.localizedDescription)"
        case .firestoreRuleDenied(let operation, let path):
            return "Firestore rule denied: \(operation) on \(path)"
        case .visionDetectionStarted(let size):
            return "Vision detection started (image size: \(size) bytes)"
        case .visionDetectionCompleted(let detectedClass, let confidence, _):
            return "Vision detection completed: \(detectedClass) (confidence: \(confidence))"
        case .visionDetectionFailed(let error, _):
            return "Vision detection failed: \(error.localizedDescription)"
        case .barcodeDetected(let type, let value):
            let truncated = value.count > 8 ? "\(value.prefix(8))..." : value
            return "Barcode detected: \(type) - \(truncated)"
        case .barcodeDetectionFailed(let reason):
            return "Barcode detection failed: \(reason)"
        case .authSignInStarted(let provider):
            return "Auth sign-in started: \(provider)"
        case .authSignInCompleted(let userId, _):
            return "Auth sign-in completed: \(Self.sanitizeUserId(userId))"
        case .authSignInFailed(let provider, let error):
            return "Auth sign-in failed: \(provider) - \(error.localizedDescription)"
        case .authTokenRefreshed(let userId):
            return "Auth token refreshed: \(Self.sanitizeUserId(userId))"
        case .performanceMetric(let operation, let duration, _):
            return "Performance: \(operation) (\(duration)ms)"
        case .memoryWarning(let level, let available):
            return "Memory warning: \(level) (\(available) bytes available)"
        case .specViolation(let spec, let section, let expected, let actual, _):
            return "SPEC VIOLATION: \(spec) § \(section) - Expected: \(expected), Actual: \(actual)"
        case .silentFailure(let feature, let expected, let actual, _):
            return "SILENT FAILURE: \(feature) - Expected: \(expected), Actual: \(actual)"
        }
    }

    var metadata: [String: Any] {
        var meta: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "category": category
        ]

        switch self {
        case .buttonTapped(let button, let screen, let context):
            meta["button"] = button
            meta["screen"] = screen
            meta.merge(context) { $1 }
        case .dataLoaded(_, _, let duration):
            meta["duration"] = duration
        case .firestoreQueryCompleted(_, let count, let duration):
            meta["resultCount"] = count
            meta["duration"] = duration
        case .visionDetectionCompleted(let detectedClass, let confidence, let duration):
            meta["detectedClass"] = detectedClass
            meta["confidence"] = confidence
            meta["duration"] = duration
        case .performanceMetric(let operation, let duration, let context):
            meta["operation"] = operation
            meta["duration"] = duration
            meta.merge(context) { $1 }
        case .specViolation(let spec, let section, let expected, let actual, let severity):
            meta["spec"] = spec
            meta["section"] = section
            meta["expected"] = expected
            meta["actual"] = actual
            meta["severity"] = severity.rawValue
        case .silentFailure(let feature, let expected, let actual, let reproSteps):
            meta["feature"] = feature
            meta["expectedBehavior"] = expected
            meta["actualBehavior"] = actual
            meta["reproSteps"] = reproSteps
        default:
            break
        }

        return meta
    }
}

public enum ViolationSeverity: String {
    case critical = "CRITICAL"  // Blocks user flow
    case high = "HIGH"          // Degrades UX significantly
    case medium = "MEDIUM"      // Noticeable but not blocking
    case low = "LOW"            // Minor deviation
}

/// Main logging interface for Abundance iOS app
public class AppLogger {

    private static let subsystem = "com.abundance.mvp"

    /// Log a structured event
    /// - Parameter event: The event to log
    public static func log(_ event: LogEvent) {
        let logger = Logger(subsystem: subsystem, category: event.category)

        // Log to OSLog (for Xcode console and Console.app)
        logger.log(level: event.severity, "\(event.message)")

        // Also write to local file for agent analysis (development only)
        #if DEBUG
        LogFileWriter.shared.append(event)
        #endif

        // Send to Firebase Analytics for production tracking
        #if !DEBUG
        FirebaseLogger.shared.log(event)
        #endif
    }

    /// Convenience method for performance tracking
    /// - Parameters:
    ///   - operation: Name of the operation
    ///   - block: Code block to measure
    /// - Returns: Result of the block
    public static func measure<T>(_ operation: String, _ block: () throws -> T) rethrows -> T {
        let start = Date()
        let result = try block()
        let duration = Date().timeIntervalSince(start) * 1000 // milliseconds

        log(.performanceMetric(operation: operation, duration: duration))

        return result
    }

    /// Convenience method for async performance tracking
    /// - Parameters:
    ///   - operation: Name of the operation
    ///   - block: Async code block to measure
    /// - Returns: Result of the block
    public static func measureAsync<T>(_ operation: String, _ block: () async throws -> T) async rethrows -> T {
        let start = Date()
        let result = try await block()
        let duration = Date().timeIntervalSince(start) * 1000 // milliseconds

        log(.performanceMetric(operation: operation, duration: duration))

        return result
    }
}

/// Writes logs to local file for development/debugging
/// Thread-safe implementation using serial dispatch queue
///
/// Note: @unchecked Sendable because thread safety is ensured via serial DispatchQueue,
/// but the compiler cannot verify this automatically.
final class LogFileWriter: @unchecked Sendable {
    static let shared = LogFileWriter()

    private let fileManager = FileManager.default
    private var logFileURL: URL?
    private let queue = DispatchQueue(label: "com.abundance.logwriter", qos: .utility)

    private init() {
        setupLogFile()
    }

    private func setupLogFile() {
        guard let projectRoot = findProjectRoot() else {
            print("⚠️ Could not find project root for log file")
            return
        }

        let debugDir = projectRoot.appendingPathComponent(".debug/logs")

        // Create .debug/logs directory if needed
        try? fileManager.createDirectory(at: debugDir, withIntermediateDirectories: true)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        logFileURL = debugDir.appendingPathComponent("session-\(timestamp).jsonl")

        print("📝 Logging to: \(logFileURL?.path ?? "unknown")")
    }

    private func findProjectRoot() -> URL? {
        #if DEBUG
        // In development, try to find project root via Bundle path
        if let bundlePath = Bundle.main.bundlePath as String? {
            var url = URL(fileURLWithPath: bundlePath)

            // Walk up to find Package.swift (SPM project root)
            for _ in 0..<10 {
                if fileManager.fileExists(atPath: url.appendingPathComponent("Package.swift").path) {
                    return url
                }
                url = url.deletingLastPathComponent()
            }
        }
        #endif

        // Fallback: use app's documents directory
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    func append(_ event: LogEvent) {
        // Serialize all writes to prevent race conditions
        queue.async { [weak self] in
            guard let self = self, let fileURL = self.logFileURL else { return }

            let logEntry: [String: Any] = [
                "severity": event.severity == .error ? "ERROR" : (event.severity == .fault ? "CRITICAL" : "INFO"),
                "message": event.message,
                "category": event.category,
                "metadata": event.metadata
            ]

            guard let jsonData = try? JSONSerialization.data(withJSONObject: logEntry),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("⚠️ Failed to serialize log event: \(event.message)")
                return
            }

            let logLine = jsonString + "\n"

            guard let data = logLine.data(using: .utf8) else {
                print("⚠️ Failed to encode log line as UTF-8")
                return
            }

            do {
                if self.fileManager.fileExists(atPath: fileURL.path) {
                    let fileHandle = try FileHandle(forWritingTo: fileURL)
                    defer { try? fileHandle.close() }  // Always close, even on error
                    try fileHandle.seekToEnd()
                    try fileHandle.write(contentsOf: data)
                } else {
                    try logLine.write(to: fileURL, atomically: true, encoding: .utf8)
                }
            } catch {
                print("⚠️ Failed to write log: \(error.localizedDescription)")
            }
        }
    }
}

/// Sends logs to Firebase Analytics (production only)
final class FirebaseLogger: @unchecked Sendable {
    static let shared = FirebaseLogger()

    private init() {}

    func log(_ event: LogEvent) {
        // TODO: Integrate with Firebase Analytics
        // Analytics.logEvent(event.category, parameters: event.metadata)
    }
}
