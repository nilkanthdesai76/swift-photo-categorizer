import Foundation
import CoreGraphics

/// Result of fast on-device face detection via Apple Vision (`VNDetectFaceRectanglesRequest`).
public struct FaceDetectionResult: Codable, Sendable, Hashable {
    /// Total number of human faces detected in the image.
    public let faceCount: Int
    
    /// Normalized bounding boxes [0.0 ... 1.0] in Vision coordinate space (origin at bottom-left).
    public let normalizedBoundingBoxes: [NormalizedRect]
    
    public var hasFaces: Bool {
        faceCount > 0
    }
    
    public init(faceCount: Int = 0, normalizedBoundingBoxes: [NormalizedRect] = []) {
        self.faceCount = faceCount
        self.normalizedBoundingBoxes = normalizedBoundingBoxes
    }
}

/// Codable normalized rectangle wrapper for CoreGraphics coordinates.
public struct NormalizedRect: Codable, Sendable, Hashable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
    
    public init(cgRect: CGRect) {
        self.x = Double(cgRect.origin.x)
        self.y = Double(cgRect.origin.y)
        self.width = Double(cgRect.size.width)
        self.height = Double(cgRect.size.height)
    }
    
    public var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}
