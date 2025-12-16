// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OutcomePredictor",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "OutcomePredictor",
            targets: ["OutcomePredictor"]
        ),
        .library(
            name: "OutcomePredictorAPI",
            targets: ["OutcomePredictorAPI"]
        ),
        .executable(
            name: "nfl-predict",
            targets: ["NFLPredictCLI"]
        ),
        .executable(
            name: "fetch-data",
            targets: ["FetchRealData"]
        ),
        .executable(
            name: "debug-espn",
            targets: ["DebugESPN"]
        ),
        .executable(
            name: "nfl-server",
            targets: ["NFLServer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.19.0"),
        .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OutcomePredictor",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .target(
            name: "OutcomePredictorAPI",
            dependencies: ["OutcomePredictor"]
        ),
        .executableTarget(
            name: "NFLServer",
            dependencies: [
                "OutcomePredictor",
                "OutcomePredictorAPI",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .executableTarget(
            name: "NFLPredictCLI",
            dependencies: ["OutcomePredictor"]
        ),
        .executableTarget(
            name: "FetchRealData",
            dependencies: ["OutcomePredictor"]
        ),
        .executableTarget(
            name: "DebugESPN",
            dependencies: ["OutcomePredictor"]
        ),
        .testTarget(
            name: "OutcomePredictorTests",
            dependencies: ["OutcomePredictor"]
        ),
    ]
)
