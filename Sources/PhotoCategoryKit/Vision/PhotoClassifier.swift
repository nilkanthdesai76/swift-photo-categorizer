import Foundation
import CoreGraphics
import Vision

#if canImport(Photos)
import Photos
#endif

/// High-performance, on-device AI photo classification engine powered by Apple's Vision framework
/// and Apple Neural Engine (ANE). Zero cloud calls, zero external models.
public final class PhotoClassifier: Sendable {
    
    public static let shared = PhotoClassifier()
    
    public init() {}
    
    // MARK: - Core Classification
    
    /// Classifies a CGImage into primary and secondary categories with face detection and confidence scores.
    public func classify(
        image: CGImage,
        id: String = UUID().uuidString,
        assetIdentifier: String? = nil,
        fileURL: URL? = nil,
        dateTaken: Date? = nil,
        fileSizeBytes: Int64 = 0
    ) throws -> CategorizedPhoto {
        // 1. Downscale to 360px for fast, low-power Neural Engine execution
        let thumbnail = ThumbnailRenderer.downscale(image, maxDimension: ThumbnailRenderer.defaultMaxDimension) ?? image
        
        // 2. Perform Apple Vision requests (Classification + Face Detection)
        let classifyRequest = VNClassifyImageRequest()
        let faceRequest = VNDetectFaceRectanglesRequest()
        
        let handler = VNImageRequestHandler(cgImage: thumbnail, options: [:])
        try handler.perform([classifyRequest, faceRequest])
        
        // 3. Process Face Observations
        var faceBoxes: [NormalizedRect] = []
        if let faces = faceRequest.results {
            for f in faces {
                faceBoxes.append(NormalizedRect(cgRect: f.boundingBox))
            }
        }
        let faceResult = FaceDetectionResult(faceCount: faceBoxes.count, normalizedBoundingBoxes: faceBoxes)
        
        // 4. Process Classification Observations
        var categoryScores: [PhotoCategory: Float] = [:]
        var tags: [ClassificationTag] = []
        
        if let observations = classifyRequest.results {
            for obs in observations {
                // Filter out low confidence noise
                guard obs.confidence >= 0.05 else { continue }
                
                let category = VisionTaxonomyMapper.mapCategory(from: obs.identifier)
                let tag = ClassificationTag(
                    identifier: obs.identifier,
                    confidence: obs.confidence,
                    category: category
                )
                tags.append(tag)
                
                let currentScore = categoryScores[category, default: 0.0]
                categoryScores[category] = max(currentScore, obs.confidence)
            }
        }
        
        // 5. Apply Face Detection Heuristics:
        // If human faces are detected, boost .people category confidence proportionally
        if faceResult.faceCount > 0 {
            let faceBonus: Float = faceResult.faceCount >= 2 ? 0.95 : 0.85
            let currentPeopleScore = categoryScores[.people, default: 0.0]
            categoryScores[.people] = max(currentPeopleScore, faceBonus)
            
            // Add synthetic face tag if not already present
            if !tags.contains(where: { $0.identifier == "face" || $0.identifier == "person" }) {
                tags.insert(
                    ClassificationTag(identifier: "human_face", confidence: faceBonus, category: .people),
                    at: 0
                )
            }
        }
        
        // 6. Determine Winning Category
        let sortedScores = categoryScores.sorted { $0.value > $1.value }
        let winningCategory: PhotoCategory
        let winningConfidence: Float
        
        if let top = sortedScores.first, top.value >= 0.15 {
            winningCategory = top.key
            winningConfidence = top.value
        } else {
            winningCategory = .other
            winningConfidence = 0.5
        }
        
        // 7. Secondary categories
        let secondary = sortedScores
            .filter { $0.key != winningCategory && $0.value >= 0.10 }
            .map { CategoryConfidence(category: $0.key, confidence: $0.value) }
        
        // 8. Dominant Color
        let dominantColor = ThumbnailRenderer.computeDominantColor(from: thumbnail)
        
        return CategorizedPhoto(
            id: id,
            assetIdentifier: assetIdentifier,
            fileURL: fileURL,
            primaryCategory: winningCategory,
            primaryConfidence: winningConfidence,
            secondaryCategories: secondary,
            tags: Array(tags.prefix(15)),
            faces: faceResult,
            dominantColorHex: dominantColor,
            dateTaken: dateTaken,
            pixelWidth: image.width,
            pixelHeight: image.height,
            fileSizeBytes: fileSizeBytes
        )
    }
    
    /// Classifies an image file directly from disk without loading full resolution into RAM.
    public func classify(fileURL: URL) throws -> CategorizedPhoto {
        guard let thumbnail = ThumbnailRenderer.loadThumbnail(from: fileURL) else {
            throw ClassifierError.cannotLoadImage(fileURL)
        }
        
        var fileSize: Int64 = 0
        var dateTaken: Date?
        
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
            fileSize = (attrs[.size] as? NSNumber)?.int64Value ?? 0
            dateTaken = attrs[.creationDate] as? Date
        }
        
        return try classify(
            image: thumbnail,
            id: fileURL.lastPathComponent,
            fileURL: fileURL,
            dateTaken: dateTaken,
            fileSizeBytes: fileSize
        )
    }
}

public enum ClassifierError: LocalizedError {
    case cannotLoadImage(URL)
    case visionRequestFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .cannotLoadImage(let url):
            return "Failed to load image thumbnail from: \(url.path)"
        case .visionRequestFailed(let msg):
            return "Apple Vision analysis failed: \(msg)"
        }
    }
}
