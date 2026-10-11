import Foundation

/// Scans local directories of images (JPEG, PNG, HEIC, TIFF, WebP) and categorizes them using `PhotoClassifier`.
public final class DirectoryClassifier: Sendable {
    
    public static let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "webp"
    ]
    
    public init() {}
    
    /// Scans a directory and returns an AsyncStream emitting live progress updates.
    public func scan(
        directoryURL: URL,
        progressHandler: (@Sendable (ClassificationProgress) -> Void)? = nil
    ) async throws -> ClassificationScanResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .creationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return ClassificationScanResult(allPhotos: [], elapsedTimeSeconds: 0)
        }
        
        var targetURLs: [URL] = []
        while let fileURL = enumerator.nextObject() as? URL {
            let ext = fileURL.pathExtension.lowercased()
            if Self.supportedExtensions.contains(ext) {
                targetURLs.append(fileURL)
            }
        }
        
        let total = targetURLs.count
        var results: [CategorizedPhoto] = []
        let governor = ThermalGovernor.shared
        let classifier = PhotoClassifier.shared
        
        for (index, url) in targetURLs.enumerated() {
            // Apply thermal pacing
            let delay = governor.pacingDelayNanoseconds
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            
            do {
                let photo = try classifier.classify(fileURL: url)
                results.append(photo)
            } catch {
                // Skip unreadable files
            }
            
            let progress = ClassificationProgress(
                processedCount: index + 1,
                totalCount: total,
                currentItemName: url.lastPathComponent,
                thermalStatus: governor.thermalStatusDescription
            )
            progressHandler?(progress)
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        return ClassificationScanResult(allPhotos: results, elapsedTimeSeconds: elapsed)
    }
}
