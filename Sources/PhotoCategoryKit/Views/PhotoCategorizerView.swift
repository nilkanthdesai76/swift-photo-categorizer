import SwiftUI
import Combine

/// Drop-in SwiftUI component for browsing, inspecting, and filtering AI-categorized photos.
public struct PhotoCategorizerView: View {
    public let photos: [CategorizedPhoto]
    public let isScanning: Bool
    public let progress: ClassificationProgress?
    public let onStartScan: (() -> Void)?
    
    @State private var selectedCategory: PhotoCategory?
    @State private var searchText: String = ""
    @State private var minConfidence: Double = 0.2
    @State private var inspectedPhoto: CategorizedPhoto?
    
    public init(
        photos: [CategorizedPhoto],
        isScanning: Bool = false,
        progress: ClassificationProgress? = nil,
        onStartScan: (() -> Void)? = nil
    ) {
        self.photos = photos
        self.isScanning = isScanning
        self.progress = progress
        self.onStartScan = onStartScan
    }
    
    private var categoryCounts: [PhotoCategory: Int] {
        var counts: [PhotoCategory: Int] = [:]
        for cat in PhotoCategory.allCases {
            counts[cat] = 0
        }
        for photo in photos {
            counts[photo.primaryCategory, default: 0] += 1
        }
        return counts
    }
    
    private var filteredPhotos: [CategorizedPhoto] {
        photos.filter { photo in
            // Category filter
            if let selected = selectedCategory, photo.primaryCategory != selected {
                return false
            }
            
            // Confidence filter
            if Double(photo.primaryConfidence) < minConfidence {
                return false
            }
            
            // Search text
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let matchesCategory = photo.primaryCategory.displayName.lowercased().contains(query)
                let matchesTag = photo.tags.contains { $0.identifier.lowercased().contains(query) }
                return matchesCategory || matchesTag
            }
            
            return true
        }
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)
    ]
    
    public var body: some View {
        VStack(spacing: 0) {
            // Scanning Status Banner
            if isScanning, let p = progress {
                VStack(spacing: 6) {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Classifying photos: \(p.processedCount)/\(p.totalCount)")
                            .font(.caption.bold())
                        Spacer()
                        Text(p.thermalStatus)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    ProgressView(value: p.fractionCompleted)
                        .tint(.accentColor)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.08))
            }
            
            // Category Filter Pills
            CategoryFilterBar(
                selectedCategory: $selectedCategory,
                counts: categoryCounts,
                totalCount: photos.count
            )
            
            Divider()
            
            // Photos Grid
            if filteredPhotos.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: selectedCategory?.sfSymbol ?? "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text(photos.isEmpty ? "No Photos Analyzed" : "No Matching Photos")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    if photos.isEmpty, let onStartScan {
                        Button("Start AI Classification", action: onStartScan)
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 4)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredPhotos) { photo in
                            PhotoCardView(photo: photo) {
                                inspectedPhoto = photo
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search tags (e.g. sunset, pizza, car)")
        .sheet(item: $inspectedPhoto) { photo in
            PhotoInspectorSheet(photo: photo) {
                inspectedPhoto = nil
            }
        }
    }
}
