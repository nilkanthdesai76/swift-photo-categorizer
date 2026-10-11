import SwiftUI

/// Horizontal pill bar for filtering photos by AI semantic categories.
public struct CategoryFilterBar: View {
    @Binding public var selectedCategory: PhotoCategory?
    public let counts: [PhotoCategory: Int]
    public let totalCount: Int
    
    public init(
        selectedCategory: Binding<PhotoCategory?>,
        counts: [PhotoCategory: Int],
        totalCount: Int
    ) {
        self._selectedCategory = selectedCategory
        self.counts = counts
        self.totalCount = totalCount
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All Photos" button
                Button {
                    selectedCategory = nil
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.stack.fill")
                        Text("All")
                        Text("\(totalCount)")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(selectedCategory == nil ? Color.white.opacity(0.25) : Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .font(.subheadline.weight(selectedCategory == nil ? .semibold : .regular))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedCategory == nil ? Color.accentColor : Color.secondary.opacity(0.12))
                    .foregroundColor(selectedCategory == nil ? .white : .primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                // Individual Category buttons
                ForEach(PhotoCategory.allCases.sorted()) { category in
                    let count = counts[category, default: 0]
                    let isSelected = selectedCategory == category
                    
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.sfSymbol)
                            Text(category.displayName)
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(isSelected ? Color.white.opacity(0.25) : Color.secondary.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color(hex: category.themeColorHex) : Color.secondary.opacity(0.12))
                        .foregroundColor(isSelected ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
}

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 128, 128, 128)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
