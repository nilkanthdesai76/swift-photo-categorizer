import SwiftUI
import PhotoCategoryKit

#if canImport(Photos)
import Photos
#endif

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Main interactive showcase view for PhotoCategoryKit iOS Demo App.
struct DemoContentView: View {
    @State private var selectedTab = 0
    
    // Categorization State
    @State private var photos: [CategorizedPhoto] = []
    @State private var isScanning = false
    @State private var scanProgress: ClassificationProgress?
    @State private var selectedSource = 1 // Default to 1 (Live Photo Library)
    @State private var scanAllPhotos = true // Default to true (Whole Photo Library!)
    @State private var useFastEngine = true // Default to true (⚡ Smart Fast Engine!)
    @State private var statusMessage: String = "Ready to categorize"
    @State private var activeScanTask: Task<Void, Never>?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                VStack(spacing: 0) {
                    // Source Picker
                    Picker("Photo Source", selection: $selectedSource) {
                        Text("Photo Library").tag(1)
                        Text("Sample Gallery").tag(0)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                    .onChange(of: selectedSource) { newSource in
                        activeScanTask?.cancel()
                        isScanning = false
                        if newSource == 0 {
                            loadSampleGallery()
                        } else {
                            photos = []
                            scanPhotoLibrary()
                        }
                    }
                    
                    // Engine & Scope Controls (Photo Library mode)
                    if selectedSource == 1 {
                        VStack(spacing: 6) {
                            Picker("Engine", selection: $useFastEngine) {
                                Text("⚡ Smart Fast (Zero Heat)").tag(true)
                                Text("🧠 Deep Vision (Heavy)").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: useFastEngine) { _ in
                                scanPhotoLibrary()
                            }
                            
                            HStack {
                                Text("Scope:")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                
                                Picker("Scope", selection: $scanAllPhotos) {
                                    Text("Whole Library (All Photos)").tag(true)
                                    Text("Quick Test (100 Photos)").tag(false)
                                }
                                .pickerStyle(.menu)
                                .font(.caption)
                                
                                Spacer()
                                
                                Button {
                                    ClassificationCache.shared.clear()
                                    scanPhotoLibrary()
                                } label: {
                                    Label("Clear Cache", systemImage: "trash")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 6)
                    }
                    
                    // Main Drop-In Categorizer View
                    PhotoCategorizerView(
                        photos: photos,
                        isScanning: isScanning,
                        progress: scanProgress,
                        onStartScan: {
                            if selectedSource == 0 {
                                loadSampleGallery()
                            } else {
                                scanPhotoLibrary()
                            }
                        }
                    )
                }
                .navigationTitle("AI Photo Categorizer")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        if isScanning {
                            Button(role: .destructive) {
                                cancelScan()
                            } label: {
                                Label("Stop", systemImage: "stop.circle.fill")
                                    .foregroundColor(.red)
                            }
                        } else {
                            Button {
                                if selectedSource == 0 {
                                    loadSampleGallery()
                                } else {
                                    scanPhotoLibrary()
                                }
                            } label: {
                                Label("Scan", systemImage: "arrow.clockwise")
                            }
                        }
                    }
                }
            }
            .tabItem {
                Label("Categories", systemImage: "square.grid.2x2.fill")
            }
            .tag(0)
            
            NavigationStack {
                VisionLabView()
            }
            .tabItem {
                Label("Vision Lab", systemImage: "cpu.fill")
            }
            .tag(1)
        }
        .task {
            // Automatically launch scan on startup
            if selectedSource == 1 {
                scanPhotoLibrary()
            } else {
                loadSampleGallery()
            }
        }
    }
    
    // MARK: - Actions
    
    private func cancelScan() {
        activeScanTask?.cancel()
        activeScanTask = nil
        isScanning = false
        statusMessage = "Scan cancelled"
    }
    
    private func loadSampleGallery() {
        activeScanTask?.cancel()
        isScanning = true
        statusMessage = "Generating and classifying synthetic photos..."
        photos = []
        
        activeScanTask = Task {
            var generated: [CategorizedPhoto] = []
            let classifier = PhotoClassifier.shared
            
            for (index, cat) in PhotoCategory.allCases.enumerated() {
                if Task.isCancelled { break }
                
                // Generate 2 sample images per category
                for i in 1...2 {
                    if let img = SamplePhotoGenerator.generatePhoto(for: cat, width: 360, height: 360) {
                        let id = "sample_\(cat.rawValue)_\(i)"
                        
                        #if canImport(UIKit)
                        PhotoThumbnailLoader.shared.cacheImage(UIImage(cgImage: img), for: id)
                        #elseif canImport(AppKit)
                        PhotoThumbnailLoader.shared.cacheImage(NSImage(cgImage: img, size: NSSize(width: 360, height: 360)), for: id)
                        #endif
                        
                        if let photo = try? classifier.classify(
                            image: img,
                            id: id,
                            dateTaken: Date(),
                            fileSizeBytes: 150_000
                        ) {
                            generated.append(photo)
                            await MainActor.run {
                                self.photos.append(photo)
                            }
                        }
                    }
                }
                
                await MainActor.run {
                    self.scanProgress = ClassificationProgress(
                        processedCount: index + 1,
                        totalCount: PhotoCategory.allCases.count,
                        currentItemName: cat.displayName,
                        thermalStatus: ThermalGovernor.shared.thermalStatusDescription
                    )
                }
            }
            
            await MainActor.run {
                self.isScanning = false
                self.statusMessage = "Loaded \(generated.count) sample photos"
            }
        }
    }
    
    private func scanPhotoLibrary() {
        #if canImport(Photos)
        activeScanTask?.cancel()
        isScanning = true
        statusMessage = "Accessing Photo Library..."
        photos = []
        
        activeScanTask = Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            guard status == .authorized || status == .limited else {
                await MainActor.run {
                    self.isScanning = false
                    self.statusMessage = "Photo Library access denied"
                }
                return
            }
            
            let maxCount = scanAllPhotos ? nil : 100
            let result: ClassificationScanResult
            
            if useFastEngine {
                let fastScanner = FastPhotoLibraryClassifier()
                result = await fastScanner.scanLibrary(
                    maxAssets: maxCount,
                    useCache: true,
                    progressHandler: { progress in
                        Task { @MainActor in
                            self.scanProgress = progress
                        }
                    },
                    onPhotoClassified: { photo, progress in
                        Task { @MainActor in
                            self.photos.append(photo)
                            self.scanProgress = progress
                        }
                    }
                )
            } else {
                let deepScanner = PhotoLibraryClassifier()
                result = await deepScanner.scanLibrary(
                    maxAssets: maxCount,
                    progressHandler: { progress in
                        Task { @MainActor in
                            self.scanProgress = progress
                        }
                    },
                    onPhotoClassified: { photo, progress in
                        Task { @MainActor in
                            self.photos.append(photo)
                            self.scanProgress = progress
                        }
                    }
                )
            }
            
            await MainActor.run {
                self.isScanning = false
                let engineLabel = useFastEngine ? "⚡ Fast Engine" : "🧠 Vision Engine"
                self.statusMessage = "[\(engineLabel)] Classified \(result.totalScanned) photos in \(String(format: "%.2f", result.elapsedTimeSeconds))s"
            }
        }
        #endif
    }
}

/// Vision Lab for benchmarking inference latency and hardware telemetry.
struct VisionLabView: View {
    @State private var benchmarkResult: String = "Tap 'Run ANE Benchmark' to test."
    @State private var isBenchmarking = false
    @State private var testedCategory: PhotoCategory = .nature
    
    var body: some View {
        List {
            Section("Apple Neural Engine (ANE) Benchmark") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Classifies synthetic images across all categories using Apple's Vision framework and computes execution latency per photo.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if isBenchmarking {
                        HStack {
                            ProgressView()
                            Text("Running on-device Vision inference...")
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button("Run ANE Benchmark") {
                            runBenchmark()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.vertical, 4)
                    }
                    
                    Text(benchmarkResult)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(8)
                }
                .padding(.vertical, 4)
            }
            
            Section("Hardware Thermal Telemetry") {
                HStack {
                    Text("Thermal State")
                    Spacer()
                    Text(ThermalGovernor.shared.thermalStatusDescription)
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Active CPU Cores")
                    Spacer()
                    Text("\(ProcessInfo.processInfo.activeProcessorCount)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Recommended Concurrency")
                    Spacer()
                    Text("\(ThermalGovernor.shared.recommendedConcurrency) threads")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Supported Categories") {
                ForEach(PhotoCategory.allCases.sorted()) { cat in
                    HStack {
                        Label(cat.displayName, systemImage: cat.sfSymbol)
                            .foregroundColor(Color(hex: cat.themeColorHex))
                        Spacer()
                        Circle()
                            .fill(Color(hex: cat.themeColorHex))
                            .frame(width: 12, height: 12)
                    }
                }
            }
        }
        .navigationTitle("Vision Lab")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func runBenchmark() {
        isBenchmarking = true
        
        Task {
            let classifier = PhotoClassifier.shared
            let iterations = 10
            var totalTimeMs: Double = 0
            
            for _ in 0..<iterations {
                if let img = SamplePhotoGenerator.generatePhoto(for: .nature, width: 360, height: 360) {
                    let start = CFAbsoluteTimeGetCurrent()
                    _ = try? classifier.classify(image: img)
                    let diff = (CFAbsoluteTimeGetCurrent() - start) * 1000.0
                    totalTimeMs += diff
                }
            }
            
            let avgTime = totalTimeMs / Double(iterations)
            
            await MainActor.run {
                self.benchmarkResult = String(format: "Average Vision inference: %.2f ms / photo\nThroughput: ~%.0f photos / sec\nThermal state: %@", avgTime, 1000.0 / avgTime, ThermalGovernor.shared.thermalStatusDescription)
                self.isBenchmarking = false
            }
        }
    }
}
