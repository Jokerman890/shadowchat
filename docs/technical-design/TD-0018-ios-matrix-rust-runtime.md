# TD-0018 iOS Matrix Rust Runtime

## Status

Implementiert für OIDC/MAS- und Passwort-Login, sichere Sitzungswiederherstellung,
Sliding-Sync, Raumliste, Text-Timeline, Textversand, Geräteverifikation, Recovery,
Push-Registrierung und mautrix-Management-Room-Kommandos.

## Ziel

Der produktive iOS-App-Einstieg verwendet MatrixRustSDK statt lokaler Demodaten,
ohne SDK-Typen in SwiftUI oder Feature-Modellen offenzulegen.

## Einordnung in die Zielarchitektur

Gemäß ADR-0016 ist `MatrixRustClientService` der native iOS-Plattformadapter.
Er verwendet intern das Rust-basierte `MatrixRustSDK`, ist aber nicht Teil des
gemeinsamen ShadowChat-Rust-Cores.

Session, Sync, Room List, Timeline, Crypto und Matrix-SDK-Store bleiben im
iOS-Adapter. Gemeinsame Shadow-Core-Policies dürfen später nur grobgranulare,
wertbasierte Eingaben verarbeiten; Timeline-Diffs, Room-List-Diffs und
SDK-Handles werden nicht durch eine zusätzliche ShadowChat-FFI geleitet.

## Laufzeitkomposition

`ShadowAppComposition` erzeugt genau eine Instanz von
`MatrixRustClientService`. Derselbe Actor wird in `ShadowAppState` sowie in die
Chatlisten- und Timeline-Repositories injiziert. Dadurch teilen
Authentifizierung, Sync und Features einen Client und einen Crypto-Store. Der
SwiftUI-App-Einstieg bleibt von konkreten Matrix-Implementierungstypen entkoppelt.

Die lokale `PreviewShadowClientService` bleibt ausschließlich für Previews und
deterministische App-Shell-Tests erhalten.

## Session und Storage

Für jede neue Anmeldung werden getrennte Application-Support- und Cache-Verzeichnisse
erzeugt. Der Matrix-SQLite-Store erhält eine kryptografisch zufällige Passphrase.

Das Restoration Token enthält:

- Matrix-Sitzung mit Access- und optionalem Refresh-Token
- Daten- und Cache-Verzeichnis
- Store-Passphrase
- optional die zum aktiven Account gehörenden APNs-Pusher-Identifikatoren

Das Token liegt ausschließlich in einer Keychain mit
`afterFirstUnlockThisDeviceOnly`. Daten- und Cache-Verzeichnisse sind vom
iCloud-Backup ausgeschlossen. Bei explizitem Logout entfernt ShadowChat Token
und Sitzungsverzeichnisse.

`ClientSessionDelegate` schreibt rotierte Matrix-Tokens zurück in denselben
Keychain-Eintrag.

Ein eigener Keychain-Marker benennt den aktiven Account. Restore und Logout
wählen deshalb niemals anhand einer lexikografisch sortierten Key-Liste. Beim
Logout wird genau der Token des aktiven Accounts entfernt.

Schlägt der Sync-Start unmittelbar nach Passwort- oder OAuth-Anmeldung fehl,
führt der App-State einen destruktiven lokalen Logout aus. Dadurch bleiben weder
eine wiederherstellbare Session noch ein authentifizierter Matrix-Client hinter
einer abgemeldeten UI bestehen.

## Authentifizierung

Der Adapter entdeckt die vom Homeserver veröffentlichten Login-Fähigkeiten.
OIDC/MAS wird bevorzugt und über `ASWebAuthenticationSession` ausgeführt. Der
MatrixRustSDK-Client erzeugt die Authorization-URL und verarbeitet den Callback.
Passwortfelder erscheinen nur, wenn der Homeserver Passwort-Login unterstützt.

OAuth-Zwischenzustände enthalten eigene Store-Verzeichnisse und werden bei Abbruch
einschließlich ihrer lokalen Daten verworfen. Erst nach erfolgreichem Callback
werden Client, Restoration Token und Store als aktive Sitzung übernommen. Fehler
werden an der Adaptergrenze in `ShadowServiceError` übersetzt.

## Sync und Features

Nach Login oder Session-Restoration erstellt der Actor einen SDK-Sync-Service mit
Offline-Modus und geteilten Sliding-Sync-Positionen. `ShadowAppState` startet den
Sync für beide Pfade.

Die Chatliste bildet ausschließlich beigetretene Nicht-Space-Räume auf
`ChatListItemViewState` ab. Unverschlüsselte Räume erhalten einen reduzierten
Trust-Level.

Für einen geöffneten Raum erzeugt der Adapter eine Live-Timeline und verarbeitet
SDK-Diffs seriell im Actor. Ein gepufferter `AsyncStream` liefert wertbasierte
Snapshots an das Feature und beendet den Listener beim Verlassen des Raums. Das
erste SDK-Update wird über ein explizites Signal mit Timeout erwartet. Die
Feature-Grenze erhält ausschließlich Textnachrichten als
`RoomTimelineItemViewState`; virtuelle, State- und noch nicht unterstützte
Medienevents werden nicht als Text vorgetäuscht. Textversand nutzt die
Markdown-Content-Fabrik des SDK; das SDK-Timeline-Event ist die einzige Quelle
für lokales Echo und Serverstatus.

## Bridge-Verhalten

Matrix wird aus der aktiven Sitzung abgeleitet. WhatsApp und Signal werden als
`unavailable` ausgegeben, solange kein mautrix-Management-Adapter konfiguriert ist.
Die UI bietet in diesem Zustand keine wirkungslose Pairing-Aktion an.

Die Build-Settings `SHADOW_WHATSAPP_MANAGEMENT_ROOM_ID`,
`SHADOW_WHATSAPP_BOT_USER_ID`, `SHADOW_SIGNAL_MANAGEMENT_ROOM_ID` und
`SHADOW_SIGNAL_BOT_USER_ID` aktivieren die jeweiligen Adapter. ShadowChat
sendet ausschließlich dokumentierte Management-Kommandos:

- mautrix-whatsapp: `login qr`, `cancel`, `logout`
- mautrix-signal: `login`, `cancel`, `logout`

QR-Bilder werden als Matrix-Medien geladen. Ein Adapter meldet erst dann
`connected`, wenn der konfigurierte Bridge-Bot in einem
Ende-zu-Ende-verschlüsselten Management-Raum innerhalb der aktiven
Pairing-Frist eine erfolgreiche Login-Antwort geliefert hat. Antworten anderer
Absender und Antworten vor Beginn des konkreten Bestätigungsschritts werden
ignoriert.
Bridge-Räume behalten immer den Trust-Hinweis für externen Transport. Die
Aufzählung von Ghost-/Puppet-Konten ist noch nicht durch einen stabilen
mautrix-Managementvertrag gedeckt und liefert deshalb keine erfundenen Kontakte.

## Verschlüsselungssicherheit

`ShadowSecurityService` bildet MatrixRustSDK-Zustände auf SDK-freie,
`Sendable`-Modelle für Gerätevertrauen, Recovery und Key Backup ab. Listener
wechseln aus beliebigen SDK-Threads zurück in den Service-Actor.

Die Geräteverifikation verwendet den SDK-`SessionVerificationController`.
SwiftUI erhält ausschließlich Emoji-Beschreibungen und Zustandsereignisse.
Bestätigung, Ablehnung und Abbruch laufen wieder actor-isoliert über den SDK-
Controller.

Recovery erzeugt beziehungsweise rotiert den Matrix-Wiederherstellungsschlüssel
mit `enableRecovery` und importiert einen vorhandenen Schlüssel mit
`recoverAndFixBackup`. Der neu erzeugte Schlüssel bleibt nur im Main-Actor-
UI-State, bis der Benutzer seine Sicherung bestätigt; er wird nicht in
UserDefaults oder Logausgaben geschrieben.

## Push und Notification Service Extension

APNs-Berechtigung und Token-Empfang sind Main-Actor-gebunden. Der Service
registriert den Base64-APNs-Token als `event_id_only` HTTP-Pusher über
`Client.setPusher`. `SHADOW_PUSH_GATEWAY_URL` muss im Release-Build die vollständige
HTTPS-Notify-Endpoint-URL enthalten. Ohne Wert bleibt Push bewusst deaktiviert.
Die Pusher-Identifikatoren werden accountgebunden im Restoration Token
gespeichert. Der App-State stellt diesen registrierten Zustand nach einem
Prozessneustart wieder her. Die APNs-Registrierung besitzt einen begrenzten
20-Sekunden-Wartepfad und reagiert auf Task-Abbruch, sodass kein wartender
Continuation-Pfad dauerhaft hängt.

Debug-Builds verwenden das APNs-Development-Environment, Release-Builds das
Production-Environment. Bei einem destruktiven Logout sind Pusher-Entfernung und
Remote-Logout Best Effort: Lokaler Keychain-Eintrag und Matrix-Verzeichnisse
werden trotzdem gelöscht. Ein lokaler Löschfehler bleibt sichtbar, nachdem der
In-Memory-State bereits sicher auf abgemeldet gesetzt wurde.

`ShadowChatNSE` ist ein eigenes Swift-6-App-Extension-Target. Der aktuelle Slice
ersetzt Serverinhalt durch „Neue verschlüsselte Nachricht“, übernimmt nur Room-
und Event-ID für den Open-Flow und liefert beim Zeitlimit den Original-Fallback
genau einmal aus. Er behauptet keine Ereignisentschlüsselung. Dafür sind vor
Release ein echtes Apple Development Team, der gemeinsame Keychain Access Group
und ein MatrixRustSDK-NSE-Client erforderlich.

Beim Antippen liest der App-Delegate `shadowchat_room_id` (mit `room_id` als
Fallback) und übergibt die Route an den App-Shell. Die Navigation wird erst in
einer authentifizierten Shell konsumiert.

## Concurrency

- `MatrixRustClientService` ist ein Actor.
- Listener liefern `Sendable` Timeline-Diffs in den Actor.
- Crypto-Listener und Verification-Delegates reichen nur `Sendable`
  ShadowChat-Werte in den Actor.
- KeychainAccess wird nur in einem `nonisolated`, thread-sicheren
  `ClientSessionDelegate` gekapselt.
- SwiftUI importiert MatrixRustSDK nicht.

## Performance- und Lifecycle-Grenzen

Der aktuelle Adapter ist funktional, aber noch nicht der Performance-Zielstand:

- `loadChatList()` fragt `roomInfo()` derzeit seriell pro Raum ab.
- `loadTimeline()` mappt beim Snapshot die vollständige gespeicherte Timeline.
- Die UI-Grenze mappt bei jedem Diff derzeit noch den vollständigen
  Timeline-Snapshot.
- Timeline-Kontexte ohne UI-Subscriber bleiben für Bridge-Managementpfade bis
  `stopSync()` oder Logout im Actor gespeichert.
- einzelne Front-Inserts und Front-Removes können lineare Array-Kosten
  verursachen.

P0-04 und P0-05 ersetzen diese Pfade durch inkrementelle Room-List-Daten,
Pagination, explizite Initialisierungssignale, begrenzte Timeline-Kontexte und
gezieltes Diff-Mapping. Gemessen werden Callback-zu-Repository-Latenz,
Main-Actor-Zeit, Kopiermengen, Queue-Tiefe und Speicher.

Adapterinterne Listener müssen bei Raum-, Session- und Accountwechsel
deterministisch beendet werden. Eine spätere Aufteilung des Actors darf nie
mehr als einen Client-, Sync-, Crypto- oder Store-Owner pro Account erzeugen.

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
- OIDC-Callback und abgebrochener OIDC-Flow
- SAS-Verifikation mit übereinstimmenden und abweichenden Emojis
- Recovery-Key-Erzeugung, Rotation und Wiederherstellung
- APNs-Pusher gegen das konfigurierte Sygnal-Gateway
- NSE-Zeitlimit und Payloads mit fehlender Room-/Event-ID
- WhatsApp- und Signal-Login gegen die konkrete mautrix-Konfiguration
