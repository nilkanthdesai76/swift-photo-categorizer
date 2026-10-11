import Foundation

/// Fast O(1) taxonomy classifier mapping Apple Vision's 1,300+ hierarchical labels
/// into high-level user-friendly PhotoCategory domains.
public enum VisionTaxonomyMapper {
    
    // MARK: - Exact Label Lookup Dictionary
    
    private static let exactMap: [String: PhotoCategory] = {
        var map: [String: PhotoCategory] = [:]
        
        // --- People & Portraits ---
        let peopleKeywords = [
            "person", "people", "human", "adult", "child", "baby", "infant", "toddler",
            "boy", "girl", "man", "woman", "face", "portrait", "selfie", "crowd",
            "family", "couple", "parent", "mother", "father", "son", "daughter",
            "bride", "groom", "bride_groom", "wedding", "dancer", "athlete", "swimmer",
            "runner", "player", "musician", "singer", "acrobat", "friend", "audience"
        ]
        for k in peopleKeywords { map[k] = .people }
        
        // --- Food & Dining ---
        let foodKeywords = [
            "food", "dish", "meal", "cuisine", "recipe", "breakfast", "lunch", "dinner",
            "dessert", "snack", "beverage", "drink", "coffee", "espresso", "latte", "tea",
            "juice", "cocktail", "wine", "beer", "pizza", "burger", "hamburger", "sandwich",
            "salad", "soup", "pasta", "spaghetti", "noodles", "ramen", "sushi", "sashimi",
            "steak", "barbecue", "bbq", "chicken", "seafood", "fish_dish", "shrimp",
            "cake", "pastry", "croissant", "bread", "bakery", "cookie", "donut", "doughnut",
            "ice_cream", "chocolate", "fruit", "apple", "banana", "berry", "strawberry",
            "orange", "grape", "vegetable", "tomato", "potato", "onion", "carrot", "cheese"
        ]
        for k in foodKeywords { map[k] = .food }
        
        // --- Vehicles & Transport ---
        let vehicleKeywords = [
            "vehicle", "car", "automobile", "motor_vehicle", "sedan", "suv", "sports_car",
            "convertible", "truck", "pickup_truck", "van", "minivan", "bus", "train",
            "locomotive", "subway", "tram", "streetcar", "bicycle", "bike", "cyclist",
            "motorcycle", "motorbike", "scooter", "airplane", "aeroplane", "aircraft",
            "jet", "airplane_cabin", "helicopter", "boat", "ship", "yacht", "sailboat",
            "canoe", "kayak", "ferry", "submarine", "ambulance", "fire_truck", "police_car",
            "tractor", "trailer", "wheelchair", "wagon"
        ]
        for k in vehicleKeywords { map[k] = .vehicle }
        
        // --- Nature & Outdoors ---
        let natureKeywords = [
            "nature", "landscape", "scenery", "outdoor", "sky", "cloud", "sunset", "sunrise",
            "dawn", "dusk", "sun", "sunshine", "ocean", "sea", "beach", "coast", "shore",
            "wave", "sand", "mountain", "hill", "valley", "cliff", "canyon", "volcano",
            "forest", "woods", "jungle", "tree", "trees", "plant", "flora", "leaf", "leaves",
            "flower", "blossom", "rose", "tulip", "garden", "meadow", "field", "grass",
            "lake", "pond", "river", "stream", "creek", "waterfall", "desert", "snow",
            "ice", "glacier", "winter", "autumn", "spring", "summer", "wilderness",
            "wildlife", "animal", "deer", "bear", "lion", "tiger", "elephant", "zebra",
            "monkey", "frog", "snake", "lizard", "insect", "butterfly"
        ]
        for k in natureKeywords { map[k] = .nature }
        
        // --- Pets & Domestic Animals ---
        let petKeywords = [
            "pet", "pets", "domestic_animal", "dog", "puppy", "hound", "retriever", "bulldog",
            "poodle", "cat", "kitten", "adult_cat", "feline", "canine", "horse", "pony",
            "rabbit", "bunny", "hamster", "guinea_pig", "parrot", "canary", "goldfish",
            "aquarium", "turtle"
        ]
        for k in petKeywords { map[k] = .pets }
        
        // --- Indoor & Living Spaces ---
        let indoorKeywords = [
            "indoor", "indoors", "interior", "room", "living_room", "bedroom", "kitchen",
            "bathroom", "dining_room", "office", "home_office", "classroom", "library",
            "furniture", "couch", "sofa", "armchair", "chair", "table", "desk", "bed",
            "wardrobe", "closet", "cabinet", "shelf", "bookshelf", "lamp", "lighting",
            "chandelier", "ceiling", "floor", "carpet", "rug", "curtain", "window_blind",
            "door", "interior_door", "hallway", "corridor", "fireplace", "staircase", "stairs"
        ]
        for k in indoorKeywords { map[k] = .indoor }
        
        // --- Documents & Notes ---
        let documentKeywords = [
            "document", "paper", "receipt", "bill", "invoice", "ticket", "boarding_pass",
            "menu", "text", "handwriting", "font", "sign", "label", "blackboard",
            "whiteboard", "book", "page", "magazine", "newspaper", "notebook", "letter",
            "envelope", "certificate", "diploma", "passport", "id_card", "business_card",
            "screen", "monitor", "display", "screenshot", "diagram", "chart"
        ]
        for k in documentKeywords { map[k] = .documents }
        
        // --- City & Architecture ---
        let cityKeywords = [
            "city", "cityscape", "skyline", "urban", "metropolis", "downtown", "town",
            "building", "architecture", "skyscraper", "tower", "bridge", "monument",
            "palace", "castle", "church", "cathedral", "temple", "mosque", "stadium",
            "street", "road", "highway", "avenue", "alley", "sidewalk", "crosswalk",
            "traffic_light", "plaza", "square", "fountain"
        ]
        for k in cityKeywords { map[k] = .cityscape }
        
        return map
    }()
    
    // MARK: - Classification Mapping
    
    /// Maps a raw Vision classification identifier to a high-level category.
    public static func mapCategory(from identifier: String) -> PhotoCategory {
        let normalized = identifier.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Direct exact lookup
        if let direct = exactMap[normalized] {
            return direct
        }
        
        // 2. Keyword substring heuristics
        if normalized.contains("dog") || normalized.contains("cat") || normalized.contains("puppy") || normalized.contains("kitten") {
            return .pets
        }
        if normalized.contains("food") || normalized.contains("dish") || normalized.contains("meal") || normalized.contains("cake") || normalized.contains("fruit") || normalized.contains("drink") {
            return .food
        }
        if normalized.contains("car") || normalized.contains("vehicle") || normalized.contains("truck") || normalized.contains("bike") || normalized.contains("plane") || normalized.contains("boat") {
            return .vehicle
        }
        if normalized.contains("person") || normalized.contains("people") || normalized.contains("face") || normalized.contains("man") || normalized.contains("woman") {
            return .people
        }
        if normalized.contains("mountain") || normalized.contains("forest") || normalized.contains("water") || normalized.contains("beach") || normalized.contains("sky") || normalized.contains("tree") || normalized.contains("flower") {
            return .nature
        }
        if normalized.contains("room") || normalized.contains("kitchen") || normalized.contains("bedroom") || normalized.contains("furniture") || normalized.contains("interior") {
            return .indoor
        }
        if normalized.contains("building") || normalized.contains("city") || normalized.contains("street") || normalized.contains("bridge") || normalized.contains("architecture") {
            return .cityscape
        }
        if normalized.contains("document") || normalized.contains("paper") || normalized.contains("receipt") || normalized.contains("text") || normalized.contains("book") {
            return .documents
        }
        
        return .other
    }
}
