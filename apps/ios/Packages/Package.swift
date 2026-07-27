// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ShadowChatMobile",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "ShadowCoreContracts",
            targets: ["ShadowCoreContracts"]
        ),
        .library(
            name: "ShadowDesignSystem",
            targets: ["ShadowDesignSystem"]
        ),
        .library(
            name: "ShadowChatListFeature",
            targets: ["ShadowChatListFeature"]
        ),
        .library(
            name: "ShadowRoomTimelineFeature",
            targets: ["ShadowRoomTimelineFeature"]
        ),
        .library(
            name: "ShadowChatAppShell",
            targets: ["ShadowChatAppShell"]
        )
    ],
    targets: [
        .target(
            name: "ShadowCoreContracts"
        ),
        .target(
            name: "ShadowDesignSystem"
        ),
        .target(
            name: "ShadowChatListFeature",
            dependencies: ["ShadowDesignSystem"]
        ),
        .target(
            name: "ShadowRoomTimelineFeature",
            dependencies: ["ShadowDesignSystem"]
        ),
        .target(
            name: "ShadowChatAppShell",
            dependencies: [
                "ShadowCoreContracts",
                "ShadowDesignSystem",
                "ShadowChatListFeature",
                "ShadowRoomTimelineFeature"
            ]
        ),
        .testTarget(
            name: "ShadowChatListFeatureTests",
            dependencies: ["ShadowChatListFeature"]
        ),
        .testTarget(
            name: "ShadowRoomTimelineFeatureTests",
            dependencies: ["ShadowRoomTimelineFeature"]
        ),
        .testTarget(
            name: "ShadowChatAppShellTests",
            dependencies: [
                "ShadowChatAppShell",
                "ShadowCoreContracts"
            ]
        )
    ]
)
