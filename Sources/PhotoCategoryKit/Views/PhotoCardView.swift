import SwiftUI

#if canImport(Photos)
import Photos
#endif

/// Card rendering a categorized photo inside a lazy grid.
public struct PhotoCardView: View {
    public let photo: CategorizedPhoto
    public let onTap: () -> Void
    
    @State private var loadedImage: Image?
    
    public init(photo: CategorizedPhoto, onTap: @escaping () -> Void) {
        self.photo = photo
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                // Photo Image Box
                ZStack(alignment: .topTrailing) {
                    Group {
                        if let loadedImage {
                            loadedImage
                                .resizable()
                                .scaledToFill()
                        } else {
                            Rectangle()
                                .fill(Color(hex: photo.dominantColorHex).opacity(0.4))
                                .overlay {
                                    Image(systemName: photo.primaryCategory.sfSymbol)
                                        .font(.system(size: 32))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                        }
                    }
                    .frame(height: 140)
                    .clipped()
                    .cornerRadius(10)
                    
                    // Top Badges (Category Pill + Faces)
                    HStack(spacing: 4) {
                        if photo.faces.hasFaces {
                            HStack(spacing: 3) {
                                Image(systemName: "person.crop.circle")
                                Text("\(photo.faces.faceCount)")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                        
                        Text("\(Int(photo.primaryConfidence * 100))%")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(hex: photo.primaryCategory.themeColorHex))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .padding(6)
                }
                
                // Category & Tag labels
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: photo.primaryCategory.sfSymbol)
                            .foregroundColor(Color(hex: photo.primaryCategory.themeColorHex))
                            .font(.caption2)
                        Text(photo.primaryCategory.displayName)
                            .font(.caption.bold())
                            .lineLimit(1)
                    }
                    
                    if let firstTag = photo.tags.first {
                        Text(firstTag.displayLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 2)
            }
            .padding(6)
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .task {
            loadImage()
        }
    }
    
    private func loadImage() {
        if let fileURL = photo.fileURL,
           let cgImage = ThumbnailRenderer.loadThumbnail(from: fileURL, maxDimension: 240) {
            #if canImport(UIKit)
            self.loadedImage = Image(decorative: cgImage, scale: 1.0)
            #elseif canImport(AppKit)
            self.loadedImage = Image(decorative: cgImage, scale: 1.0)
            #endif
        }
    }
}
