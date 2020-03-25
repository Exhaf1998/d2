// swift-tools-version:4.2.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "D2",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // TODO: Use the upstream SwiftDiscord once vapor3 branch is merged
        .package(url: "https://github.com/nuclearace/SwiftDiscord.git", .revision("f8db5d698a3960f3cc1cedd29342357d0bfeccd6")),
        .package(url: "https://github.com/rapierorg/telegram-bot-swift.git", from: "2.0.0"),
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
            dependencies: ["Logging", "Commander", "D2Utils", "D2Handlers", "D2DiscordIO", "D2TelegramIO"]
        ),
        .target(
            name: "D2DiscordIO",
            dependencies: ["Logging", "SwiftDiscord", "D2MessageIO", "D2Utils"]
        ),
        .target(
            name: "D2TelegramIO",
            dependencies: ["Logging", "TelegramBotSDK", "D2MessageIO", "D2Utils"]
        ),
        .target(
            name: "D2Handlers",
            dependencies: ["Logging", "D2Utils", "D2MessageIO", "D2Permissions", "D2Commands"]
        ),
        .target(
            name: "D2Commands",
            dependencies: ["Logging", "SwiftSoup", "QRCodeGenerator", "PrologInterpreter", "D2Utils", "D2MessageIO", "D2Permissions", "D2Graphics", "D2Script", "D2NetAPIs"]
        ),
        .target(
            name: "D2Permissions",
            dependencies: ["Logging", "D2Utils", "D2MessageIO"]
        ),
        .target(
            name: "D2Script",
            dependencies: ["Logging", "D2Utils"]
        ),
        .target(
            name: "D2NetAPIs",
            dependencies: ["Logging", "D2Utils", "SwiftSoup", "Socket"]
        ),
        .target(
            name: "D2Graphics",
            dependencies: ["Logging", "D2Utils", "D2MessageIO", "Cairo"]
        ),
        .target(
            name: "D2MessageIO",
            dependencies: ["Logging", "D2Utils"]
        ),
        .target(
            name: "D2Utils",
            dependencies: ["Logging", "Socket"]
        ),
        .testTarget(
            name: "D2CommandTests",
            dependencies: ["D2Utils", "D2MessageIO", "D2TestUtils", "D2Commands"]
        ),
        .testTarget(
            name: "D2ScriptTests",
            dependencies: ["D2Utils", "D2Script"]
        ),
        .testTarget(
            name: "D2UtilsTests",
            dependencies: ["D2Utils", "D2MessageIO", "D2TestUtils"]
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
