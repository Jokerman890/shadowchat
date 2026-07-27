# TD-0018 iOS Matrix Rust Runtime

## Status

Implementiert für Passwort-Login, sichere Sitzungswiederherstellung, Sliding-Sync,
Raumliste, Text-Timeline und Textversand. OIDC/MAS, Geräteverifikation, Push und
mautrix-Management bleiben getrennte Folgeslices.

## Ziel

Der produktive iOS-App-Einstieg verwendet MatrixRustSDK statt lokaler Demodaten,
ohne SDK-Typen in SwiftUI oder Feature-Modellen offenzulegen.

## Laufzeitkomposition

`ShadowChatApp` erzeugt genau eine Instanz von `MatrixRustClientService`. Derselbe
Actor wird in `ShadowAppState` sowie in die Chatlisten- und Timeline-Repositories
injiziert. Dadurch teilen Authentifizierung, Sync und Features einen Client und
einen Crypto-Store.

Die lokale `PreviewShadowClientService` bleibt ausschließlich für Previews und
deterministische App-Shell-Tests erhalten.

## Session und Storage

Für jede neue Anmeldung werden getrennte Application-Support- und Cache-Verzeichnisse
erzeugt. Der Matrix-SQLite-Store erhält eine kryptografisch zufällige Passphrase.

Das Restoration Token enthält:

- Matrix-Sitzung mit Access- und optionalem Refresh-Token
- Daten- und Cache-Verzeichnis
- Store-Passphrase

Das Token liegt ausschließlich in einer Keychain mit
`afterFirstUnlockThisDeviceOnly`. Daten- und Cache-Verzeichnisse sind vom
iCloud-Backup ausgeschlossen. Bei explizitem Logout entfernt ShadowChat Token
und Sitzungsverzeichnisse.

`ClientSessionDelegate` schreibt rotierte Matrix-Tokens zurück in denselben
Keychain-Eintrag.

## Authentifizierung

Der aktuelle Slice unterstützt HTTPS-Homeserver und Matrix-Passwort-Login.
Fehler werden an der Adaptergrenze in `ShadowServiceError` übersetzt.

OIDC/MAS ist laut ADR-0004 der bevorzugte Produktionspfad. Der noch folgende
OIDC-Slice muss Server-Capabilities entdecken und den Browser-Callback verarbeiten;
er darf das Passwort nicht als universell verfügbaren Fallback darstellen.

## Sync und Features

Nach Login oder Session-Restoration erstellt der Actor einen SDK-Sync-Service mit
Offline-Modus und geteilten Sliding-Sync-Positionen. `ShadowAppState` startet den
Sync für beide Pfade.

Die Chatliste bildet ausschließlich beigetretene Nicht-Space-Räume auf
`ChatListItemViewState` ab. Unverschlüsselte Räume erhalten einen reduzierten
Trust-Level.

Für einen geöffneten Raum erzeugt der Adapter eine Live-Timeline und verarbeitet
SDK-Diffs seriell im Actor. Die Feature-Grenze erhält ausschließlich Textnachrichten
als `RoomTimelineItemViewState`; virtuelle, State- und noch nicht unterstützte
Medienevents werden nicht als Text vorgetäuscht. Textversand nutzt die
Markdown-Content-Fabrik des SDK.

## Bridge-Verhalten

Matrix wird aus der aktiven Sitzung abgeleitet. WhatsApp und Signal werden als
`unavailable` ausgegeben, solange kein mautrix-Management-Adapter konfiguriert ist.
Die UI bietet in diesem Zustand keine wirkungslose Pairing-Aktion an.

## Concurrency

- `MatrixRustClientService` ist ein Actor.
- Listener liefern `Sendable` Timeline-Diffs in den Actor.
- KeychainAccess wird nur in einem `nonisolated`, thread-sicheren
  `ClientSessionDelegate` gekapselt.
- SwiftUI importiert MatrixRustSDK nicht.

## Validierung

Auf macOS:

- `xcodegen generate`
- `cd apps/ios/Packages && swift test`
- `xcodebuild build -project apps/ios/ShadowChat.xcodeproj -scheme ShadowChat -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO`

Zusätzlich:

- Login gegen Passwort-fähigen Test-Homeserver
- App-Neustart mit Session-Restoration
- Empfang und Versand in verschlüsseltem Testraum
- Logout entfernt Keychain-Token und Matrix-Store
