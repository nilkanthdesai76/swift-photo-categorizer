import SwiftUI

/// Detailed inspector sheet showing Apple Vision classification breakdown, face bounding boxes, and tags.
public struct PhotoInspectorSheet: View {
    public let photo: CategorizedPhoto
    public let onDismiss: () -> Void
    
    @State private var currentPhoto: CategorizedPhoto
    @State private var previewImage: Image?
    @State private var isRunningDeepVision: Bool = false
    
    public init(photo: CategorizedPhoto, onDismiss: @escaping () -> Void) {
        self.photo = photo
        self._currentPhoto = State(initialValue: photo)
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
                                .fill(Color(hex: currentPhoto.dominantColorHex).opacity(0.3))
                                .frame(height: 220)
                                .overlay {
                                    Image(systemName: currentPhoto.primaryCategory.sfSymbol)
                                        .font(.system(size: 48))
                                        .foregroundColor(Color(hex: currentPhoto.primaryCategory.themeColorHex))
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Winning Category Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label(currentPhoto.primaryCategory.displayName, systemImage: currentPhoto.primaryCategory.sfSymbol)
                                .font(.title3.bold())
                                .foregroundColor(Color(hex: currentPhoto.primaryCategory.themeColorHex))
                            Spacer()
                            Text("\(Int(currentPhoto.primaryConfidence * 100))% confidence")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: currentPhoto.primaryCategory.themeColorHex).opacity(0.15))
                                .foregroundColor(Color(hex: currentPhoto.primaryCategory.themeColorHex))
                                .clipShape(Capsule())
                        }
                        
                        ProgressView(value: Double(currentPhoto.primaryConfidence))
                            .tint(Color(hex: currentPhoto.primaryCategory.themeColorHex))
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Secondary Categories (if any)
                    if !currentPhoto.secondaryCategories.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Competing Categories")
                                .font(.headline)
                            
                            ForEach(currentPhoto.secondaryCategories, id: \.category) { sec in
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
                    if currentPhoto.faces.hasFaces {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Face Detection", systemImage: "person.crop.rectangle.badge.plus")
                                .font(.headline)
                            
                            HStack {
                                Text("Detected Faces:")
                                Spacer()
                                Text("\(currentPhoto.faces.faceCount) human \(currentPhoto.faces.faceCount == 1 ? "face" : "faces")")
                                    .font(.subheadline.bold())
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Vision Classification Tags & On-Demand Deep Analysis
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Classification Tags")
                                .font(.headline)
                            Spacer()
                            if isRunningDeepVision {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Button {
                                    runDeepVisionAnalysis()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                        Text("Deep Vision")
                                    }
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.12))
                                    .foregroundColor(.accentColor)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        if !currentPhoto.tags.isEmpty {
                            FlowTagsLayout(spacing: 8) {
                                ForEach(currentPhoto.tags) { tag in
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
                        } else {
                            Text("Fast smart-categorized. Tap 'Deep Vision' to extract 1,300+ Neural Engine tags.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Technical Details & Dominant Palette
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo Details")
                            .font(.headline)
                        
                        HStack {
                            Text("Dominant Color")
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: currentPhoto.dominantColorHex))
                                    .frame(width: 16, height: 16)
                                Text(currentPhoto.dominantColorHex)
                                    .font(.caption.monospaced())
                            }
                        }
                        
                        if currentPhoto.pixelWidth > 0 {
                            HStack {
                                Text("Dimensions")
                                Spacer()
                                Text(currentPhoto.formattedDimensions)
                                    .font(.subheadline)
                            }
                        }
                        
                        if currentPhoto.fileSizeBytes > 0 {
                            HStack {
                                Text("File Size")
                                Spacer()
                                Text(currentPhoto.formattedFileSize)
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
        .task(id: currentPhoto.id) {
            #if canImport(UIKit) || canImport(AppKit)
            if let platformImg = await PhotoThumbnailLoader.shared.loadImage(for: currentPhoto, targetSize: CGSize(width: 600, height: 600)) {
                #if canImport(UIKit)
                self.previewImage = Image(uiImage: platformImg)
                #elseif canImport(AppKit)
                self.previewImage = Image(nsImage: platformImg)
                #endif
            }
            #endif
        }
    }
    
    private func runDeepVisionAnalysis() {
        guard !isRunningDeepVision else { return }
        isRunningDeepVision = true
        
        Task {
            #if canImport(UIKit)
            if let platformImg = await PhotoThumbnailLoader.shared.loadImage(for: currentPhoto, targetSize: CGSize(width: 480, height: 480)),
               let cgImage = platformImg.cgImage {
                if let deepResult = try? PhotoClassifier.shared.classify(
                    image: cgImage,
                    id: currentPhoto.id,
                    assetIdentifier: currentPhoto.assetIdentifier,
                    fileURL: currentPhoto.fileURL,
                    dateTaken: currentPhoto.dateTaken,
                    fileSizeBytes: currentPhoto.fileSizeBytes
                ) {
                    await MainActor.run {
                        self.currentPhoto = deepResult
                        self.isRunningDeepVision = false
                    }
                    return
                }
            }
            #elseif canImport(AppKit)
            if let platformImg = await PhotoThumbnailLoader.shared.loadImage(for: currentPhoto, targetSize: CGSize(width: 480, height: 480)) {
                var rect = CGRect(origin: .zero, size: platformImg.size)
                if let cgImage = platformImg.cgImage(forProposedRect: &rect, context: nil, hints: nil),
                   let deepResult = try? PhotoClassifier.shared.classify(
                    image: cgImage,
                    id: currentPhoto.id,
                    assetIdentifier: currentPhoto.assetIdentifier,
                    fileURL: currentPhoto.fileURL,
                    dateTaken: currentPhoto.dateTaken,
                    fileSizeBytes: currentPhoto.fileSizeBytes
                ) {
                    await MainActor.run {
                        self.currentPhoto = deepResult
                        self.isRunningDeepVision = false
                    }
                    return
                }
            }
            #endif
            await MainActor.run {
                self.isRunningDeepVision = false
            }
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
