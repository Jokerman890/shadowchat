# TD-0016 Mobile Repository Swap Boundary

## Status

Akzeptiert als Mobile-Boundary-Slice. Dieser Slice bereitet den Austausch von Demo-/InMemory-Repositories gegen spaetere FFI-backed Repositories vor.

## Ziel

Android und iOS sollen ihre aktuellen Demo-Repositories spaeter gegen FFI-backed Session-, RoomList- und Timeline-Daten tauschen koennen, ohne Feature-Views oder ViewModels neu zu bauen.

## 🧩 Architektur

Die bestehenden Feature-Contracts bleiben stabil:

- Android `ChatListRepository`
- Android `RoomTimelineRepository`
- iOS `ChatListRepository`
- iOS `RoomTimelineRepository`

Neu ist nur eine App-Shell-nahe Provider-Grenze:

- Android `ShadowRepositoryProvider`
- iOS `ShadowRepositoryProvider`

Die Provider liefern heute Demo-Repositories. Spaeter kann eine FFI-backed Implementierung dieselben Feature-Repositories bereitstellen.

## 🔗 Swap Boundary / FFI-Ausblick

Die Swap Boundary sitzt bewusst in der App-Shell:

- Feature-Module kennen keine App-Shell-Demo-Daten.
- Feature-Module kennen keine FFI-DTOs.
- ViewModels erhalten weiterhin nur ihre bisherigen Repository-Interfaces.
- Die App-Shell entscheidet, welcher Provider verwendet wird.

Dadurch bleibt die spaetere FFI-Integration eine Adapter-Frage und kein UI-Refactor.

## 🔄 Datenfluss

Aktueller Datenfluss:

```text
App Shell
  -> DemoShadowRepositoryProvider
  -> DemoChatListRepository / DemoRoomTimelineRepository
  -> Feature ViewModel
  -> Feature View
```

Spaeterer Datenfluss:

```text
App Shell
  -> FfiShadowRepositoryProvider
  -> FFI-backed ChatListRepository / RoomTimelineRepository
  -> Feature ViewModel
  -> Feature View
```

Die zweite Variante ist noch nicht implementiert.

## 🚫 Nicht-Ziele

- keine echte Matrix-SDK-Integration
- keine echten FFI-Aufrufe aus Android oder iOS
- keine Binding-Generierung
- kein echter Login
- kein echter Sync
- keine Netzwerkzugriffe
- keine produktive Persistenz
- keine echten Matrix-Credentials
- keine Push Notifications
- keine Bridge-Implementierung
- keine Send-Pipeline
- kein UI-Redesign

## ✅ Akzeptanzkriterien

- Demo-Repositories werden ueber einen Provider in die App-Shell injiziert.
- Feature-Repositories bleiben unveraendert.
- Feature-Views und ViewModels muessen nicht wissen, ob Daten aus Demo oder spaeter aus FFI kommen.
- Android und iOS verwenden dasselbe Boundary-Muster.
- Es gibt keine neuen Dependencies und keine generierten Bindings.

## 🧪 Validierung

Fuer diesen Slice:

- Android `./gradlew.bat assembleDebug`
- Android `./gradlew.bat testDebugUnitTest`
- Android `./gradlew.bat lint`
- iOS `swift test`, falls lokal verfuegbar
- Rust `cargo test --workspace`
- `git diff --check`

## ⚠️ Risiken

- Die Provider-Grenze ist noch App-Shell-internal. Sobald echte FFI-backed Repositories entstehen, muss entschieden werden, ob sie im App-Modul, einem App-Service-Modul oder einem dedizierten Platform-Bridge-Modul liegen.
- Fehler- und Session-State-Mapping ist noch nicht an Mobile-UI-States angeschlossen.
- Live-Updates, Cancellation und Streaming bleiben eigene Slices.
