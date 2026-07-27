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
- `project.yml` erzeugt das iOS-18-/Swift-6-Projekt reproduzierbar mit XcodeGen.
- `ShadowChat/ShadowChatApp.swift` ist der SwiftUI App Entry Point.
- Das App-Target bindet das lokale SwiftPM-Package `Packages` ein und hostet `ShadowChatRootView` aus `ShadowChatAppShell`.
- `ShadowCoreContracts` kapselt Session-, Bridge-, Trust- und Pairing-Typen ohne SDK-Typen in der UI.
- Der Standard-Build startet bewusst mit `PreviewShadowClientService`; die Oberfläche kennzeichnet diese Laufzeit sichtbar und gibt sie nicht als echte Matrix-Sitzung aus.

## Enthaltener Produkt-Slice
- Onboarding und explizite lokale Produktvorschau
- Session-State-Machine und austauschbarer Actor-Service
- Chat-Liste, Room-Navigation und sendbarer Composer
- Bridge Hub für Matrix, WhatsApp und Signal mit sichtbaren Trust-Signalen
- Security Center und Abmelde-Flow
- WhatsApp-inspirierte grüne Akzente, OLED Dark Mode und iOS-Material

## Matrix-Live-Adapter
`project.yml` pinnt `MatrixRustSDK`, `KeychainAccess` und `SwiftCrypto`. Der produktive Adapter muss `ShadowClientService` implementieren und wird danach am App-Einstieg injiziert. Bis dieser Adapter inklusive sicherer Session-Persistenz, Sync und Crypto-Tests vorliegt, bleibt die Laufzeit explizit auf lokale Vorschau begrenzt.

## Build und Tests
Auf macOS mit Xcode:
- `xcodegen generate`
- `cd Packages && swift test`
- `xcodebuild -list -project ShadowChat.xcodeproj`
- `xcodebuild build -project ShadowChat.xcodeproj -scheme ShadowChat -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO`
