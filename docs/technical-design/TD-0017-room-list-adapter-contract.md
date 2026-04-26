# TD-0017 Room List Adapter Contract

## Status

Akzeptiert als Contract-/Boundary-Slice. Dieser Slice fuehrt keine Matrix-SDK-Live-Anbindung, keine FFI-Aufrufe und keine produktive Persistenz ein.

## Ziel

Der Room-List-Adapter-Contract beschreibt, welche app-eigenen Daten spaeter aus Matrix Room List / Sync / Sliding-Sync-Konzepten in ShadowChat einfliessen duerfen.

Der Contract bleibt bewusst Matrix-nah genug fuer spaetere Adapter, aber nicht SDK-gebunden. Mobile UI und ViewModels sehen weiterhin nur stabile App-Modelle.

## 🧩 Architektur

Die Room List wird in drei Schichten gedacht:

```text
Matrix SDK / matrix-sdk-ui Konzepte
  -> Rust Room List Adapter
  -> app-eigene RoomSummary / Mobile Summary Models
  -> ChatListRepository
  -> ChatListViewModel
  -> ChatList UI
```

Heute existieren nur Contract-Modelle und statische Adapter. Spaeter kann ein FFI-backed Repository dieselbe Mobile-Grenze verwenden.

## 🔗 Adapter / FFI-Ausblick

Rust definiert die app-eigene Basis:

- `RoomSummary`
- `RoomDisplayName`
- `RoomLastMessageSummary`
- `RoomUnreadState`
- `RoomMembership`
- `TrustLevel`
- `RoomListAdapter`
- `RoomListService`

Android und iOS ergaenzen feature-nahe Summary-Modelle:

- Android `ChatListRoomSummary`
- Android `ChatListMembership`
- iOS `ChatListRoomSummaryViewState`
- iOS `ChatListMembership`

Diese Modelle sind keine generierten FFI-DTOs. Sie beschreiben nur die mobile Swap-Grenze, damit spaeter FFI-backed Repositories in `ChatListItemUi` bzw. `ChatListItemViewState` mappen koennen.

## 🔄 Mapping / Datenfluss

Spaeteres Mapping:

```text
Matrix Room
  -> room id
  -> display name
  -> latest visible message preview
  -> unread counters / mention marker
  -> membership state
  -> trust / bridge-safe classification
  -> RoomSummary
  -> ChatListRoomSummary / ChatListRoomSummaryViewState
  -> ChatListItemUi / ChatListItemViewState
```

Die UI bleibt absichtlich bei Chat-Listen-Modellen. Felder wie `membership` und `hasUnreadMentions` duerfen fuer zukuenftige Badges, Filter oder Warnungen vorbereitet sein, ohne heute neue Produktlogik zu aktivieren.

## Contract-Felder

- `roomId`: stabile app-eigene Raumkennung. Spaeter aus Matrix Room ID abgeleitet, aber nicht als SDK-Typ exponiert.
- `displayName`: sichtbarer Raum-/Kontaktname.
- `lastMessage`: optionale Vorschau mit Body, Zeitlabel und optionalem Sendernamen.
- `unread`: Zaehler plus Mention-Marker.
- `trustLevel`: `Verified`, `Standard` oder `Reduced`.
- `membership`: `Joined`, `Invited`, `Left`, `Knocked` oder `Banned`.
- `isFavorite`: lokaler/UI-naher Sortierhinweis, noch ohne Persistenz.

## 🚫 Nicht-Ziele

- keine echte Matrix-SDK-Integration
- keine echten Matrix-Rooms
- kein Login
- kein Sync
- keine Netzwerkzugriffe
- keine produktive Persistenz
- keine FFI-Aufrufe aus Android oder iOS
- keine Binding-Generierung
- keine Crypto-/Encryption-Integration
- keine Push Notifications
- keine Bridge-Implementierung
- keine Send-Pipeline
- kein UI-Redesign

## ✅ Akzeptanzkriterien

- Rust/Core enthaelt app-eigene Room-Summary- und Room-List-Adapter-Contracts.
- Bestehende `ChatListItem`-Projektion bleibt fuer vorhandene Call-Sites verfuegbar.
- Android und iOS besitzen kleine Mapping-Modelle fuer spaetere Room-Summary-Daten.
- Mapping-Tests pruefen, dass Summary-Daten in bestehende Chat-Listen-View-States ueberfuehrt werden.
- Keine neuen externen Dependencies werden eingefuehrt.

## 🧪 Validierung

Fuer diesen Slice:

- Rust `cargo fmt --all --check`
- Rust `cargo test --workspace`
- Android `./gradlew.bat assembleDebug`
- Android `./gradlew.bat testDebugUnitTest`
- Android `./gradlew.bat lint`
- iOS `swift test`, falls lokal verfuegbar
- `git diff --check`

## ⚠️ Risiken

- Die Summary-Modelle sind bewusst noch Snapshot-orientiert. Streaming, Cancellation und Pagination bleiben eigene Integrationsslices.
- Membership ist vorbereitet, aber noch nicht in der UI sichtbar. Die spaetere Produktentscheidung muss klaeren, welche Membership-Zustaende in der Chat-Liste angezeigt werden.
- Trust-Level bleibt grob. Device Trust, Room Trust und Bridge Trust muessen in einem spaeteren Security-/Bridge-Slice genauer getrennt werden.
