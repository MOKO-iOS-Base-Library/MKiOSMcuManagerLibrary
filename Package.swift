// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MKiOSMcuManagerLibrary",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "MKiOSMcuManagerLibrary",
            type: .dynamic,
            targets: ["MKiOSMcuManagerLibrary"]),
    ],
    dependencies: [
        .package(url: "https://github.com/NordicSemiconductor/IOS-nRF-Connect-Device-Manager.git", exact: "1.9.2"),
    ],
    targets: [
        .target(
            name: "MKiOSMcuManagerLibrary",
            dependencies: [
                .product(name: "iOSMcuManagerLibrary", package: "IOS-nRF-Connect-Device-Manager")
            ],
            path: "Sources",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("IOS14_OR_LATER")  // 添加编译标志
            ]
        ),
        .testTarget(
            name: "MKiOSMcuManagerLibraryTests",
            dependencies: ["MKiOSMcuManagerLibrary"],
            path: "Tests"
        )
    ]
)
