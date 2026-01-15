// Sources/Persistence/Models/Item+Search.swift

import Foundation

extension Item {
    /// Returns true if the item matches the search query.
    /// Searches across all available text fields: name, category, subCategory, brand, model, color, material, condition
    ///
    /// - Parameter query: The search text to match against
    /// - Returns: True if any searchable field contains the query
    ///   (case-insensitive, diacritic-insensitive, locale-aware)
    public func matchesSearchQuery(_ query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return true }

        // Collect all searchable text fields (including Stage 3.1 fields)
        let searchableFields: [String?] = [
            name,
            category,
            subCategory,
            brand,
            model,
            color,
            material,
            condition?.displayName  // Convert enum to display string
        ]

        // Return true if any field contains the query
        // Uses localizedStandardContains for case-insensitive AND diacritic-insensitive matching
        // e.g., "cafe" matches "Café", "naïve" matches "naive"
        return searchableFields.contains { field in
            field?.localizedStandardContains(trimmedQuery) == true
        }
    }

    /// All searchable field names for documentation/testing
    public static var searchableFieldNames: [String] {
        ["name", "category", "subCategory", "brand", "model", "color", "material", "condition"]
    }
}
