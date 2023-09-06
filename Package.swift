// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "metamask-ios-sdk",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "metamask-ios-sdk",
            targets: ["metamask-ios-sdk"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/socketio/socket.io-client-swift", .upToNextMajor(from: "16.1.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "metamask-ios-sdk",
            dependencies: [
                .product(name: "SocketIO", package: "socket.io-client-swift"),
                "Ecies"
            ]),
        .binaryTarget(
                name: "Ecies",
                path: "Sources/metamask-ios-sdk/Frameworks/Ecies.xcframework"),
    ],
    swiftLanguageVersions: [.v5]
)
