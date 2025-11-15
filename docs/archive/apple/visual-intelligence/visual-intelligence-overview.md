# Visual Intelligence Documentation

**Source**: https://sosumi.ai/documentation/visualintelligence
**Fetched**: 2025-11-02

## Overview
This documentation covers Apple's Visual Intelligence framework for developers integrating semantic content analysis into their applications.

## Core Components

### Essential Resources
The framework provides guidance on "Integrating your app with visual intelligence" and introduces the `SemanticContentDescriptor` class as a primary interface.

### SemanticContentDescriptor
This class enables access to semantic content with two main properties:
- **labels**: An array of string identifiers representing detected content
- **pixelBuffer**: An optional pixel buffer containing raw image data (`CVReadOnlyPixelBuffer`)

### Protocol Conformance
The descriptor implements several protocol requirements:
- `defaultResolverSpecification` for resolver configuration
- `Specification` type for descriptor specifications
- `ValueType` for type definition
- `UnwrappedType` for type unwrapping

## Related Frameworks

The documentation references **App Intents** fundamentals, including:
- Making actions and content discoverable throughout the system
- Implementing initial app intents for your application

---

**Note**: This content is unofficial documentation extracted from Apple's developer portal. All rights belong to Apple Inc.
