// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PhotoCategoryKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "PhotoCategoryKit",
            targets: ["PhotoCategoryKit"]
        ),
        .executable(
            name: "PhotoCategorizerCLI",
            targets: ["PhotoCategorizerCLI"]
        )
    ],
    targets: [
        .target(
            name: "PhotoCategoryKit",
            path: "Sources/PhotoCategoryKit"
        ),
        .executableTarget(
            name: "PhotoCategorizerCLI",
            dependencies: ["PhotoCategoryKit"],
            path: "Sources/PhotoCategorizerCLI"
        ),
        .testTarget(
            name: "PhotoCategoryKitTests",
            dependencies: ["PhotoCategoryKit"],
            path: "Tests/PhotoCategoryKitTests"
        )
    ]
)
