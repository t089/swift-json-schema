// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-json-schema",
    products: [
        .library(
            name: "JSONSchema",
            targets: ["JSONSchema"]),
    ],
    dependencies: [
        .package(url: "https://github.com/t089/swift-json-macros.git", branch: "new-codable"),
        //.package(path: "../swift-json-macros"),
    ],
    targets: [
        .target(
            name: "JSONSchema",
            dependencies: [
                .product(name: "JSONMacros", package: "swift-json-macros"),
            ]),
        .testTarget(
            name: "JSONSchemaTests",
            dependencies: ["JSONSchema"]
        ),
    ]
)
