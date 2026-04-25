# iOS Packages

Hier liegen wiederverwendbare iOS-Module wie Design, Motion, Navigation, Services und Bindings.

## SwiftPM
- Package: `ShadowChatMobile`
- Libraries: `ShadowDesignSystem`, `ShadowChatListFeature`, `ShadowChatAppShell`
- Tests: `ShadowChatListFeatureTests`

## App-Shell
- `ShadowChatAppShell` stellt `ShadowChatRootView` bereit.
- `ShadowChatRootView` hostet die vorhandene Chat-Liste in einem `NavigationStack`.
- Das installierbare iOS-App-Target liegt außerhalb des Packages unter `apps/ios/ShadowChat.xcodeproj`.

## Build und Tests
Auf macOS mit Xcode:
- `xcodebuild -list`
- `xcodebuild test -scheme ShadowChatMobile -destination "platform=iOS Simulator,name=<iPhone Simulator>"`

Auf Windows ist Swift/Xcode in der Regel nicht verfügbar; die iOS-Validierung erfolgt über macOS/Xcode oder CI.
