// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ShadowChatMobile",
    platforms: [
        .iOS(.v17)
    ],
    products: [
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
                "ShadowDesignSystem",
                "ShadowChatListFeature"
            ]
        ),
        .testTarget(
            name: "ShadowChatListFeatureTests",
            dependencies: ["ShadowChatListFeature"]
        ),
        .testTarget(
            name: "ShadowRoomTimelineFeatureTests",
            dependencies: ["ShadowRoomTimelineFeature"]
        )
    ]
)
