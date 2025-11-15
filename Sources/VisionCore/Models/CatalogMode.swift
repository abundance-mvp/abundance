import Foundation

/// Determines how a detected object should be cataloged
/// Used to control UI treatment and upload triggering in the real-time detection pipeline
public enum CatalogMode: String, Codable, Equatable, Sendable {
    /// High confidence (>0.70) and high quality (>0.65)
    /// Object is automatically cataloged with mint green border and sparkle animation
    case automatic

    /// Medium confidence (0.40-0.69) or low quality (<0.65)
    /// Object requires manual confirmation via double-tap, displayed with grey border
    case manual

    /// Low confidence (<0.40)
    /// Object is ignored and not shown to user
    case ignore
}
