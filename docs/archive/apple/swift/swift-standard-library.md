# Swift Standard Library Documentation

**Source**: https://sosumi.ai/documentation/swift
**Fetched**: 2025-11-02

This page provides comprehensive API reference documentation for Apple's Swift programming language, specifically focusing on the Standard Library section.

## Key Sections

### Essentials
- Swift updates and information on adopting strict concurrency in Swift 6 applications

### Core Numeric Types

**Int**
The documentation covers the signed integer type with extensive functionality:
- "Converting Integers" through multiple initializer methods
- "Converting Floating-Point Values" for type conversion
- "Converting with No Loss of Precision" using optional initializers
- "Converting Strings" to integer values
- Random number generation methods
- Comprehensive arithmetic operations (addition, subtraction, multiplication, division)
- "Masked Arithmetic" for overflow-wrapping operations
- Bitwise operations and comparisons
- "Performing Calculations with Overflow" to detect overflow conditions
- "Double-Width Calculations" for extended precision operations
- Sign and magnitude queries
- Numeric constants (zero, min, max)
- Byte order manipulation
- Binary representation inspection
- Memory address initialization
- Encoding and decoding support
- Hash and description functionality

**Double**
The floating-point type includes:
- Integer and string conversion methods
- "Converting Floating-Point Values" between different precisions
- "Converting with No Loss of Precision" optional conversions
- Random value generation within ranges
- Complete arithmetic operators with assignment variants
- "Rounding Values" using various rounding rules
- Comparison and magnitude operations
- "Querying a Double" for internal properties like exponent and significand
- Numeric constants (pi, infinity, NaN variants)
- Binary representation details
- "Querying a Double's State" (finite, infinite, normal, subnormal)
- Encoding/decoding support

**String**
Comprehensive string manipulation covering:
- Multiple creation methods from various sources
- Character and substring access
- "Appending Strings and Characters" through concatenation operators
- Insertion and replacement of substrings
- Removal operations with multiple variants
- Case transformation (uppercase/lowercase)
- String comparison and pattern matching
- Substring extraction and range operations
- Splitting functionality
- Character encoding support (UTF-8, UTF-16, Unicode Scalars)
- Path and file operations
- Index manipulation and range expressions
- Encoding and decoding support

### Protocol Implementations
The documentation includes extensive "Default Implementations" sections showing how these types conform to standard Swift protocols including Equatable, Comparable, Codable, Hashable, and various numeric protocols.

### SIMD Support
All numeric types include support for SIMD (Single Instruction Multiple Data) operations through storage types for 2, 4, 8, 16, 32, and 64-element vectors.
