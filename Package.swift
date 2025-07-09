// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MKiOSMcuManagerLibrary",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "MKiOSMcuManagerLibrary",
            type: .dynamic,
            targets: ["MKiOSMcuManagerLibrary"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/NordicSemiconductor/IOS-nRF-Connect-Device-Manager.git",
            exact: "1.3.1"  // Using exact version for stability
        ),
    ],
    targets: [
        .target(
            name: "MKiOSMcuManagerLibrary",
            dependencies: [
                .product(
                    name: "iOSMcuManagerLibrary",
                    package: "IOS-nRF-Connect-Device-Manager"
                )
            ],
            path: "Sources",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("IOS14_OR_LATER")
            ], linkerSettings: [
                .linkedFramework("CoreBluetooth"),
                .linkedFramework("Combine")
            ]
        ),
        .testTarget(
            name: "MKiOSMcuManagerLibraryTests",
            dependencies: ["MKiOSMcuManagerLibrary"])
    ]
)
