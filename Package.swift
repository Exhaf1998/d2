// swift-tools-version:4.2.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "D2",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // TODO: Use the upstream SwiftDiscord once vapor3 branch is merged
        .package(url: "https://github.com/nuclearace/SwiftDiscord.git", .revision("67ee8a5b4e5779f9c6822f76b8e3c5cf99ed5d54")),
        .package(url: "https://github.com/PureSwift/Cairo.git", .revision("b5f867a56a20d2f0064ccb975ae4a669b374e9e0")),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.0.0"),
        .package(url: "https://github.com/IBM-Swift/BlueSocket.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/kylef/Commander.git", from: "0.9.1"),
        .package(url: "https://github.com/fwcd/swift-qrcode-generator.git", from: "0.0.2"),
        .package(url: "https://github.com/fwcd/swift-prolog.git", .revision("9cb83791eda7ec9861a26a3b5ae28aded78e1932"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "D2",
            dependencies: ["SwiftDiscord", "D2MessageIO", "Commander", "D2Utils", "D2Permissions", "D2Commands"]
        ),
        .target(
            name: "D2Shell",
            dependencies: ["D2Utils", "D2Permissions", "D2Commands"]
        ),
        .target(
            name: "D2Commands",
            dependencies: ["D2MessageIO", "SwiftSoup", "QRCodeGenerator", "PrologInterpreter", "D2Utils", "D2Permissions", "D2Graphics", "D2Script", "D2NetAPIs"]
        ),
        .target(
            name: "D2Permissions",
            dependencies: ["D2MessageIO", "D2Utils"]
        ),
        .target(
            name: "D2Script",
            dependencies: ["D2Utils"]
        ),
        .target(
            name: "D2NetAPIs",
            dependencies: ["D2Utils", "SwiftSoup", "Socket"]
        ),
        .target(
            name: "D2Graphics",
            dependencies: ["D2MessageIO", "D2Utils", "Cairo"]
        ),
        .target(
            name: "D2Utils",
            dependencies: ["D2MessageIO", "Socket", "Logging"]
        ),
        .target(
            name: "D2MessageIO"
        ),
        .testTarget(
            name: "D2CommandTests",
            dependencies: ["D2MessageIO", "D2Utils", "D2TestUtils", "D2Commands"]
        ),
        .testTarget(
            name: "D2ScriptTests",
            dependencies: ["D2Utils", "D2Script"]
        ),
        .testTarget(
            name: "D2UtilsTests",
            dependencies: ["D2MessageIO", "D2Utils", "D2TestUtils"]
        ),
        .testTarget(
            name: "D2GraphicsTests",
            dependencies: ["D2MessageIO", "D2TestUtils", "D2Graphics"]
        ),
        .testTarget(
            name: "D2NetAPITests",
            dependencies: ["D2MessageIO", "D2TestUtils", "D2NetAPIs"]
        ),
        .testTarget(
            name: "D2TestUtils",
            dependencies: ["D2MessageIO", "D2Commands"]
        )
    ]
)
