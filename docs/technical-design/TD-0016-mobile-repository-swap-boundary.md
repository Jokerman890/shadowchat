# TD-0016 Mobile Repository Swap Boundary

## Status

Akzeptiert und durch ADR-0016 präzisiert. Die Provider-Grenze tauscht
Demo-/InMemory-Repositories gegen Plattformadapter-backed Repositories aus.
Eine zusätzliche ShadowChat-FFI ist dafür nicht erforderlich.

## Ziel

Android und iOS sollen Demo-Repositories gegen produktive Session-, Room-List-
und Timeline-Repositories tauschen können, ohne Feature-Views oder ViewModels
neu zu bauen.

## 🧩 Architektur

Die bestehenden Feature-Contracts bleiben stabil:

- Android `ChatListRepository`
- Android `RoomTimelineRepository`
- iOS `ChatListRepository`
- iOS `RoomTimelineRepository`

Neu ist nur eine App-Shell-nahe Provider-Grenze:

- Android `ShadowRepositoryProvider`
- iOS `ShadowRepositoryProvider`

Die Provider liefern je nach App-Komposition Demo-Repositories oder
Repositories über dem nativen Plattform-Matrix-Adapter.

## Swap Boundary

Die Swap Boundary sitzt bewusst in der App-Shell:

- Feature-Module kennen keine App-Shell-Demo-Daten.
- Feature-Module kennen weder Matrix-SDK- noch optionale Core-FFI-DTOs.
- ViewModels erhalten weiterhin nur ihre bisherigen Repository-Interfaces.
- Die App-Shell entscheidet, welcher Provider verwendet wird.

Dadurch bleibt die Live-Integration eine Adapter-Frage und kein UI-Refactor.

## 🔄 Datenfluss

Aktueller Datenfluss:

```text
App Shell
  -> DemoShadowRepositoryProvider
  -> DemoChatListRepository / DemoRoomTimelineRepository
  -> Feature ViewModel
  -> Feature View
```

Produktiver Zieldatenfluss:

```text
App Shell
  -> PlatformShadowRepositoryProvider
  -> ChatListRepository / RoomTimelineRepository
  -> Plattform-Matrix-Adapter
  -> Matrix-SDK
  -> Feature ViewModel
  -> Feature View
```

Diese Variante ist auf iOS mit `MatrixRepositoryProvider` und
`MatrixRustClientService` implementiert. Android verwendet weiterhin den
Demo-Provider.

Optionale pure Core-Policy:

```text
Plattform-Repository
  -> grobgranulare Shadow-Core-Policy
  -> wertbasiertes Ergebnis
```

Room-List-/Timeline-Streams und SDK-Handles laufen nicht durch diese optionale
Core-Grenze.

## 🚫 Nicht-Ziele

- keine echte Matrix-SDK-Integration
- keine neuen Core-FFI-Aufrufe aus Android oder iOS
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
- Feature-Views und ViewModels müssen nicht wissen, ob Daten aus Demo- oder
  Plattformadapter-Repositories kommen.
- Android und iOS verwenden dasselbe Boundary-Muster.
- Produktive Adapter bleiben durch app-eigene Contracts austauschbar.
- Es gibt keine generierten Shadow-Core-Bindings im Event-Hot-Path.

## 🧪 Validierung

Fuer diesen Slice:

- Android `./gradlew.bat assembleDebug`
- Android `./gradlew.bat testDebugUnitTest`
- Android `./gradlew.bat lint`
- iOS `swift test`, falls lokal verfuegbar
- Rust `cargo test --workspace`
- `git diff --check`

## Risiken

- Die iOS-Provider-Grenze liegt noch im App-Target; bei weiterer Aufteilung
  sollen SDK-nahe Implementierungen in dedizierten Service-Komponenten bleiben.
- Android benötigt einen eigenen Plattformadapter und eine produktive
  Dependency-Injection-Komposition.
- Fehler- und Session-State-Mapping ist noch nicht an Mobile-UI-States angeschlossen.
- Live-Updates, Cancellation und Streaming bleiben eigene Slices.
