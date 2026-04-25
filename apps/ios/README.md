# iOS App

Hier liegt die native iOS-App von ShadowChat.

## Erwartete Bereiche
- App Target
- Notification Service Extension
- Share Extension
- Design- und Motion-Module
- Feature-Module

## UI-Stack
SwiftUI mit klarer Trennung von UI, Navigation, Services und Domain-Modellen.

## Aktueller App-Einstieg
- `ShadowChat.xcodeproj` enthält das minimale iOS-App-Target `ShadowChat`.
- `ShadowChat/ShadowChatApp.swift` ist der SwiftUI App Entry Point.
- Das App-Target bindet das lokale SwiftPM-Package `Packages` ein und hostet `ShadowChatRootView` aus `ShadowChatAppShell`.

## Build und Tests
Auf macOS mit Xcode:
- `xcodebuild -list -project ShadowChat.xcodeproj`
- `xcodebuild build -project ShadowChat.xcodeproj -scheme ShadowChat -sdk iphonesimulator -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO`
