# XCTestCase API Documentation

**Source**: https://sosumi.ai/documentation/xctest/xctestcase
**Fetched**: 2025-11-02

## Overview

`XCTestCase` serves as the foundational class for constructing unit tests in Xcode. It enables developers to organize related test methods with optional setup and teardown phases, while supporting performance measurement and asynchronous operation testing.

## Class Hierarchy

- **Inherits from:** `XCTest`
- **Conforms to:** `XCTActivity`, `XCTWaiterDelegate`, and various Swift protocols (`Equatable`, `Hashable`, `CustomStringConvertible`, etc.)

## Core Responsibilities

As stated in the documentation: "The primary class for defining test cases, test methods, and performance tests."

## Lifecycle Management

### Setup and Teardown

- **`setUp()`** – Customizes initial state before each test case begins
- **`tearDown()`** – Performs cleanup operations after each test case completes
- **`addTeardownBlock(_:)`** – Registers teardown code blocks to execute after the current test method (multiple blocks supported)

### Execution Control

- **`continueAfterFailure`** – Boolean property determining whether tests continue after failures
- **`executionTimeAllowance`** – Configures timeout duration (in seconds, rounded to nearest minute) before test fails
- **`runsForEachTargetApplicationUIConfiguration`** – Enables automatic test repetition across orientation, localization, and appearance variations

## Asynchronous Testing

### Expectations

XCTestCase provides multiple expectation creation methods:

- **`expectation(description:)`** – Basic expectation with descriptive text
- **`expectation(forNotification:object:handler:)`** – Notification-based expectations
- **`expectation(for:evaluatedWith:handler:)`** – Predicate-based expectations
- **`keyValueObservingExpectation(for:keyPath:expectedValue:)`** – KVO-based expectations
- **`expectation(that:on:options:willEqual:)`** – Key-value observing for property changes

### Waiting Methods

- **`wait(for:timeout:enforceOrder:)`** – Waits for expectation fulfillment with timeout and optional ordering
- **`fulfillment(of:timeout:enforceOrder:)`** – Alternative waiting mechanism
- **`waitForExpectations(timeout:handler:)`** – Legacy expectation waiting method

### Modern Concurrency

For Swift concurrency-based tests, annotate methods with `async` or `async throws` and use standard concurrency patterns instead of expectations.

## Performance Testing

### Core Methods

- **`measure(_:)`** – Measures performance of a code block using default metrics
- **`measure(metrics:block:)`** – Records selected metrics for a code block
- **`measure(metrics:options:block:)`** – Records metrics with specified measurement options
- **`startMeasuring()` / `stopMeasuring()`** – Manual performance recording control

### Configuration

- **`defaultPerformanceMetrics`** – Array of default metrics recorded during tests
- **`defaultMetrics`** – Default metrics for performance recording
- **`defaultMeasureOptions`** – Default measurement options configuration

The documentation notes: "Build performance tests as part of a continuous improvement cycle for performance in your app."

## UI Testing Features

### Interruption Handling

- **`addUIInterruptionMonitor(withDescription:handler:)`** – Registers handler for UI interruptions
- **`removeUIInterruptionMonitor(_:)`** – Removes interrupt handler using provided token

## Programmatic Test Creation

- **`init(selector:)` / `init(invocation:)`** – Initializes tests programmatically
- **`testInvocations`** – Array of invocations representing all test methods
- **`invokeTest()`** – Executes the test
- **`record(_:)` / `recordFailure(withDescription:inFile:atLine:expected:)`** – Manual issue/failure recording

## Key Capabilities

XCTestCase leverages `XCTActivity` conformance to: "simplify complex tests by organizing them into activities, and attach output to tests for later analysis."

## Important Patterns

1. **Test Organization** – Group related tests within single test case classes
2. **Resource Management** – Use setup/teardown and teardown blocks for resource initialization and cleanup
3. **Asynchronous Operations** – Prefer async/await patterns with concurrent tests over legacy expectations
4. **Performance Baselines** – Establish performance metrics during continuous development cycles
5. **UI Test Stability** – Monitor and handle interruptions to improve reliability

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
