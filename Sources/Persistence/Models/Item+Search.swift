// Sources/Persistence/Models/Item+Search.swift

import Foundation

extension Item {
    /// Returns true if the item matches the search query.
    /// Searches across all available text fields: category, color, material, condition
    ///
    /// When Stage 3.1 adds additional fields (name, subCategory, brand, model),
    /// this method will automatically search those fields as well.
    ///
    /// - Parameter query: The search text to match against
    /// - Returns: True if any searchable field contains the query (case-insensitive, locale-aware)
    public func matchesSearchQuery(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }

        // Collect all searchable text fields
        // Currently available fields from Item model
        let searchableFields: [String?] = [
            category,
            color,
            material,
            condition
        ]

        // Return true if any field contains the query (case-insensitive, locale-aware)
        return searchableFields.contains { field in
            field?.localizedCaseInsensitiveContains(query) == true
        }
    }

    /// All searchable field names for documentation/testing
    /// Note: After Stage 3.1, add: name, subCategory, brand, model
    public static var searchableFieldNames: [String] {
        ["category", "color", "material", "condition"]
    }
}
