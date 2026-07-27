# ADR-0016 Hybride Matrix-Laufzeit mit nativen Plattformadaptern

## Status

Akzeptiert am 27.07.2026.

Diese Entscheidung präzisiert ADR-0002 und ersetzt die zuvor offene Annahme,
dass Session, Sync, Room List, Timeline, Crypto und Persistenz zwingend in einer
zusätzlichen ShadowChat-Rust-Laufzeit hinter eigener FFI liegen müssen.

## Kontext

ShadowChat besitzt derzeit drei unterschiedliche Reifegrade:

- iOS verwendet produktiv `MatrixRustSDK` hinter dem actor-isolierten
  `MatrixRustClientService`.
- Android verwendet Demo-Repositories und besitzt noch keine Matrix-Laufzeit.
- `shadow_core_runtime` ist ein synchroner No-op-Vertragsprototyp ohne
  Matrix-SDK, Netzwerk, Streaming, Crypto oder Persistenz.

Der tatsächliche iOS-Datenfluss ist:

```text
SwiftUI
  -> ShadowAppState / Feature ViewModel
  -> app-eigenes Service- oder Repository-Protokoll
  -> MatrixRustClientService / MatrixRepositoryProvider
  -> MatrixRustSDK
  -> Matrix-Client, Sync, Crypto und SQLite-Stores
```

SDK-Listener wechseln mit `Sendable`-Werten zurück in den Service-Actor.
SwiftUI und die Feature-Pakete importieren kein `MatrixRustSDK`.

Der Android-Datenfluss endet derzeit bei lokalen Daten:

```text
Compose
  -> ViewModel
  -> ChatListRepository / RoomTimelineRepository
  -> DemoShadowRepositoryProvider
  -> lokale Demo-Daten
```

Der Rust-Prototyp ist nicht mit einer Mobile-App verbunden:

```text
NoopMatrixSessionRuntime
  -> synchrone Commands und Snapshots
  -> Ffi*-DTO-Prototypen
  -> keine generierten Bindings
```

## Entscheidungsoptionen

Bewertung: 1 ist ungünstig, 5 ist günstig. Die Zahlen sind eine
Architekturheuristik und keine Laufzeitmessung.

| Kriterium | A: vollständig plattformspezifisch | B: gesamte Laufzeit im Shadow-Rust-Core | C: hybrid |
| --- | ---: | ---: | ---: |
| Android-/iOS-Parität | 2 | 5 | 4 |
| FFI-Kosten im heißen Pfad | 5 | 2 | 5 |
| Streaming und Backpressure | 4 | 2 | 5 |
| Cancellation und Lifecycle | 4 | 2 | 5 |
| SDK-Upgrade-Aufwand | 2 | 3 | 4 |
| Debugbarkeit | 4 | 2 | 4 |
| Testbarkeit | 3 | 4 | 5 |
| Crypto-/Storage-Verantwortung | 4 | 3 | 5 |
| Migrationsrisiko | 3 | 1 | 5 |

### Option A: vollständig plattformspezifische Laufzeiten

Jede Plattform besitzt Matrix-Laufzeit, Mapping und sämtliche Produktregeln.

Vorteile:

- keine zusätzliche ShadowChat-FFI
- natürliche Swift-Concurrency- und Kotlin-Coroutine-Lifecycles
- SDK-nahe Fehler sind lokal gut debuggbar

Nachteile:

- Trust-, Sortier-, Capability- und Fehlerregeln können auseinanderlaufen
- doppelte Produktlogik und doppelte Contract-Tests
- Android-/iOS-Parität hängt überwiegend von manueller Abstimmung ab

### Option B: gesamte Matrix-Laufzeit im gemeinsamen Rust-Core

ShadowChat würde Matrix-Client, Session, Sync, Room List, Timeline, Crypto und
Persistenz selbst in Rust hosten und über eigene Mobile-Bindings exportieren.

Vorteile:

- maximal gemeinsame Laufzeitlogik
- einheitliche Matrix- und Crypto-Implementierung
- gemeinsame Rust-Integrationstests

Nachteile:

- die bestehende iOS-Integration müsste trotz funktionierendem
  `MatrixRustSDK` neu aufgebaut werden
- Timeline- und Room-List-Diffs müssten zusätzlich über eine eigene FFI
  kopiert, versioniert und verwaltet werden
- Listener, Backpressure, Cancellation, Memory Ownership und Fehlertransport
  würden zu einer zweiten Binding-Schicht neben den SDK-Bindings
- Apple-Keychain, OAuth-Präsentation, APNs, NSE und Android-Lifecycle bleiben
  trotzdem plattformspezifisch
- der aktuelle Rust-Prototyp deckt keinen produktiven Teil dieser Laufzeit ab

### Option C: hybride Architektur

Jede Plattform besitzt einen nativen Matrix-Adapter hinter stabilen
ShadowChat-Protokollen. Der gemeinsame Rust-Core enthält nur plattformneutrale,
deterministische Produktlogik und wertbasierte Contracts.

Vorteile:

- keine zusätzliche ShadowChat-FFI im Room-List-/Timeline-Hot-Path
- Plattform-Lifecycle und Cancellation bleiben nativ
- bestehende iOS-Laufzeit bleibt migrationsfähig
- gemeinsame Regeln und Testvektoren verhindern semantische Drift
- Matrix-SDK-Upgrades bleiben auf den jeweiligen Adapter begrenzt

Nachteile:

- SDK-Mapping wird pro Plattform implementiert
- Contract-Parität benötigt verpflichtende Fixtures und Conformance-Tests
- der gemeinsame Rust-Core darf nicht erneut schleichend zur zweiten
  Matrix-Laufzeit werden

## Entscheidung

ShadowChat verwendet Option C.

Die operative Matrix-Laufzeit ist plattformspezifisch und liegt ausschließlich
im jeweiligen Matrix-Adapter. Der gemeinsame Rust-Core bleibt verbindlicher
Ort für plattformneutrale Produktregeln, stabile Wertmodelle und gemeinsame
Testvektoren.

Die Bezeichnung „nativer Plattformadapter“ beschreibt die App-Grenze. Der
Adapter darf intern ein Rust-basiertes SDK mit offiziellen Swift- oder
Kotlin-Bindings verwenden. Entscheidend ist, dass ShadowChat keine zweite FFI
für hochfrequente Matrix-Ereignisse darüberlegt.

## Verbindliche Verantwortlichkeiten

| Bereich | Allein verantwortliche Laufzeitschicht | Gemeinsamer Core |
| --- | --- | --- |
| Session und Client-Lifecycle | Plattform-Matrix-Adapter pro Account | Zustandsbegriffe, Fehlerklassen und Übergangsregeln |
| Sync | Plattform-Matrix-Adapter | keine Netzwerk- oder Loop-Verantwortung |
| Room List | Plattform-Repository über dem Matrix-Adapter | reine Sortier-, Filter- und Trust-Policy |
| Timeline und Pagination | Plattform-Repository über dem Matrix-Adapter | wertbasierte Event-/Delivery-Regeln und Testvektoren |
| Senden | Plattform-Matrix-Adapter | Validierungs- und Statussemantik ohne SDK-Handle |
| Crypto, SAS, Recovery, Key Backup | Plattform-Matrix-Adapter und dessen SDK | nur sichtbare Trust-/Security-Semantik |
| Matrix-Persistenz | SDK-Store unter Besitz des Plattformadapters | keine Tokens, Store-Keys oder SDK-Datenbanken |
| Secret Storage | Keychain beziehungsweise Android Keystore hinter dem Plattformadapter | keine Secrets |
| Push-Registrierung und Notification Extension | Plattformservice | nur payload-neutrale Routingregeln, falls gemeinsam nutzbar |
| Bridges | dedizierter Plattform-/Service-Adapter hinter ShadowChat-Contracts | gemeinsame Trust- und Capability-Policy |

Es darf pro Account genau einen aktiven Matrix-Client, einen Sync-Owner und
einen Crypto-/Store-Owner geben.

## Contract- und FFI-Regeln

1. SwiftUI und Compose sehen ausschließlich ShadowChat-Wertmodelle.
2. SDK-Typen, Client-Handles, Tokens und Store-Passphrases überschreiten keine
   Feature-Grenze.
3. Room List und Timeline werden direkt im Plattformadapter auf app-eigene
   Werte gemappt.
4. Eine zukünftige ShadowChat-FFI ist nur für grobgranulare, pure
   Core-Funktionen zulässig, beispielsweise Trust-Klassifikation oder
   deterministische Sortierschlüssel.
5. Hochfrequente Timeline-Diffs, Room-List-Diffs, Crypto-Listener und
   SDK-Handles gehen nicht durch die ShadowChat-Core-FFI.
6. `FfiSession*` bleibt vorerst ein nicht angebundener Contract-Prototyp. Er ist
   keine Ziel-Runtime und darf nicht als Mobile-Integrationspfad beworben
   werden.
7. Contract-Versionen und Fixtures müssen auf beiden Plattformen denselben
   erwarteten Output erzeugen.

## Streaming, Backpressure und Cancellation

- Jeder Stream ist an Account, Session und Consumer-Lifecycle gebunden.
- Plattform-Repositories liefern snapshots plus begrenzte, wertbasierte
  Änderungen.
- Bei langsamen Consumern dürfen ersetzbare Zwischenstände zusammengeführt
  werden; Security- und Sendestatus-Ereignisse dürfen nicht still verloren
  gehen.
- Raumwechsel, Logout und Accountwechsel beenden zugehörige Tasks, Listener und
  Timeline-Kontexte deterministisch.
- Kein Stream darf einen View-, Activity-, Scene- oder ViewModel-Lifecycle
  unkontrolliert überleben.
- Queue-Limits, Coalescing und Initial-Snapshot-Verhalten werden vor der
  Live-Android-Integration als Contract festgelegt.

## Performance-Folgen

Die Entscheidung vermeidet eine zusätzliche Serialisierungs- und
Speicherkopie für jedes Room-List- oder Timeline-Ereignis. Das reduziert
Architekturrisiko, ist aber noch kein gemessener Performancegewinn.

Verbindliche Messpunkte:

- SDK-Callback bis Repository-Emission
- Repository-Emission bis sichtbarer UI-State
- Anzahl und Größe gemappter beziehungsweise kopierter Items
- Queue-Tiefe und zusammengeführte Updates
- aktive Timeline-Kontexte und Listener
- Speicher nach wiederholtem Raumwechsel
- Main-Thread-/Main-Actor-Zeit pro Update

Die aktuellen iOS-Pfade mit seriellen `roomInfo()`-Aufrufen, vollständigem
Timeline-Mapping, Polling auf das erste Update und unbegrenzten
Timeline-Kontexten gelten ausdrücklich nicht als Zielzustand. Sie werden in
P0-04 und P0-05 optimiert.

## Migrationspfad iOS

1. `MatrixRustClientService` bleibt produktiver Adapter.
2. Session/Sync, Room List, Timeline, Security und Storage werden schrittweise
   in kleinere adapterinterne Komponenten getrennt.
3. Repository-Contracts erhalten lifecycle-sichere Streams und Pagination.
4. Listener und Timeline-Kontexte erhalten explizite Cancellation und
   Eviction.
5. Gemeinsame Policy-Fixtures werden gegen Swift-Mappingtests ausgeführt.
6. Erst nach Messung wird entschieden, welche grobgranulare Policy tatsächlich
   als Rust-Binding eingebunden wird.

## Migrationspfad Android

1. Bestehende Feature-Repositories und ViewModels bleiben stabil.
2. Ein Android-`ShadowClientService` und ein dedizierter Matrix-Adapter werden
   hinter dem Repository-Provider eingeführt.
3. Die konkrete Android-SDK-/Binding-Wahl wird in einem begrenzten Spike gegen
   Session, Sliding Sync, Timeline, Crypto, Lifecycle und Buildgröße geprüft.
4. Session und Sync werden vor Room List und Timeline integriert.
5. Live-Repositories ersetzen den Demo-Provider über Dependency Injection.
6. Kotlin-Conformance-Tests verwenden dieselben Contract-Fixtures wie iOS und
   der Rust-Core.

## Auswirkungen auf den Rust-Core

- ADR-0002 bleibt gültig, aber der gemeinsame Core ist kein zweiter
  Matrix-Client.
- `shadow_core_runtime` wird bis zu einem eigenen Migrationsslice als
  historischer Contract-Prototyp beibehalten.
- Vor produktiver Nutzung wird das Crate inhaltlich auf pure Session-Policy
  reduziert oder in ein eindeutiger benanntes Contract-/Policy-Crate
  überführt.
- Es werden vorerst keine Mobile-Bindings für `FfiSession*` generiert.
- Neue Rust-Module dürfen keine Matrix-Netzwerk-, Crypto- oder
  Store-Verantwortung übernehmen, ohne diese ADR bewusst zu ersetzen.

## Konsequenzen

- Der bestehende iOS-Produktstand muss nicht neu geschrieben werden.
- Android kann unabhängig, aber contract-konform integriert werden.
- Plattformadapter tragen operative Matrix- und Security-Verantwortung.
- Plattformübergreifende Gleichheit wird durch Contracts, Fixtures,
  Conformance-Tests und Produkt-Policies erreicht, nicht durch einen
  erzwungenen gemeinsamen Event-Hot-Path.
- P0-04 und P0-05 dürfen iOS-Performanceprobleme lokal lösen, ohne auf eine
  FFI-Migration zu warten.
- Eine spätere Neubewertung ist nur mit Messdaten, einem funktionsfähigen
  Binding-Prototyp und einer dokumentierten Migrationskostenanalyse zulässig.
