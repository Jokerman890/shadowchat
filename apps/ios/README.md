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
- Der Standard-Build injiziert `MatrixRustClientService`. `PreviewShadowClientService` wird ausschließlich von Previews und Tests verwendet.

## Enthaltener Produkt-Slice
- Onboarding und explizite lokale Produktvorschau
- Session-State-Machine und austauschbarer Actor-Service
- Chat-Liste, Room-Navigation und sendbarer Composer
- Bridge Hub für Matrix, WhatsApp und Signal mit sichtbaren Trust-Signalen
- Security Center und Abmelde-Flow
- OIDC/MAS-Discovery und Passwort-Login nach Homeserver-Capabilities
- SAS-Geräteverifikation, Recovery und Key-Backup-Status
- APNs-Pusher und eingebettete Notification Service Extension
- konfigurierbare mautrix-whatsapp- und mautrix-signal-Management-Room-Adapter
- WhatsApp-inspirierte grüne Akzente, OLED Dark Mode und iOS-Material

## Matrix-Live-Adapter
`project.yml` pinnt `MatrixRustSDK`, `KeychainAccess` und `SwiftCrypto`. Der
produktive Actor implementiert `ShadowClientService`, persistiert Restoration
Tokens und Store-Passphrasen ausschließlich in der Keychain und hält SDK-Typen
aus UI- und Feature-Modulen heraus.

## Release-Konfiguration

Die folgenden Xcode-Build-Settings sind absichtlich leer und müssen je Umgebung
gesetzt werden:

- `SHADOW_PUSH_GATEWAY_URL`: vollständige HTTPS-URL des Matrix/Sygnal
  `/_matrix/push/v1/notify`-Endpoints
- `SHADOW_WHATSAPP_MANAGEMENT_ROOM_ID`: Room-ID des mautrix-whatsapp-Bots
- `SHADOW_WHATSAPP_BOT_USER_ID`: erwartete Matrix-User-ID des mautrix-whatsapp-Bots
- `SHADOW_SIGNAL_MANAGEMENT_ROOM_ID`: Room-ID des mautrix-signal-Bots
- `SHADOW_SIGNAL_BOT_USER_ID`: erwartete Matrix-User-ID des mautrix-signal-Bots

Für Gerätebuilds müssen außerdem `DEVELOPMENT_TEAM`, die App Group
`group.de.shadowchat.ios` und die Push-Capability im Apple Developer Account
provisioniert sein.

## Build und Tests
Auf macOS mit Xcode:
- `xcodegen generate`
- `cd Packages && swift test`
- `xcodebuild -list -project ShadowChat.xcodeproj`
- `xcodebuild build -project ShadowChat.xcodeproj -scheme ShadowChat -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO`

## Performance-Messung

Messbudgets, Referenzgeräte, Instruments-Ablauf und Signpost-Namen stehen in
`../../docs/quality/performance-baseline.md`. Runtime-Baselines werden mit
Release-Builds auf physischen Geräten erhoben; Debug- oder Simulatorzeiten
gelten nicht als Produktmessung. Textuelle Ergebnisse werden unter
`../../docs/quality/performance-results/` versioniert.
