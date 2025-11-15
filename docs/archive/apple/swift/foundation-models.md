# Foundation Models Documentation Summary

**Source**: https://sosumi.ai/documentation/technologyoverviews/foundation-models
**Fetched**: 2025-11-02

## Overview
Apple's Foundation Models documentation explains how developers can leverage on-device models that power Apple Intelligence. The guide emphasizes integrating generative capabilities into existing app features while maintaining thoughtful design principles.

## Key Sections

**Data Definition for Precise Output**
The documentation recommends identifying existing app features that could benefit from generative models. For instance, a restaurant review feature could be enhanced by converting user submissions into visual scorecards. Developers should define custom data types to guide model outputs rather than relying on parsing code.

**Tool Calling Capabilities**
According to the guide, "Tool calling allows a model to interact with the code you write to extend the model's capabilities." This enables models to determine when to invoke custom functions—such as calendar scanning for reservation details—to complete user requests with current information.

**Adapter Customization**
For domain-specific tasks, adapters function as small modules trained on custom data to enhance the base model's performance in specialized areas.

## Design Considerations
The documentation references Apple's Human Interface Guidelines for machine learning, encouraging developers to prioritize thoughtful design when implementing generative features.

The material emphasizes practical implementation through prompt engineering practice and iterative testing with the Language Model Session framework.
