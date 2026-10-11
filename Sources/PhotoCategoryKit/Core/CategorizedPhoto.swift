import Foundation

/// Confidence pairing for secondary or competing category scores.
public struct CategoryConfidence: Codable, Sendable, Hashable, Comparable {
    public let category: PhotoCategory
    public let confidence: Float
    
    public init(category: PhotoCategory, confidence: Float) {
        self.category = category
        self.confidence = confidence
    }
    
    public static func < (lhs: CategoryConfidence, rhs: CategoryConfidence) -> Bool {
        lhs.confidence < rhs.confidence
    }
}

/// Represents an analyzed and classified photo.
public struct CategorizedPhoto: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    
    /// Optional PhotoKit PHAsset localIdentifier (for iOS photo library).
    public let assetIdentifier: String?
    
    /// Optional file URL (for local directory scans).
    public let fileURL: URL?
    
    /// Winning primary semantic category.
    public let primaryCategory: PhotoCategory
    
    /// Winning category confidence (0.0 to 1.0).
    public let primaryConfidence: Float
    
    /// Other categories detected with non-zero confidence.
    public let secondaryCategories: [CategoryConfidence]
    
    /// Top raw classification tags from Apple Vision.
    public let tags: [ClassificationTag]
    
    /// Detected faces and bounding boxes.
    public let faces: FaceDetectionResult
    
    /// Dominant average color extracted from the thumbnail.
    public let dominantColorHex: String
    
    /// Creation date metadata if available.
    public let dateTaken: Date?
    
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let fileSizeBytes: Int64
    
    public init(
        id: String = UUID().uuidString,
        assetIdentifier: String? = nil,
        fileURL: URL? = nil,
        primaryCategory: PhotoCategory,
        primaryConfidence: Float,
        secondaryCategories: [CategoryConfidence] = [],
        tags: [ClassificationTag] = [],
        faces: FaceDetectionResult = FaceDetectionResult(),
        dominantColorHex: String = "#808080",
        dateTaken: Date? = nil,
        pixelWidth: Int = 0,
        pixelHeight: Int = 0,
        fileSizeBytes: Int64 = 0
    ) {
        self.id = id
        self.assetIdentifier = assetIdentifier
        self.fileURL = fileURL
        self.primaryCategory = primaryCategory
        self.primaryConfidence = primaryConfidence
        self.secondaryCategories = secondaryCategories.sorted(by: >)
        self.tags = tags
        self.faces = faces
        self.dominantColorHex = dominantColorHex
        self.dateTaken = dateTaken
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.fileSizeBytes = fileSizeBytes
    }
    
    public var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }
    
    public var formattedDimensions: String {
        "\(pixelWidth) × \(pixelHeight)"
    }
}
