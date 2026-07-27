# TD-0017 iOS Product Shell

## Status

Implementierter iOS-Produkt-Shell. Der App-Einstieg verwendet den in TD-0018
beschriebenen Matrix-Live-Adapter; die lokale Laufzeit bleibt für Previews und Tests.

## Ziel

Der iOS-Produkt-Shell verbindet die vorhandenen Chat- und Timeline-Features mit einem testbaren Session-Lifecycle, Bridge Hub, Security Center und einer sendbaren Composer-Grenze.

## Module

### ShadowCoreContracts

Enthält wertbasierte, `Sendable`-konforme Modelle und Actor-Protokolle:

- `ShadowSessionSnapshot`
- `ShadowSessionState`
- `ShadowAccount`
- `ShadowBridgeSnapshot`
- `ShadowPairingSession`
- `ShadowSessionService`
- `ShadowBridgeService`
- `ShadowClientService`

Das Modul importiert weder SwiftUI noch MatrixRustSDK.

### ShadowChatAppShell

`ShadowAppState` ist `@MainActor`-isoliert und mit Observation beobachtbar. Er besitzt den injizierten `ShadowClientService` und übersetzt Service-Ergebnisse in UI-State.

`PreviewShadowClientService` ist ein Actor für deterministische lokale Produktflüsse. Die Onboarding-UI kennzeichnet diesen Modus sichtbar. Der Service speichert keine Zugangsdaten und führt keine Netzwerkzugriffe aus. Der ausgelieferte App-Einstieg injiziert dagegen `MatrixRustClientService`.

### Room Timeline

`RoomTimelineRepository` besitzt zusätzlich zu `loadTimeline` eine asynchrone `sendMessage`-Grenze. `RoomTimelineViewModel` verwaltet Entwurf, laufenden Sendestatus und Fehler. Ein erfolgreicher Send fügt das Repository-Ergebnis der aktuellen Timeline hinzu; ein Fehler erhält den Entwurf.

## Navigation

Nach einer aktiven Sitzung zeigt die Root View vier Bereiche:

1. Chats
2. Anrufe
3. Bridges
4. Einstellungen / Security Center

Room-Navigation bleibt im App-Shell, während Chat-Liste und Timeline stateless Feature-Views bleiben.

## Trust-Regeln

- Matrix wird als nativer verschlüsselter Kontext dargestellt.
- WhatsApp und Signal werden als externe verschlüsselte Transporte dargestellt.
- Pairing und Disconnect sind explizite Benutzeraktionen.
- Eine Bridge-Warnung bleibt nach erfolgreicher Kopplung sichtbar.
- Die lokale Vorschau wird niemals als Matrix-Live-Sitzung bezeichnet.

## Build

`apps/ios/project.yml` definiert:

- iOS 18
- Swift 6
- vollständige Strict-Concurrency-Prüfung
- `MatrixRustSDK` in der von Element X verwendeten Version
- `KeychainAccess`
- `SwiftCrypto`
- SwiftLint Build Tool Plugin

## Noch notwendige Produktionsarbeit

Der App-Store-fähige Matrix-Live-Build benötigt nach TD-0018 weiterhin:

- OIDC/MAS und Password-Login gemäß Server-Capabilities
- E2EE-Verifikation und Recovery
- Push/NSE und Share Extension
- reale mautrix-Management-Room-Adapter

## Validierung

Auf macOS:

- `xcodegen generate`
- `cd apps/ios/Packages && swift test`
- `xcodebuild build -project apps/ios/ShadowChat.xcodeproj -scheme ShadowChat -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO`

Plattformunabhängig:

- `git diff --check`
- keine Secrets in Session-/Bridge-DTOs
- keine MatrixRustSDK-Typen in SwiftUI-Features
