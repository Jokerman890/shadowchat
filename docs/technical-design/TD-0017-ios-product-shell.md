# TD-0017 iOS Product Shell

## Status

Implementierter iOS-Produkt-Shell. Der App-Einstieg verwendet den in TD-0018
beschriebenen Matrix-Live-Adapter; die lokale Laufzeit bleibt für Previews und Tests.

Der Matrix-Live-Adapter ist gemäß ADR-0016 der native iOS-Plattformadapter. Er
ist nicht die gemeinsame ShadowChat-Rust-Laufzeit.

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
- `ShadowSecurityService`
- `ShadowPushService`
- `ShadowClientService`

Das Modul importiert weder SwiftUI noch MatrixRustSDK.

### ShadowChatAppShell

`ShadowAppState` ist `@MainActor`-isoliert und mit Observation beobachtbar. Er besitzt den injizierten `ShadowClientService` und übersetzt Service-Ergebnisse in UI-State.

`PreviewShadowClientService` ist ein Actor für deterministische lokale Produktflüsse. Die Onboarding-UI kennzeichnet diesen Modus sichtbar. Der Service speichert keine Zugangsdaten und führt keine Netzwerkzugriffe aus. Der ausgelieferte App-Einstieg injiziert dagegen `MatrixRustClientService`.

Die produktive Objektkomposition liegt in `ShadowAppComposition`. Der SwiftUI-
App-Einstieg kennt nur `ShadowAppState`, `ShadowRepositoryProvider` und den
Notification-Router; konkrete Matrix-Services werden nicht im Scene-Aufbau
verdrahtet.

### Room Timeline

`RoomTimelineRepository` besitzt zusätzlich zu `loadTimeline` einen
lifecycle-gebundenen `AsyncStream` für Timeline-Snapshots und eine asynchrone
`sendMessage`-Grenze. `RoomTimelineViewModel` verwaltet Entwurf, laufenden
Sendestatus und Fehler. Ein erfolgreicher Send leert den Entwurf; lokales Echo
und Serverbestätigung kommen ausschließlich aus dem Matrix-Timeline-Stream,
damit kein synthetisches Duplikat entsteht. Die Timeline zeigt den tatsächlichen
Raum-Verschlüsselungsstatus und bietet den Composer auch in einem leeren Raum an.

## Navigation

Nach einer aktiven Sitzung zeigt die Root View vier Bereiche:

1. Chats
2. Anrufe
3. Bridges
4. Einstellungen / Security Center

Room-Navigation bleibt im App-Shell, während Chat-Liste und Timeline stateless Feature-Views bleiben.

Ein `ShadowNotificationRouter` übergibt die normalisierte Raum-ID aus einer
angetippten Push-Benachrichtigung an den authentifizierten Shell. Die ausstehende
Route wird genau einmal konsumiert, wechselt in den Chat-Bereich und ersetzt den
vorherigen Chat-Navigationspfad.

Einstellungen zeigen nur Funktionen mit angeschlossenem Produktverhalten.
App-Sperre, Lesebestätigungen und Link-Vorschauen werden erst wieder als Controls
angeboten, wenn persistierte Policies und ihre Laufzeitwirkung implementiert sind.

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

Der aktuelle Slice enthält Matrix-Live-Sitzungen, OIDC/MAS, SAS-Verifikation,
Recovery, Push-Registrierung, eine datensparsame NSE und konfigurierbare
mautrix-Management-Room-Adapter. Vor einer App-Store-Auslieferung bleiben:

- Apple-Team-, App-Group- und Push-Gateway-Konfiguration für den Release-Build
- Shared-Keychain-Zugriff und Matrix-Ereignisentschlüsselung in der NSE
- Share Extension
- Mediennachrichten und produktive Call-Integration
- End-to-End-QA gegen die konkret betriebenen Homeserver und mautrix-Instanzen

## Validierung

Auf macOS:

- `xcodegen generate`
- `cd apps/ios/Packages && swift test`
- `xcodebuild build -project apps/ios/ShadowChat.xcodeproj -scheme ShadowChat -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO`

Plattformunabhängig:

- `git diff --check`
- keine Secrets in Session-/Bridge-DTOs
- keine MatrixRustSDK-Typen in SwiftUI-Features
