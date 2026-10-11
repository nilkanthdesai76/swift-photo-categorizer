import Foundation

/// Progress information emitted during batch classification scans.
public struct ClassificationProgress: Sendable {
    public let processedCount: Int
    public let totalCount: Int
    public let currentItemName: String
    public let thermalStatus: String
    
    public var fractionCompleted: Double {
        guard totalCount > 0 else { return 0.0 }
        return min(1.0, Double(processedCount) / Double(totalCount))
    }
    
    public var percentString: String {
        "\(Int(fractionCompleted * 100))%"
    }
    
    public init(
        processedCount: Int,
        totalCount: Int,
        currentItemName: String = "",
        thermalStatus: String = "Nominal"
    ) {
        self.processedCount = processedCount
        self.totalCount = totalCount
        self.currentItemName = currentItemName
        self.thermalStatus = thermalStatus
    }
}

/// Aggregated result of a complete photo library or directory classification scan.
public struct ClassificationScanResult: Sendable {
    public let allPhotos: [CategorizedPhoto]
    public let photosByCategory: [PhotoCategory: [CategorizedPhoto]]
    public let totalScanned: Int
    public let elapsedTimeSeconds: Double
    
    public init(allPhotos: [CategorizedPhoto], elapsedTimeSeconds: Double) {
        self.allPhotos = allPhotos
        self.totalScanned = allPhotos.count
        self.elapsedTimeSeconds = elapsedTimeSeconds
        
        var grouped: [PhotoCategory: [CategorizedPhoto]] = [:]
        for cat in PhotoCategory.allCases {
            grouped[cat] = []
        }
        for photo in allPhotos {
            grouped[photo.primaryCategory, default: []].append(photo)
        }
        self.photosByCategory = grouped
    }
    
    public func count(for category: PhotoCategory) -> Int {
        photosByCategory[category]?.count ?? 0
    }
}
