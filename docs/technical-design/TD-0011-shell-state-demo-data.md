# TD-0011 Shell State und Demo-Daten

## Status

Akzeptiert fuer die aktuellen Mobile-UI-Shell-Slices.

## Kontext

Die mobile App-Shell hostet lokale UI-Slices fuer Chat-Liste, Room Timeline, Calls, Updates, Profile und Settings. Diese Shell braucht bis zur Matrix-Integration konsistente Demo-Daten, darf aber keine echte Matrix-, Auth-, Send-, Push-, Bridge-, Persistenz- oder Netzwerklogik vortaeuschen.

Vor diesem Slice lagen Runtime-Demo-Daten teilweise direkt in den Shell-Views. Dadurch waren Chat-Liste, Timeline und reine Shell-Tabs schwerer voneinander zu unterscheiden, obwohl sie alle nur lokale InMemory-Daten nutzen.

## Entscheidung

Runtime-Demo-Daten werden pro Plattform im App-Shell-Bereich gekapselt:

- Android: `apps/android/app/src/main/java/com/shadowchat/app/ShadowDemoData.kt`
- iOS: `apps/ios/Packages/Sources/ShadowChatAppShell/ShadowDemoData.swift`

Die Feature-Module behalten ihre bestehenden Contracts:

- `ChatListRepository`
- `RoomTimelineRepository`
- Chat-/Timeline-State-Modelle
- lokale ViewModels

Die App-Shell stellt nur InMemory-Repositories bereit, die diese Contracts erfuellen. Feature-Module kennen weiterhin keine App-Shell-spezifischen Demo-Quellen und keine Matrix-Implementierungsdetails.

## Demo-Room-IDs

Die Runtime-Demo-Daten verwenden stabile Room-IDs, die auf Android und iOS gleich benannt sind:

- `sofia`
- `design-squad`
- `jason`
- `family`
- `emma`
- `adventure`
- `noah`
- `daniel`

Die Chat-Liste und Timeline-Shells muessen fuer diese IDs konsistent bleiben. Wenn ein Demo-Raum ausgewaehlt wird, liefert die Timeline ein passendes lokales Snapshot-Modell fuer denselben `roomId`.

## Preview- und Test-Daten

Preview- und Test-Daten bleiben bewusst von Runtime-Demo-Daten getrennt:

- Feature-Tests nutzen eigene Stub-Repositories.
- SwiftUI- und Compose-Previews duerfen weiterhin eigene Preview-Fixtures verwenden.
- Runtime-InMemory-Daten liegen in der App-Shell, nicht in Feature-Tests oder Feature-Preview-Dateien.

Diese Trennung verhindert, dass spaetere Matrix-Integration versehentlich an Preview-Fixtures oder Test-Stubs gekoppelt wird.

## Nicht-Ziele

Dieser Slice fuehrt nicht ein:

- Matrix-SDK-Integration
- Authentifizierung
- echte Send-Pipeline
- Push Notifications
- Bridge-Implementierung
- Persistenz
- Netzwerkzugriffe
- echte Calls-, Payment- oder Settings-Operationen

## Spaetere Ablösung

Sobald Matrix-Session- und Room-List-Services bereitstehen, kann die App-Shell andere Implementierungen hinter denselben Repository-Contracts injizieren. Die aktuellen `Demo*Repository`-Implementierungen sind bewusst lokal, klein und austauschbar.

## Risiken

- Demo-Daten enthalten weiterhin produktnah wirkende Texte. Sie muessen bis zur echten Matrix-Anbindung klar als lokale Shell-Daten behandelt werden.
- Calls, Updates, Profile und Settings bleiben reine Shells. Echte Produktoperationen benoetigen eigene Feature-Slices und eigene Contracts.
