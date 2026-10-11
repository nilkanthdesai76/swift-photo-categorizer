# PhotoCategoryKit (swift-photo-categorizer)

[![CI](https://github.com/nilkanthdesai76/swift-photo-categorizer/actions/workflows/ci.yml/badge.svg)](https://github.com/nilkanthdesai76/swift-photo-categorizer/actions/workflows/ci.yml)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-F05138.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2016%2B%20%7C%20macOS%2013%2B-blue.svg)](https://apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An on-device, privacy-first AI photo categorization and smart album grouping framework for iOS and macOS. Powered by Apple's built-in **Vision framework** (`VNClassifyImageRequest` + `VNDetectFaceRectanglesRequest`) and the **Apple Neural Engine (ANE)** with zero external model downloads, sub-30MB RAM footprint, and battery-friendly thermal pacing.

---

## 🌟 Key Features

- 🧠 **1,300+ Vision Categories Mapped**: Maps Apple Vision's hierarchical taxonomy into 9 user-friendly photo domains:
  - 🌿 **Nature & Outdoors**: Mountains, sunsets, forests, beaches, flowers, oceans, wilderness.
  - 👥 **People & Portraits**: Solo portraits, group photos, family, selfies with automatic face counting.
  - 🍕 **Food & Dining**: Dishes, beverages, coffee, desserts, restaurants, recipes.
  - 🚗 **Vehicles & Transport**: Cars, motorcycles, bicycles, airplanes, boats, trains.
  - 🏠 **Indoor & Living**: Interior rooms, furniture, home decor, architecture.
  - 📄 **Documents & Receipts**: Invoices, receipts, whiteboards, notes, IDs, book pages.
  - 🏙️ **City & Architecture**: Skylines, skyscrapers, bridges, streets, monuments.
  - 🐾 **Pets & Animals**: Dogs, cats, puppies, domestic pets, wildlife.
  - 📷 **Other**: Abstract textures, unclassified snapshots.
- 👤 **Face Detection Heuristics**: Automatically counts faces, extracts normalized bounding boxes, and boosts portrait confidence without extra passes.
- ⚡ **Zero-Thermal Adaptive Pacing**: Monitors `ProcessInfo.processInfo.thermalState` via `ThermalGovernor` to scale parallel threads (4 → 2 → 1) and introduce millisecond delays if the device heats up.
- 🪶 **Ultra-Low Memory Footprint**: Feeds 360px hardware-downscaled thumbnails to Vision instead of 48MP raw buffers. Peak memory remains `< 30 MB` even on 10,000+ photo libraries.
- ☁️ **iCloud Friendly**: Fetches lightweight thumbnails through `PHImageManager` with `isNetworkAccessAllowed = true` without forcing multi-gigabyte original photo downloads.
- 🎨 **Drop-in SwiftUI Views**: Includes `PhotoCategorizerView`, `CategoryFilterBar`, `PhotoCardView`, and `PhotoInspectorSheet` with Vision tags breakdown.
- 📱 **Interactive iOS Demo App**: Includes a complete Xcode project with sample bundled scenes and live Photo Library scanning.

---

## 📦 Installation

Add `PhotoCategoryKit` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/nilkanthdesai76/swift-photo-categorizer.git", from: "1.0.0")
]
```

Or in Xcode: **File > Add Package Dependencies...** and enter the repository URL.

---

## 🚀 Quickstart

### 1. Classify a Single Image

```swift
import PhotoCategoryKit
import CoreGraphics

let classifier = PhotoClassifier.shared

// Classify any CGImage
let photo = try classifier.classify(image: cgImage)

print("Category: \(photo.primaryCategory.displayName)") // e.g. "Nature & Outdoors"
print("Confidence: \(photo.primaryConfidence * 100)%")   // e.g. "94%"
print("Faces: \(photo.faces.faceCount)")                 // e.g. 0
print("Top Tags: \(photo.tags.map { $0.displayLabel })") // ["Mountain", "Sky", "Lake"]
```

### 2. Ultra-Fast Zero-Heat Library Scan (30,000+ Photos)

Designed specifically for large libraries (10,000–50,000+ photos) where running heavy neural networks causes device heating and battery drain. Combines Apple's pre-indexed smart albums, 16×16 micro-pixel color physics ($Cb/Cr$ skin tone locus, foliage/sky ratios, document contrast), and persistent caching:

```swift
import PhotoCategoryKit

// 30,000 photos classified in ~1-3 seconds with ZERO device heating
let fastScanner = FastPhotoLibraryClassifier()

let result = await fastScanner.scanLibrary(
    maxAssets: nil, // entire photo library
    useCache: true,
    progressHandler: { progress in
        print("Progress: \(progress.processedCount)/\(progress.totalCount)")
    },
    onPhotoClassified: { photo, progress in
        // Streams classified photos live to your UI
    }
)

print("Classified \(result.totalScanned) photos in \(result.elapsedTimeSeconds)s")
```

### 3. Deep Vision On-Demand Single Photo Scan

For single photos or detailed inspector views, run full Vision ML inference on-demand:

```swift
let classifier = PhotoClassifier.shared
let detailed = try classifier.classify(image: cgImage)
print("Detected tags: \(detailed.tags.map { $0.displayLabel })")
print("Faces found: \(detailed.faces.faceCount)")
```

### 4. Drop-in SwiftUI Interface

```swift
import SwiftUI
import PhotoCategoryKit

struct MyPhotosView: View {
    @State private var categorizedPhotos: [CategorizedPhoto] = []
    @State private var isScanning = false
    
    var body: some View {
        PhotoCategorizerView(
            photos: categorizedPhotos,
            isScanning: isScanning,
            onStartScan: {
                startCategorization()
            }
        )
    }
    
    private func startCategorization() {
        // Run PhotoLibraryClassifier and update categorizedPhotos
    }
}
```

---

## 📱 Running the iOS Demo App

Run the included launcher script to verify and open the Demo app:

```bash
git clone https://github.com/nilkanthdesai76/swift-photo-categorizer.git
cd swift-photo-categorizer
./launch-demo.sh
```

Or open in Xcode:

```bash
open Demo/Demo.xcodeproj
```

---

## 🧪 Testing

Run the unit test suite locally:

```bash
swift test
```

Or with Xcode:

```bash
xcodebuild -scheme PhotoCategoryKit -destination "generic/platform=macOS" test
```

---

## 📄 License

MIT License. Free to use in commercial and personal apps.
