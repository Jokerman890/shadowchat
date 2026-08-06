# TD-0012 Matrix Integration Readiness Audit

## Status

Historisches Readiness-Audit. Die damals offene Matrix-Core-Frage ist mit
ADR-0016 zugunsten einer hybriden Architektur entschieden. iOS besitzt
inzwischen eine Live-Anbindung; Android verwendet weiterhin Demodaten.

## Ziel

Dieses Dokument bewertet, wie gut die bestehenden Mobile-, Rust-, FFI-, Repository-, State- und Demo-Data-Grenzen auf eine spaetere echte Matrix Room List / Timeline Integration vorbereitet sind.

Der Fokus liegt auf Readiness, Boundary-Gaps und konkreter Integrationsreihenfolge. Es entstehen keine Netzwerkzugriffe, keine produktive Persistenz, keine echten Sessions und keine Matrix-Credentials.

## Bestehender Stand

### Mobile Shell

- Android besitzt `:app`, `:designsystem`, `:features:chatlist` und `:features:timeline`.
- iOS besitzt ein App Target `ShadowChat` und SwiftPM-Targets fuer `ShadowDesignSystem`, `ShadowChatListFeature`, `ShadowRoomTimelineFeature` und `ShadowChatAppShell`.
- Chat-Liste und Room Timeline werden als native UI-Slices gehostet.
- Die App-Shell haelt nur lokalen Navigation-State.
- Runtime-Demo-Daten sind pro Plattform im App-Shell-Bereich gekapselt:
  - Android: `ShadowDemoData.kt`
  - iOS: `ShadowDemoData.swift`

### Mobile Repository-Contracts

Android:

- `ChatListRepository.loadChatList(): List<ChatListItemUi>`
- `RoomTimelineRepository.loadTimeline(roomId: String): RoomTimelineSnapshotUi`

iOS:

- `ChatListRepository.loadChatList() async throws -> [ChatListItemViewState]`
- `RoomTimelineRepository.loadTimeline(roomId:) async throws -> RoomTimelineSnapshotViewState`

Die Contracts liefern aktuell Snapshots. Sie kennen noch keine Live-Updates, Pagination, Sync-Token, Session-Identitaet oder Fehlerdetails.

### Rust-Core zum Zeitpunkt des Audits

Der Rust-Workspace ist vorhanden und enthaelt minimale Crates:

- `shadow_core_domain`
- `shadow_core_auth`
- `shadow_core_session`
- `shadow_core_rooms`
- `shadow_core_timeline`

Aktuell sind dies Stubs bzw. fruehe Domain-Ansaetze. `shadow_core_rooms` liefert eine lokale Bootstrap-Liste. `shadow_core_timeline` enthaelt nur erste Message-/Delivery-State-Bausteine. Eine echte Matrix-Runtime, ein Client-Lifecycle, Sync-Loop, Room-List-Service oder Timeline-Subscription existieren noch nicht.

### FFI und Bindings zum Zeitpunkt des Audits

Es gibt noch keine produktive FFI-Schicht fuer Android oder iOS. Das ist fuer den aktuellen Stand korrekt, weil die Core-Contracts und Mapping-Regeln noch nicht stabil genug sind.

## Readiness-Bewertung

### Bereits bereit

- UI und Core sind getrennt.
- Mobile Feature-Module importieren keine rohen Matrix- oder Rust-Typen.
- Demo-Daten sind austauschbar hinter Repository-Contracts.
- Trust-Level sind in der Chat-Liste sichtbar modelliert: `verified`, `standard`, `reduced`.
- Navigation nutzt lokale `roomId`-Strings und keine Matrix-SDK-Objekte.
- Android und iOS haben vergleichbare State-Modelle fuer Loading, Loaded, Empty und Error.

### Noch nicht bereit

- Es gibt keinen app-eigenen, plattformuebergreifend dokumentierten Room-List-Domain-Contract.
- Es gibt keinen app-eigenen Timeline-Domain-Contract mit Matrix-nahen Feldern wie event id, sender id, origin server timestamp, edit/delete/reaction metadata oder pagination tokens.
- Mobile Repository-Contracts sind Snapshot-only und koennen Live-Updates noch nicht ausdruecken.
- Fehlerzustaende sind fuer echte Integration zu grob. Es fehlen getrennte Kategorien fuer offline, auth expired, sync unavailable, rate limited, room inaccessible und bridge/external-source warnings.
- Trust- und Bridge-Semantik ist noch nicht tief genug modelliert, um native Matrix-Raeume, externe Quellen und reduzierte Verifikation eindeutig zu unterscheiden.
- Es gibt keine FFI-Boundary-Regeln fuer Threading, Cancellation, Streaming, Memory Ownership und Error Mapping.
- Es gibt keine Session-Boundary zwischen App-Shell und Core-Runtime.

## Boundary-Regeln fuer die naechsten Slices

1. Mobile UI darf weiterhin nur app-eigene UI- und Domain-nahe Modelle sehen.
2. Matrix-SDK-Typen bleiben hinter dem jeweiligen Plattformadapter verborgen.
3. Demo-Repositories bleiben erhalten, bis echte Services dieselben Contracts erfuellen.
4. Live-Updates duerfen nicht direkt in Composables oder SwiftUI-Views gebunden werden.
5. Repository- oder Service-Contracts muessen Cancellation und Lifecycle der Plattform respektieren.
6. Bridge- oder externe Raumkontexte duerfen niemals als verified/native dargestellt werden.
7. Session-Status muss vor Room List / Timeline klar modelliert sein.

## Empfohlene Integrationsreihenfolge

### Slice 1: Core Domain Contract Alignment

Ziel: App-eigene Room-List- und Timeline-Domain-Modelle in Rust und `core/contracts` dokumentieren.

Umfang:

- `RoomId`, `RoomDisplayName`, `RoomPreview`, `UnreadState`, `TrustLevel`
- `TimelineEventId`, `TimelineItem`, `SenderDisplay`, `DeliveryState`
- Fehler- und Statusmodell als Contract, noch ohne SDK-Anbindung

Nicht enthalten: Matrix-Runtime, Netzwerk, Persistenz, FFI.

### Slice 2: Matrix Runtime Boundary Design

Ziel: Session-, Client- und Sync-Lifecycle des Plattformadapters als Boundary
dokumentieren.

Umfang:

- Runtime ownership
- account/session scoping
- cancellation rules
- offline/auth-expired/sync-unavailable states
- redaction/logging rules

Nicht enthalten: produktive Credentials oder echte Login-Flows.

### Slice 3: Contract- und Conformance-Prototyp

Ziel: gemeinsame Wertmodelle und Fixtures für Android/iOS festlegen, ohne
hohe Eventraten durch eine zusätzliche ShadowChat-FFI zu leiten.

Umfang:

- Snapshot- und Diff-Contracts
- Streaming-, Backpressure- und Cancellation-Regeln
- Error mapping
- gemeinsame Conformance-Fixtures

Nicht enthalten: generierte Mobile-Bindings oder Matrix-SDK-Live-Anbindung.

### Slice 4: Room List Service Adapter

Ziel: erster echter Adapter hinter `ChatListRepository`, sobald Runtime und FFI klar sind.

Umfang:

- Mapping Matrix/SDK-naher Room-List-Konzepte auf app-eigene Modelle
- klare Fallbacks fuer Trust und externe Kontexte
- tests mit Fixtures

Nicht enthalten: Timeline-Live-Subscription.

### Slice 5: Timeline Service Adapter

Ziel: Timeline-Snapshots und spaeter Live-Updates hinter `RoomTimelineRepository` anbinden.

Umfang:

- Event mapping
- pagination readiness
- edit/delete/reaction placeholders als Domain-Contract
- delivery-state mapping

Nicht enthalten: Send Pipeline.

## Aufgelöste Architekturentscheidungen

- ADR-0016 wählt native Plattformadapter mit gemeinsamem Policy-/Contract-Core.
- Es wird keine zusätzliche ShadowChat-FFI für Room-List-/Timeline-Hot-Paths
  eingeführt.
- Room List und Timeline benötigen snapshots plus lifecycle-sichere Streams;
  Backpressure und Cancellation werden vor Android-Live-Integration
  festgelegt.
- Matrix Trust, Device Trust und Bridge Trust bleiben getrennte app-eigene
  Semantiken.
- Credential-freie Contract-Tests werden durch adapterbezogene
  Integrationstests in kontrollierten Testumgebungen ergänzt.

## Validierungsanforderungen fuer spaetere Integrationsslices

- Rust: `cargo fmt --all --check` und `cargo test --workspace`
- Android: `./gradlew.bat assembleDebug`, `./gradlew.bat testDebugUnitTest`, `./gradlew.bat lint`
- iOS: `swift test` fuer SwiftPM und `xcodebuild build` fuer das App Target auf macOS
- Contract-Mapping-Tests fuer Room List und Timeline
- Fixture-basierte Tests ohne echte Matrix-Credentials

## Nicht-Ziele dieses Audits

- keine Matrix-SDK-Integration
- keine Authentifizierung
- keine echte Session-Verwaltung
- keine Room-Subscription
- keine Send-Pipeline
- keine Push Notifications
- keine Bridge-Implementierung
- keine Crypto-Integration
- keine produktive Persistenz
- keine Netzwerkzugriffe

## Ergebnis

Die Trennung von UI, State und Repository-Contracts war tragfähig und ermöglichte
die iOS-Live-Integration. Die Zielgrenze liegt gemäß ADR-0016 zwischen
Feature-Repositories und Plattform-Matrix-Adaptern. Der gemeinsame Rust-Core
liefert pure Policies und Testvektoren, aber keine zweite Matrix-Laufzeit.

Für Android folgen zuerst Session-/Sync-Adapter und danach Live-Room-List und
Timeline. Für beide Plattformen bleiben Streaming, Cancellation, Pagination
und Performance-Baselines eigene P0-/P1-Arbeitspakete.
