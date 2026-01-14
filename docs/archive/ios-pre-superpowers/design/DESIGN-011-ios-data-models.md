# DESIGN-011: iOS Data Models

**Created**: 2025-11-08
**Stage**: 2.2 - iOS Client Architecture
**Status**: Approved

---

## Overview

Codable structs for API responses and Firestore documents.

---

## CatalogItem

```swift
import Foundation

struct CatalogItem: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var category: String
    var location: String?
    var estimatedValue: Double?
    var imageURL: URL?
    var barcodeValue: String?
    var aiAnalysis: AIAnalysis?
    let createdAt: Date
    var updatedAt: Date
    let userId: String

    enum CodingKeys: String, CodingKey {
        case id, name, category, location
        case estimatedValue = "estimated_value"
        case imageURL = "image_url"
        case barcodeValue = "barcode_value"
        case aiAnalysis = "ai_analysis"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
}
```

---

## AIAnalysis

```swift
struct AIAnalysis: Codable, Equatable {
    var layer1: Layer1Result? // On-device Vision
    var layer2a: Layer2aResult? // Gemini attributes
    var layer2b: Layer2bResult? // Product ID (barcode/SerpAPI)
    var layer3: Layer3Result? // Claude synthesis

    enum CodingKeys: String, CodingKey {
        case layer1
        case layer2a = "layer_2a"
        case layer2b = "layer_2b"
        case layer3
    }
}

struct Layer1Result: Codable, Equatable {
    let detectedLabel: String
    let confidence: Float
    let boundingBox: BoundingBox

    enum CodingKeys: String, CodingKey {
        case detectedLabel = "detected_label"
        case confidence
        case boundingBox = "bounding_box"
    }
}

struct BoundingBox: Codable, Equatable {
    let x, y, width, height: Double
}
```

---

## User

```swift
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String?
    let displayName: String?
    let subscriptionStatus: SubscriptionStatus
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "display_name"
        case subscriptionStatus = "subscription_status"
        case createdAt = "created_at"
    }
}

enum SubscriptionStatus: String, Codable {
    case free
    case trial
    case premium
}
```

---

**Status**: ✅ Approved
