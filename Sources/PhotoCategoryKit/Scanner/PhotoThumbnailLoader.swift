import Foundation
import CoreGraphics

#if canImport(Photos)
import Photos
#endif

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

/// Thread-safe, bounded memory cache and asynchronous image loader for PhotoKit assets,
/// local files, and synthetic in-memory images.
public final class PhotoThumbnailLoader: @unchecked Sendable {
    
    public static let shared = PhotoThumbnailLoader()
    
    #if canImport(UIKit) || canImport(AppKit)
    private let cache = NSCache<NSString, PlatformImage>()
    #endif
    
    public init() {
        #if canImport(UIKit) || canImport(AppKit)
        cache.countLimit = 300 // Max 300 cached thumbnails
        cache.totalCostLimit = 60 * 1024 * 1024 // 60 MB memory ceiling
        #endif
    }
    
    #if canImport(UIKit) || canImport(AppKit)
    /// Manually caches a platform image (e.g. for synthetic demo images).
    public func cacheImage(_ image: PlatformImage, for id: String) {
        cache.setObject(image, forKey: id as NSString)
    }
    
    /// Loads an image for a categorized photo, checking memory cache, PhotoKit, and file URL.
    public func loadImage(
        for photo: CategorizedPhoto,
        targetSize: CGSize = CGSize(width: 320, height: 320)
    ) async -> PlatformImage? {
        let cacheKey = "\(photo.id)_\(Int(targetSize.width))" as NSString
        
        // 1. Check in-memory cache
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }
        if let cachedExact = cache.object(forKey: photo.id as NSString) {
            return cachedExact
        }
        
        // 2. PhotoKit asset identifier
        #if canImport(Photos)
        if let assetId = photo.assetIdentifier {
            let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
            if let asset = fetch.firstObject {
                let options = PHImageRequestOptions()
                options.deliveryMode = .fastFormat
                options.resizeMode = .fast
                options.isNetworkAccessAllowed = true
                
                let loaded: PlatformImage? = await withCheckedContinuation { continuation in
                    PHImageManager.default().requestImage(
                        for: asset,
                        targetSize: targetSize,
                        contentMode: .aspectFill,
                        options: options
                    ) { img, _ in
                        continuation.resume(returning: img)
                    }
                }
                
                if let loaded {
                    cache.setObject(loaded, forKey: cacheKey)
                    return loaded
                }
            }
        }
        #endif
        
        // 3. Local file URL
        if let url = photo.fileURL,
           let cgImage = ThumbnailRenderer.loadThumbnail(from: url, maxDimension: Int(targetSize.width)) {
            #if canImport(UIKit)
            let image = UIImage(cgImage: cgImage)
            #elseif canImport(AppKit)
            let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            #endif
            cache.setObject(image, forKey: cacheKey)
            return image
        }
        
        return nil
    }
    
    /// Clears memory cache on memory pressure warnings.
    public func clearCache() {
        cache.removeAllObjects()
    }
    #endif
}
