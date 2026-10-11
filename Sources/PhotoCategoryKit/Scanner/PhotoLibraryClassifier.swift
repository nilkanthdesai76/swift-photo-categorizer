import Foundation
import CoreGraphics

#if canImport(Photos)
import Photos
#endif

/// Classifies photos directly from the user's iOS Photo Library using PhotoKit (`PHAsset`).
/// Decodes only 360px hardware thumbnails via `PHImageManager` to guarantee minimal memory usage (<30MB)
/// and zero thermal elevation.
public final class PhotoLibraryClassifier: @unchecked Sendable {
    
    public init() {}
    
    #if canImport(Photos)
    /// Scans PhotoKit library assets and classifies each photo on-device.
    public func scanLibrary(
        maxAssets: Int? = nil,
        progressHandler: (@Sendable (ClassificationProgress) -> Void)? = nil,
        onPhotoClassified: (@Sendable (CategorizedPhoto, ClassificationProgress) -> Void)? = nil
    ) async -> ClassificationScanResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
        let allAssets = PHAsset.fetchAssets(with: fetchOptions)
        let total = min(allAssets.count, maxAssets ?? allAssets.count)
        
        var results: [CategorizedPhoto] = []
        let governor = ThermalGovernor.shared
        let classifier = PhotoClassifier.shared
        let imageManager = PHCachingImageManager.default()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .fastFormat
        requestOptions.resizeMode = .fast
        requestOptions.isNetworkAccessAllowed = true // Allows fetching lightweight thumbnail from iCloud without downloading full original
        
        let targetSize = CGSize(width: 360, height: 360)
        
        for index in 0..<total {
            let asset = allAssets.object(at: index)
            
            // Thermal pacing
            let delay = governor.pacingDelayNanoseconds
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            
            var classifiedPhoto: CategorizedPhoto?
            if let cgImage = await loadAssetThumbnail(asset: asset, imageManager: imageManager, targetSize: targetSize, options: requestOptions) {
                if let photo = try? classifier.classify(
                    image: cgImage,
                    id: asset.localIdentifier,
                    assetIdentifier: asset.localIdentifier,
                    dateTaken: asset.creationDate,
                    fileSizeBytes: 0
                ) {
                    results.append(photo)
                    classifiedPhoto = photo
                }
            }
            
            let progress = ClassificationProgress(
                processedCount: index + 1,
                totalCount: total,
                currentItemName: classifiedPhoto?.primaryCategory.displayName ?? "Asset \(index + 1) of \(total)",
                thermalStatus: governor.thermalStatusDescription
            )
            
            if let photo = classifiedPhoto {
                onPhotoClassified?(photo, progress)
            } else {
                progressHandler?(progress)
            }
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        return ClassificationScanResult(allPhotos: results, elapsedTimeSeconds: elapsed)
    }
    
    private func loadAssetThumbnail(
        asset: PHAsset,
        imageManager: PHImageManager,
        targetSize: CGSize,
        options: PHImageRequestOptions
    ) async -> CGImage? {
        await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                #if canImport(UIKit)
                continuation.resume(returning: image?.cgImage)
                #elseif canImport(AppKit)
                if let image = image {
                    var rect = CGRect(origin: .zero, size: image.size)
                    let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
                    continuation.resume(returning: cgImage)
                } else {
                    continuation.resume(returning: nil)
                }
                #else
                continuation.resume(returning: nil)
                #endif
            }
        }
    }
    #endif
}
