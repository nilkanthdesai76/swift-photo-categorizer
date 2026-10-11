import XCTest
import CoreGraphics
@testable import PhotoCategoryKit

final class PhotoCategoryKitTests: XCTestCase {
    
    // MARK: - 1. Metadata & Ordering Tests
    
    func testPhotoCategoryOrderingAndMetadata() {
        let all = PhotoCategory.allCases.sorted()
        XCTAssertEqual(all.first, .nature)
        XCTAssertEqual(all.last, .other)
        
        for category in PhotoCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
            XCTAssertFalse(category.sfSymbol.isEmpty)
            XCTAssertTrue(category.themeColorHex.hasPrefix("#"))
            XCTAssertEqual(category.themeColorHex.count, 7)
        }
    }
    
    // MARK: - 2. Taxonomy Exact Mapping Tests
    
    func testVisionTaxonomyMapperExactMapping() {
        XCTAssertEqual(VisionTaxonomyMapper.mapCategory(from: "mountain"), .nature)
        XCTAssertEqual(VisionTaxonomyMapper.mapCategory(from: "pizza"), .food)
        XCTAssertEqual(VisionTaxonomyMapper.mapCategory(from: "automobile"), .vehicle)
        XCTAssertEqual(VisionTaxonomyMapper.mapCategory(from: "living_room"), .indoor)
        XCTAssertEqual(VisionTaxonomyMapper.mapCategory(from: "portrait"), .people)
        XCTAssertEqual(VisionTaxonomyMapper.mapCategory(from: "receipt"), .documents)
        XCTAssertEqual(VisionTaxonomyMapper.mapCategory(from: "dog"), .pets)
        XCTAssertEqual(VisionTaxonomyMapper.mapCategory(from: "skyscraper"), .cityscape)
    }
    
    // MARK: - 3. Taxonomy Substring Heuristics
    
    func testVisionTaxonomyMapperSubstringHeuristics() {
        XCTAssertEqual(VisionTaxonomyMapper.mapCategory(from: "fast_sports_car"), .vehicle)
        XCTAssertEqual(VisionTaxonomyMapper.mapCategory(from: "fresh_organic_fruit"), .food)
        XCTAssertEqual(VisionTaxonomyMapper.mapCategory(from: "dense_green_forest_trees"), .nature)
        XCTAssertEqual(VisionTaxonomyMapper.mapCategory(from: "modern_kitchen_table"), .indoor)
        XCTAssertEqual(VisionTaxonomyMapper.mapCategory(from: "playful_puppy_dog"), .pets)
    }
    
    // MARK: - 4. Face Detection Result Models
    
    func testFaceDetectionResultNormalizedBoxes() {
        let box = NormalizedRect(x: 0.2, y: 0.3, width: 0.4, height: 0.4)
        let result = FaceDetectionResult(faceCount: 1, normalizedBoundingBoxes: [box])
        
        XCTAssertTrue(result.hasFaces)
        XCTAssertEqual(result.faceCount, 1)
        XCTAssertEqual(result.normalizedBoundingBoxes.first?.width, 0.4)
        XCTAssertEqual(result.normalizedBoundingBoxes.first?.cgRect.origin.x, 0.2)
        
        let empty = FaceDetectionResult()
        XCTAssertFalse(empty.hasFaces)
        XCTAssertEqual(empty.faceCount, 0)
    }
    
    // MARK: - 5. Classification Tag Formatting
    
    func testClassificationTagDisplayLabel() {
        let tag = ClassificationTag(identifier: "adult_golden_retriever", confidence: 0.92, category: .pets)
        XCTAssertEqual(tag.displayLabel, "Adult Golden Retriever")
        XCTAssertEqual(tag.category, .pets)
        XCTAssertEqual(tag.confidence, 0.92)
    }
    
    // MARK: - 6. Synthetic Photo Generation
    
    func testSyntheticPhotoGeneration() {
        for category in PhotoCategory.allCases {
            let image = SamplePhotoGenerator.generatePhoto(for: category, width: 120, height: 120)
            XCTAssertNotNil(image, "Failed to generate synthetic photo for \(category.displayName)")
            XCTAssertEqual(image?.width, 120)
            XCTAssertEqual(image?.height, 120)
        }
    }
    
    // MARK: - 7. Thumbnail Downscaler
    
    func testThumbnailRendererDownscaling() {
        guard let original = SamplePhotoGenerator.generatePhoto(for: .nature, width: 1000, height: 800) else {
            XCTFail("Could not create test image")
            return
        }
        
        guard let downscaled = ThumbnailRenderer.downscale(original, maxDimension: 360) else {
            XCTFail("Downscale failed")
            return
        }
        
        XCTAssertLessThanOrEqual(max(downscaled.width, downscaled.height), 360)
        
        let dominantColor = ThumbnailRenderer.computeDominantColor(from: downscaled)
        XCTAssertTrue(dominantColor.hasPrefix("#"))
        XCTAssertEqual(dominantColor.count, 7)
    }
    
    // MARK: - 8. Photo Classification Engine
    
    func testPhotoClassificationEngine() throws {
        guard let image = SamplePhotoGenerator.generatePhoto(for: .nature, width: 360, height: 360) else {
            XCTFail("Failed to generate test image")
            return
        }
        
        let classifier = PhotoClassifier()
        let result = try classifier.classify(image: image, id: "test_nature_01")
        
        XCTAssertEqual(result.id, "test_nature_01")
        XCTAssertTrue(result.primaryConfidence > 0.0)
        XCTAssertTrue(result.dominantColorHex.hasPrefix("#"))
    }
    
    // MARK: - 9. Face Detection Integration
    
    func testFaceDetectionIntegration() throws {
        guard let portrait = SamplePhotoGenerator.generatePhoto(for: .people, width: 360, height: 360) else {
            XCTFail("Failed to generate portrait image")
            return
        }
        
        let classifier = PhotoClassifier()
        let result = try classifier.classify(image: portrait, id: "test_people_01")
        
        // Portrait drawing contains eye/mouth features detectable by Vision face request
        XCTAssertTrue(result.primaryConfidence > 0.0)
        XCTAssertNotNil(result.primaryCategory)
    }
    
    // MARK: - 10. Thermal Governor Status & Delays
    
    func testThermalGovernorAdaptivePacing() {
        let governor = ThermalGovernor.shared
        XCTAssertFalse(governor.thermalStatusDescription.isEmpty)
        XCTAssertGreaterThan(governor.recommendedConcurrency, 0)
        
        // Pacing delays should be >= 0
        XCTAssertGreaterThanOrEqual(governor.pacingDelayNanoseconds, 0)
    }
    
    // MARK: - 11. Scan Result Aggregation
    
    func testClassificationScanResultAggregation() {
        let photo1 = CategorizedPhoto(primaryCategory: .nature, primaryConfidence: 0.95)
        let photo2 = CategorizedPhoto(primaryCategory: .food, primaryConfidence: 0.88)
        let photo3 = CategorizedPhoto(primaryCategory: .nature, primaryConfidence: 0.82)
        
        let result = ClassificationScanResult(allPhotos: [photo1, photo2, photo3], elapsedTimeSeconds: 1.5)
        
        XCTAssertEqual(result.totalScanned, 3)
        XCTAssertEqual(result.count(for: .nature), 2)
        XCTAssertEqual(result.count(for: .food), 1)
        XCTAssertEqual(result.count(for: .vehicle), 0)
        XCTAssertEqual(result.elapsedTimeSeconds, 1.5)
    }
}
