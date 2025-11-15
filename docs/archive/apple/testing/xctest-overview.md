# XCTest Framework Overview

**Source**: https://sosumi.ai/documentation/xctest
**Fetched**: 2025-11-02

## Overview

XCTest is Apple's comprehensive testing framework for iOS, macOS, tvOS, and watchOS applications. It provides APIs for unit testing, UI testing, and performance measurement.

## Core Testing Components

### Test Cases and Methods

The framework centers on `XCTestCase`, which provides the foundation for defining test methods. Tests can be customized with setup and teardown operations through methods like `setUp()`, `setUpWithError()`, `tearDown()`, and `tearDownWithError()`. For granular control, `addTeardownBlock()` allows asynchronous cleanup operations.

### Test Assertions

XCTest offers comprehensive assertion functions covering:

- **Boolean assertions**: `XCTAssertTrue()`, `XCTAssertFalse()`
- **Nil checks**: `XCTAssertNil()`, `XCTAssertNotNil()`, `XCTUnwrap()`
- **Equality**: `XCTAssertEqual()`, `XCTAssertNotEqual()`
- **Object identity**: `XCTAssertIdentical()`, `XCTAssertNotIdentical()`
- **Comparable values**: `XCTAssertGreaterThan()`, `XCTAssertLessThan()`
- **Error handling**: `XCTAssertThrowsError()`

## Asynchronous Testing

### Expectations

XCTest handles async operations through expectations:

- `XCTestExpectation`: Basic expectation for async operations
- `XCTKVOExpectation`: Key-value observing expectations
- `XCTNSNotificationExpectation`: Notification-based expectations
- `XCTNSPredicateExpectation`: Predicate-based expectations

The framework provides wait functions: `wait(for:)`, `wait(for:timeout:)`, and `fulfillment(of:timeout:enforceOrder:)` for async handling.

## Performance Testing

### Measurement Capabilities

Performance testing uses the `measure()` function family for benchmarking. Available metrics include:

- `XCTCPUMetric`: CPU usage measurement
- `XCTMemoryMetric`: Memory consumption
- `XCTClockMetric`: Wall clock time
- `XCTHitchMetric`: Rendering hiccups
- `XCTStorageMetric`: Disk I/O tracking
- `XCTApplicationLaunchMetric`: App launch performance

Options like `XCTMeasureOptions` control iteration counts and manual measurement timing.

## Test Management

### Activities and Attachments

Tests can be organized using `XCTContext.runActivity()` to group substeps. Attachments capture test artifacts:

- Screenshots via `XCTAttachment(screenshot:)`
- Images with `XCTAttachment(image:)`
- Data, files, and strings for debugging

Attachments have lifetimes: "deleteOnSuccess" or "keepAlways".

### Expected Failures

Use `XCTExpectFailure()` to mark known issues, with options for strict/non-strict matching and custom issue matchers.

## Test Execution and Observation

### Test Runs

`XCTestRun` tracks execution with properties for success status, failure counts, durations, and skip information.

### Observation

`XCTestObservation` protocol monitors test lifecycle events. Register observers through `XCTestObservationCenter.shared.addTestObserver()`.

### Issues

`XCTIssue` represents test failures with types: assertion failures, performance regressions, thrown errors, and uncaught exceptions.

## UI Testing

XCTest integrates with `XCUIAutomation` for user interface testing, supporting element interaction and screenshot capture through the same attachment system.

## Test Control

Additional capabilities include:

- **Skipping tests**: `XCTSkipIf()`, `XCTSkipUnless()`
- **Conditional execution**: `continueAfterFailure`, `executionTimeAllowance`
- **Custom test creation**: Programmatic test generation via `XCTestInvocation`

This framework provides developers with robust tools for comprehensive test coverage across all Apple platforms.

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
