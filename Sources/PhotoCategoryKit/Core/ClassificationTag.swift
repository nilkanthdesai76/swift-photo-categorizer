import Foundation

/// Individual Vision classification tag with its confidence score and mapped high-level category.
public struct ClassificationTag: Identifiable, Codable, Sendable, Hashable {
    public var id: String { identifier }
    
    /// Raw classification identifier from Apple Vision (e.g., "landscape", "dog", "pizza", "car").
    public let identifier: String
    
    /// Humanized clean label for display (e.g. "landscape" -> "Landscape", "adult_cat" -> "Adult Cat").
    public var displayLabel: String {
        identifier
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    /// Classification confidence score between 0.0 and 1.0.
    public let confidence: Float
    
    /// High-level category mapped from this tag.
    public let category: PhotoCategory
    
    public init(identifier: String, confidence: Float, category: PhotoCategory) {
        self.identifier = identifier
        self.confidence = confidence
        self.category = category
    }
}
