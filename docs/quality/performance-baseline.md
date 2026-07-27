# Performance-Baseline

Status: vorläufige Zielbudgets und reproduzierbares Messprotokoll. Die Werte
sind noch keine gemessene Produkt-Baseline und werden deshalb nicht als
CI-Grenzwerte verwendet.

## Zweck

ShadowChat ist motion-first. Animationen, Übergänge und Materialien dürfen
Navigation, Scrollen, Texteingabe, Energieverbrauch und Accessibility trotzdem
nicht merklich verschlechtern. Dieses Dokument trennt Zielbudgets,
Messbedingungen und echte Messergebnisse.

## Vorläufige Budgets

Alle Latenzbudgets werden als Median (`p50`) und langsamer Rand (`p95`)
aus mindestens 10 Wiederholungen berichtet. Netzwerkabhängige Live-Messungen
werden getrennt von deterministischen lokalen Fixtures ausgewiesen.

| Vorgang | Vorläufiges Budget | Messpunkt |
| --- | --- | --- |
| Cold Start bis interaktive Root-UI | p50 ≤ 1,2 s; p95 ≤ 1,8 s | `XCTApplicationLaunchMetric` und Instruments App Launch |
| Warm Start bis interaktive Root-UI | p50 ≤ 0,4 s; p95 ≤ 0,7 s | XCTest/Time Profiler, App-Prozess bleibt erhalten |
| Session Restore | p50 ≤ 0,8 s; p95 ≤ 1,5 s | `SessionRestore` |
| Erste nutzbare Raumliste | p50 ≤ 1,2 s; p95 ≤ 2,0 s | `RoomListLoad`, Fixture separat von Live-Netzwerk |
| Raum öffnen bis interaktive Oberfläche | p95 ≤ 0,3 s | Navigation, Core Animation und SwiftUI-Instrument |
| Erste Timeline-Seite | p50 ≤ 0,7 s; p95 ≤ 1,2 s | `TimelineLoad`, Fixture separat von Live-Netzwerk |
| Senden bis lokaler Status sichtbar | p50 ≤ 0,15 s; p95 ≤ 0,25 s | `MessageSend`; lokale UI-Bestätigung separat vom Server-Ack |
| Scrollen in Raumliste und Timeline | Hitch-Time-Ratio ≤ 1 %; kein einzelner Hitch > 100 ms im Referenzlauf | Core Animation Hitches und MetricKit |
| Speicher nach 20 geöffneten Räumen | stabil ≤ 250 MB und Anstieg ≤ 100 MB gegenüber Raumlisten-Baseline | Allocations/Memory Graph nach gleicher Navigationsfolge |

Die Budgets werden nach der ersten stabilen Geräte-Baseline überprüft. Eine
Änderung braucht ein versioniertes Ergebnis und eine begründete
Architekturentscheidung; sie darf nicht nur einen fehlerhaften Lauf passend
machen.

## iOS-Signposts

Das App-Target verwendet das Subsystem `de.shadowchat.ios`. Signposts enthalten
keine Room-IDs, User-IDs, Tokens, Nachrichteninhalte oder sonstige
personenbezogene Daten.

| Kategorie | Name | Grenze |
| --- | --- | --- |
| `Performance.Session` | `SessionRestore` | Keychain-Lookup, Client-Aufbau und SDK-Session-Restore |
| `Performance.Session` | `SyncStart` | Aufbau beziehungsweise Start des SDK-Sync-Service |
| `Performance.Repository` | `RoomListLoad` | Repository-Aufruf bis gemappte Raumliste |
| `Performance.Repository` | `TimelineLoad` | Repository-Aufruf bis erster gemappter Timeline-Snapshot |
| `Performance.Repository` | `MessageSend` | Repository-Aufruf bis Rückkehr des lokalen Sendepfads |

Jedes Intervall wird mit demselben Signposter und Namen beendet, auch wenn der
Aufruf einen Fehler wirft. `MessageSend` ist vorläufig die Service-Grenze; ein
expliziter lokaler Echo-Status wird in P0-05 separat messbar gemacht.

## Referenzläufe

Runtime-Messungen erfolgen mit einem Release-Build auf physischen Geräten.
Simulator- und Debug-Läufe dienen nur der Korrektheit und werden nicht als
App-Laufzeit-Baseline veröffentlicht.

Pro Ergebnis werden mindestens zwei Profile geführt:

1. ältestes noch unterstütztes physisches iPhone auf der iOS-18-Kompatibilitätslinie
2. modernes 120-Hz-iPhone auf dem aktuellen iOS-27-Zielruntime

Im Ergebnis müssen konkretes Gerätemodell, OS-Build, Xcode-Version, Commit,
Build-Konfiguration, Energiezustand, Thermal State, Netzwerkprofil,
Reduce-Motion-/Reduce-Transparency-Zustand und Fixture-Größe stehen. Falls das
iOS-27-Runtimeprofil noch nicht verfügbar ist, wird es als `nicht gemessen`
ausgewiesen und nicht durch Simulatorwerte ersetzt.

## Reproduzierbarer iOS-Ablauf

1. Auf macOS `cd apps/ios && xcodegen generate` ausführen.
2. Die App im Release-Schema mit passendem dSYM auf dem Referenzgerät
   installieren.
3. In Instruments `Points of Interest`, `SwiftUI`, `Time Profiler`,
   `Core Animation Hitches`, `Allocations` und bei Bedarf `Energy Log`
   passend zum untersuchten Flow wählen.
4. Für Startmessungen pro Variante mindestens 10 Läufe erfassen. Cold Start
   beendet den Prozess vollständig; Warm Start erhält den Prozess.
5. Für Repository-Latenzen nach Subsystem, Kategorie und Signpost-Name filtern.
6. Raumliste und Timeline jeweils 30 Sekunden mit derselben automatisierten
   Scrollfolge prüfen; normalen Motion-Modus und Reduce Motion getrennt
   protokollieren.
7. Für Speicher die Raumlisten-Baseline erfassen, 20 Räume mit derselben
   Reihenfolge öffnen und schließen, danach zwei Minuten im Leerlauf warten.
8. Trace, Kennzahlen und Beobachtungen unter
   `docs/quality/performance-results/` versionieren. Große `.trace`-Pakete
   verbleiben außerhalb von Git; im Ergebnis steht deren kontrollierter
   Ablageort und SHA-256.

Für fokussierte SwiftUI-Hotspots kann auf macOS zusätzlich ETTrace verwendet
werden. Der Capture muss kurz, symboliziert und exakt auf einen Flow begrenzt
sein. Ohne passende dSYMs gilt er nicht als belastbare Baseline.

## XCTest-Zuordnung

Die noch anzulegenden Performancefälle verwenden:

- `XCTApplicationLaunchMetric` für Cold Start
- `XCTOSSignpostMetric` für die fünf benannten Signpost-Intervalle
- `XCTHitchMetric` für reproduzierbare Scrollfolgen
- `XCTMemoryMetric` für die definierte 20-Räume-Sequenz
- `XCTClockMetric` nur für isolierte Mapping- und Diff-Fixtures

Die Tests werden erst zu CI-Gates, wenn die Fixtures 100, 1.000 und 10.000
Elemente reproduzierbar erzeugen und mehrere Geräte-Baselines stabil sind.

## Bekannte Hotspots

Der aktuelle Code zeigt vor der ersten Messung bereits drei zu bestätigende
Risiken:

- `loadChatList()` fragt Raum-Metadaten seriell ab.
- Timeline-Snapshots und Diffs werden an mehreren Grenzen vollständig gemappt.
- Timeline-Kontexte können bis `stopSync()` oder Logout im Actor verbleiben.

Diese Punkte werden nicht allein aufgrund der Codeanalyse als gemessene
Regression bezeichnet. P0-04 und P0-05 optimieren sie erst nach reproduzierbaren
Messungen.
