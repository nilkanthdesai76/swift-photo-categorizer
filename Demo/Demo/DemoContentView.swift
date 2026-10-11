import SwiftUI
import PhotoCategoryKit

#if canImport(Photos)
import Photos
#endif

/// Main interactive showcase view for PhotoCategoryKit iOS Demo App.
struct DemoContentView: View {
    @State private var selectedTab = 0
    
    // Categorization State
    @State private var photos: [CategorizedPhoto] = []
    @State private var isScanning = false
    @State private var scanProgress: ClassificationProgress?
    @State private var selectedSource = 0 // 0: Synthetic Gallery, 1: Photo Library
    @State private var statusMessage: String = "Ready to categorize"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                VStack(spacing: 0) {
                    // Source Picker
                    Picker("Photo Source", selection: $selectedSource) {
                        Text("Sample Gallery").tag(0)
                        Text("Photo Library").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .onChange(of: selectedSource) { newSource in
                        if newSource == 0 {
                            loadSampleGallery()
                        } else {
                            photos = []
                        }
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
                        Button {
                            if selectedSource == 0 {
                                loadSampleGallery()
                            } else {
                                scanPhotoLibrary()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(isScanning)
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
            loadSampleGallery()
        }
    }
    
    // MARK: - Actions
    
    private func loadSampleGallery() {
        isScanning = true
        statusMessage = "Generating and classifying synthetic photos..."
        
        Task {
            var generated: [CategorizedPhoto] = []
            let classifier = PhotoClassifier.shared
            
            for (index, cat) in PhotoCategory.allCases.enumerated() {
                // Generate 2 sample images per category
                for i in 1...2 {
                    if let img = SamplePhotoGenerator.generatePhoto(for: cat, width: 360, height: 360) {
                        if let photo = try? classifier.classify(
                            image: img,
                            id: "\(cat.rawValue)_\(i)",
                            dateTaken: Date(),
                            fileSizeBytes: 150_000
                        ) {
                            generated.append(photo)
                        }
                    }
                }
                
                scanProgress = ClassificationProgress(
                    processedCount: index + 1,
                    totalCount: PhotoCategory.allCases.count,
                    currentItemName: cat.displayName,
                    thermalStatus: ThermalGovernor.shared.thermalStatusDescription
                )
            }
            
            await MainActor.run {
                self.photos = generated
                self.isScanning = false
                self.statusMessage = "Loaded \(generated.count) sample photos"
            }
        }
    }
    
    private func scanPhotoLibrary() {
        #if canImport(Photos)
        isScanning = true
        statusMessage = "Scanning Photo Library..."
        
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            guard status == .authorized || status == .limited else {
                await MainActor.run {
                    self.isScanning = false
                    self.statusMessage = "Photo Library access denied"
                }
                return
            }
            
            let scanner = PhotoLibraryClassifier()
            let result = await scanner.scanLibrary(maxAssets: 50) { progress in
                Task { @MainActor in
                    self.scanProgress = progress
                }
            }
            
            await MainActor.run {
                self.photos = result.allPhotos
                self.isScanning = false
                self.statusMessage = "Classified \(result.totalScanned) photos in \(String(format: "%.1f", result.elapsedTimeSeconds))s"
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
