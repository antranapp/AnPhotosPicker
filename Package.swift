// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AnPhotosPicker",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "AnPhotosPicker",
            targets: ["AnPhotosPicker"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AnPhotosPicker",
            dependencies: []
        ),
    ]
)
