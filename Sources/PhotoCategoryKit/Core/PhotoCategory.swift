import Foundation

/// Primary semantic categories for AI-driven photo classification.
/// Maps hierarchical Apple Vision classification taxonomies into user-friendly collections.
public enum PhotoCategory: String, Codable, CaseIterable, Identifiable, Sendable, Comparable {
    case nature
    case people
    case food
    case vehicle
    case indoor
    case documents
    case cityscape
    case pets
    case other
    
    public var id: String { rawValue }
    
    /// User-facing localized title.
    public var displayName: String {
        switch self {
        case .nature:
            return "Nature & Outdoors"
        case .people:
            return "People & Portraits"
        case .food:
            return "Food & Dining"
        case .vehicle:
            return "Vehicles & Transport"
        case .indoor:
            return "Indoor & Living"
        case .documents:
            return "Documents & Receipts"
        case .cityscape:
            return "City & Architecture"
        case .pets:
            return "Pets & Animals"
        case .other:
            return "Other"
        }
    }
    
    /// SF Symbol icon name suitable for iOS and macOS UI.
    public var sfSymbol: String {
        switch self {
        case .nature:
            return "leaf.fill"
        case .people:
            return "person.2.fill"
        case .food:
            return "fork.knife"
        case .vehicle:
            return "car.fill"
        case .indoor:
            return "house.fill"
        case .documents:
            return "doc.text.fill"
        case .cityscape:
            return "building.2.fill"
        case .pets:
            return "pawprint.fill"
        case .other:
            return "photo.fill"
        }
    }
    
    /// Accent color hint for badges and charts.
    public var themeColorHex: String {
        switch self {
        case .nature:
            return "#34C759" // Green
        case .people:
            return "#007AFF" // Blue
        case .food:
            return "#FF9500" // Orange
        case .vehicle:
            return "#FF3B30" // Red
        case .indoor:
            return "#AF52DE" // Purple
        case .documents:
            return "#FFCC00" // Yellow
        case .cityscape:
            return "#5856D6" // Indigo
        case .pets:
            return "#FF2D55" // Pink
        case .other:
            return "#8E8E93" // Gray
        }
    }
    
    /// Sort priority in the UI category selector.
    public var displayOrder: Int {
        switch self {
        case .nature: return 0
        case .people: return 1
        case .food: return 2
        case .vehicle: return 3
        case .indoor: return 4
        case .cityscape: return 5
        case .pets: return 6
        case .documents: return 7
        case .other: return 8
        }
    }
    
    public static func < (lhs: PhotoCategory, rhs: PhotoCategory) -> Bool {
        lhs.displayOrder < rhs.displayOrder
    }
}
