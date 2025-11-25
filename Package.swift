// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OutcomePredictor",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "OutcomePredictor",
            targets: ["OutcomePredictor"]
        ),
        .executable(
            name: "nfl-predict",
            targets: ["NFLPredictCLI"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OutcomePredictor"
        ),
        .executableTarget(
            name: "NFLPredictCLI",
            dependencies: ["OutcomePredictor"]
        ),
        .testTarget(
            name: "OutcomePredictorTests",
            dependencies: ["OutcomePredictor"]
        ),
    ]
)
