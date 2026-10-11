import Foundation
import PhotoCategoryKit

@main
struct PhotoCategorizerCLI {
    static func main() async {
        let args = CommandLine.arguments
        
        guard args.count > 1 else {
            print("""
            PhotoCategorizer CLI - On-device AI Photo Categorization
            
            Usage:
              PhotoCategorizerCLI <path-to-folder> [--json]
            
            Example:
              PhotoCategorizerCLI ~/Pictures --json
            """)
            exit(0)
        }
        
        let path = NSString(string: args[1]).expandingTildeInPath
        let folderURL = URL(fileURLWithPath: path)
        let outputJSON = args.contains("--json")
        
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDir), isDir.boolValue else {
            print("Error: Directory not found at \(path)")
            exit(1)
        }
        
        print("🔍 Scanning and classifying photos in: \(folderURL.path)")
        let classifier = DirectoryClassifier()
        
        do {
            let result = try await classifier.scan(directoryURL: folderURL) { progress in
                let pct = String(format: "%.1f%%", progress.fractionCompleted * 100)
                print("\r[\(pct)] Analyzing \(progress.processedCount)/\(progress.totalCount) (\(progress.currentItemName))", terminator: "")
                fflush(stdout)
            }
            print("\n")
            
            if outputJSON {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(result.allPhotos)
                if let str = String(data: data, encoding: .utf8) {
                    print(str)
                }
            } else {
                print("==================================================")
                print("   AI CLASSIFICATION RESULTS (\(result.totalScanned) photos)")
                print("   Elapsed: \(String(format: "%.2f", result.elapsedTimeSeconds))s")
                print("==================================================")
                
                for category in PhotoCategory.allCases.sorted() {
                    let photos = result.photosByCategory[category] ?? []
                    guard !photos.isEmpty else { continue }
                    print("\n📂 \(category.displayName) (\(photos.count) photos):")
                    for photo in photos.prefix(5) {
                        let topTag = photo.tags.first?.displayLabel ?? "unknown"
                        let faceStr = photo.faces.hasFaces ? " | \(photo.faces.faceCount) face(s)" : ""
                        let name = photo.fileURL?.lastPathComponent ?? photo.id
                        print("   • \(name) [\(Int(photo.primaryConfidence * 100))%] (\(topTag)\(faceStr))")
                    }
                    if photos.count > 5 {
                        print("   ... and \(photos.count - 5) more")
                    }
                }
                print("\n==================================================")
            }
        } catch {
            print("Classification failed: \(error.localizedDescription)")
            exit(1)
        }
    }
}
