import SwiftUI

/// Detailed inspector sheet showing Apple Vision classification breakdown, face bounding boxes, and tags.
public struct PhotoInspectorSheet: View {
    public let photo: CategorizedPhoto
    public let onDismiss: () -> Void
    
    @State private var previewImage: Image?
    
    public init(photo: CategorizedPhoto, onDismiss: @escaping () -> Void) {
        self.photo = photo
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Photo Preview with Face Box Overlay
                    ZStack {
                        if let previewImage {
                            previewImage
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 280)
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: photo.dominantColorHex).opacity(0.3))
                                .frame(height: 220)
                                .overlay {
                                    Image(systemName: photo.primaryCategory.sfSymbol)
                                        .font(.system(size: 48))
                                        .foregroundColor(Color(hex: photo.primaryCategory.themeColorHex))
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Winning Category Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label(photo.primaryCategory.displayName, systemImage: photo.primaryCategory.sfSymbol)
                                .font(.title3.bold())
                                .foregroundColor(Color(hex: photo.primaryCategory.themeColorHex))
                            Spacer()
                            Text("\(Int(photo.primaryConfidence * 100))% confidence")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: photo.primaryCategory.themeColorHex).opacity(0.15))
                                .foregroundColor(Color(hex: photo.primaryCategory.themeColorHex))
                                .clipShape(Capsule())
                        }
                        
                        ProgressView(value: Double(photo.primaryConfidence))
                            .tint(Color(hex: photo.primaryCategory.themeColorHex))
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Secondary Categories (if any)
                    if !photo.secondaryCategories.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Competing Categories")
                                .font(.headline)
                            
                            ForEach(photo.secondaryCategories, id: \.category) { sec in
                                HStack {
                                    Image(systemName: sec.category.sfSymbol)
                                        .foregroundColor(Color(hex: sec.category.themeColorHex))
                                    Text(sec.category.displayName)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(Int(sec.confidence * 100))%")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                }
                                ProgressView(value: Double(sec.confidence))
                                    .tint(Color(hex: sec.category.themeColorHex))
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Face Detection Information
                    if photo.faces.hasFaces {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Face Detection", systemImage: "person.crop.rectangle.badge.plus")
                                .font(.headline)
                            
                            HStack {
                                Text("Detected Faces:")
                                Spacer()
                                Text("\(photo.faces.faceCount) human \(photo.faces.faceCount == 1 ? "face" : "faces")")
                                    .font(.subheadline.bold())
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Vision Classification Tags
                    if !photo.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Apple Vision Tags")
                                .font(.headline)
                            
                            FlowTagsLayout(spacing: 8) {
                                ForEach(photo.tags) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag.displayLabel)
                                        Text("\(Int(tag.confidence * 100))%")
                                            .font(.caption2.bold())
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: tag.category.themeColorHex).opacity(0.12))
                                    .foregroundColor(.primary)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Technical Details & Dominant Palette
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo Details")
                            .font(.headline)
                        
                        HStack {
                            Text("Dominant Color")
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: photo.dominantColorHex))
                                    .frame(width: 16, height: 16)
                                Text(photo.dominantColorHex)
                                    .font(.caption.monospaced())
                            }
                        }
                        
                        if photo.pixelWidth > 0 {
                            HStack {
                                Text("Dimensions")
                                Spacer()
                                Text(photo.formattedDimensions)
                                    .font(.subheadline)
                            }
                        }
                        
                        if photo.fileSizeBytes > 0 {
                            HStack {
                                Text("File Size")
                                Spacer()
                                Text(photo.formattedFileSize)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("AI Classification")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
        .task(id: photo.id) {
            #if canImport(UIKit) || canImport(AppKit)
            if let platformImg = await PhotoThumbnailLoader.shared.loadImage(for: photo, targetSize: CGSize(width: 600, height: 600)) {
                #if canImport(UIKit)
                self.previewImage = Image(uiImage: platformImg)
                #elseif canImport(AppKit)
                self.previewImage = Image(nsImage: platformImg)
                #endif
            }
            #endif
        }
    }
}

/// Simple flow layout helper for tags.
public struct FlowTagsLayout: Layout {
    public var spacing: CGFloat
    
    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        height = currentY + lineHeight
        return CGSize(width: width, height: height)
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
