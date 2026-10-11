import Foundation
import CoreGraphics
import ImageIO

/// Hardware-accelerated image thumbnail downscaler and dominant color extractor.
/// Uses ImageIO to load thumbnails directly from compressed files or decodes directly into minimal buffers.
public enum ThumbnailRenderer {
    
    /// Target max dimension for Vision classification thumbnails (360px provides optimal ANE classification accuracy).
    public static let defaultMaxDimension = 360
    
    /// Creates a downscaled CGImage directly from a file URL without loading the full-resolution uncompressed image into RAM.
    public static func loadThumbnail(from url: URL, maxDimension: Int = defaultMaxDimension) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
    
    /// Downscales an existing CGImage to a target max dimension.
    public static func downscale(_ image: CGImage, maxDimension: Int = defaultMaxDimension) -> CGImage? {
        let width = image.width
        let height = image.height
        let maxSide = max(width, height)
        
        guard maxSide > maxDimension else {
            return image
        }
        
        let scale = Double(maxDimension) / Double(maxSide)
        let targetWidth = max(1, Int(Double(width) * scale))
        let targetHeight = max(1, Int(Double(height) * scale))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: targetWidth * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
        return context.makeImage()
    }
    
    /// Computes dominant hex color string (e.g. "#4A90E2") from a downscaled thumbnail.
    public static func computeDominantColor(from image: CGImage) -> String {
        // Downscale to 16x16 to get average palette
        let size = 16
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var buffer = [UInt8](repeating: 0, count: size * size * 4)
        
        guard let context = CGContext(
            data: &buffer,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return "#808080"
        }
        
        context.interpolationQuality = .low
        context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
        
        var totalR: UInt64 = 0
        var totalG: UInt64 = 0
        var totalB: UInt64 = 0
        let pixelCount = UInt64(size * size)
        
        for i in 0..<Int(pixelCount) {
            let offset = i * 4
            totalR += UInt64(buffer[offset])
            totalG += UInt64(buffer[offset + 1])
            totalB += UInt64(buffer[offset + 2])
        }
        
        let avgR = UInt8(totalR / pixelCount)
        let avgG = UInt8(totalG / pixelCount)
        let avgB = UInt8(totalB / pixelCount)
        
        return String(format: "#%02X%02X%02X", avgR, avgG, avgB)
    }
}
