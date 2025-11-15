# Swift Testing Framework Overview

**Source**: https://sosumi.ai/documentation/testing
**Fetched**: 2025-11-02

## Core Concepts

Swift Testing is Apple's modern testing framework for Swift. It provides developers with tools to define, organize, and validate test behavior through macros and structured APIs.

## Essential Components

**Test Definition**: Tests are created using the `@Test` macro, which marks functions as test cases. Tests can be organized into suites using the `@Suite` macro for hierarchical test organization.

**Key Structures**:
- `Test` - represents individual test metadata and properties
- `Test.Case` - tracks parameterized test instances
- `Trait` - customizes test runtime behavior

## Behavior Validation

The framework provides several validation mechanisms:

- **Expectations**: `expect()` checks conditions without stopping execution
- **Requirements**: `require()` validates conditions and halts on failure
- **Error Testing**: Specialized macros verify that specific errors are thrown
- **Process Exit Testing**: Validates how applications exit with exit codes and signals
- **Asynchronous Confirmation**: `confirmation()` ensures async events occur expected numbers of times

## Test Customization

Developers can apply traits to tests for:
- **Enabling/Disabling**: Conditional test execution
- **Execution Control**: Serial or parallel test running
- **Time Limits**: Enforce maximum execution duration
- **Annotations**: Add tags, comments, and bug associations
- **Issue Handling**: Filter or transform test failures

## Data Collection

The framework supports **Attachments** - recording values, files, and data during test execution for analysis and debugging.

## Migration Path

For teams using XCTest, Apple provides migration guidance to transition existing tests to the new framework.

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
