# ShadowChat Projekt-TODO

Stand: 27.07.2026

Dieses Dokument ist der zentrale, versionierbare Arbeitsplan für ShadowChat. Es
verbindet Architektur, Performance, Qualität, Sicherheit und Release-Reife.

## Status und Priorität

- `[ ]` offen
- `[~]` in Arbeit
- `[x]` abgeschlossen und verifiziert
- `P0` blockiert belastbare Weiterentwicklung oder Release-Reife
- `P1` notwendig für ein produktionsnahes MVP
- `P2` Ausbau nach stabiler MVP-Basis

Eine Aufgabe gilt erst als abgeschlossen, wenn Implementierung, Tests,
Dokumentation und die angegebenen Nachweise vollständig sind.

## Verifizierte Ausgangslage

- [x] Repository `Jokerman890/shadowchat` ist lokal eingerichtet.
- [x] Lokaler Tracking-Branch ist `codex/shadowchat-ios-product-shell`.
- [x] Ausgangscommit ist `084374d30e60cb0751c0c2c099ac745aa9f54677`.
- [x] Rust-Formatprüfung und Rust-Workspace-Tests laufen unter Windows durch.
- [x] Android-Unit-Tests laufen unter Windows durch.
- [x] Repository-weite und plattformspezifische `AGENTS.md`-Regeln sind vorhanden.
- [x] Visuelles und interaktives Designziel für iOS ist iOS 27.
- [x] Reichhaltige, flüssige Motion und unterschiedliche kontextabhängige Übergänge sind verbindliche Produktanforderungen.
- [ ] iOS-Pakettests und iOS-Simulator-Build auf macOS aktuell erneut verifizieren.
- [ ] Reale Laufzeitwerte für Startzeit, Raumliste, Timeline, Speicher und UI-Jank erheben.

## P0 - Architektur und Performance stabilisieren

### P0-01 Branch- und Integrationsstrategie festlegen

Ziel: Einen eindeutigen, prüfbaren Weg vom iOS-Produktbranch nach `main`
festlegen.

- [x] Diff `main...codex/shadowchat-ios-product-shell` fachlich prüfen.
- [x] Prüfen, ob ein offener Pull Request für den Produktbranch existiert.
- [ ] iOS-CI, Rust-CI und Android-CI für den exakten Head-Commit ausführen.
- [x] Offene Review-Kommentare und fehlgeschlagene Checks abarbeiten.
- [x] Unabhängige Slice-Branches einzeln bewerten:
  - `slice/room-list-adapter-contract`
  - `slice/checkly-browser-smoke-check`
  - `slice/liquid-glass-ui-redesign`
- [x] Den veralteten Liquid-Glass-Branch nicht ungeprüft zusammenführen.
- [x] Merge-Reihenfolge und Konfliktstrategie dokumentieren.

Nachweis:

- `docs/quality/branch-integration-plan-2026-07-27.md`
- Pull Request `#19` verbindet den Produktbranch als Draft mit `main`.
- Die CI-Aufgabe bleibt bis zur erfolgreichen Prüfung des neu veröffentlichten
  exakten Head-Commits offen.

Akzeptanz:

- Produktbranch ist über einen nachvollziehbaren PR mit `main` verbunden.
- Alle erforderlichen Checks sind grün.
- Nicht übernommene Branches haben eine dokumentierte Entscheidung:
  übernehmen, neu aufsetzen oder schließen.

### P0-02 Matrix-Core-Entscheidung als ADR festhalten

Ziel: Die derzeitige Abweichung zwischen gemeinsamem Rust-Core und direktem
iOS-MatrixRustSDK-Adapter bewusst entscheiden.

- [ ] Ist-Datenfluss dokumentieren:
  `SwiftUI -> Repository -> MatrixRustClientService -> MatrixRustSDK`.
- [ ] Zieloption A bewerten: Matrix-Laufzeit dauerhaft plattformspezifisch.
- [ ] Zieloption B bewerten: Matrix-Laufzeit im gemeinsamen Rust-Core mit FFI.
- [ ] Zieloption C bewerten: hybrider Core mit nativen Plattform-Adaptern.
- [ ] Kriterien vergleichen:
  - Android-/iOS-Parität
  - FFI-Kopierkosten
  - Streaming und Backpressure
  - Cancellation und Lifecycle
  - SDK-Upgrade-Aufwand
  - Debugbarkeit
  - Testbarkeit
  - Crypto- und Storage-Verantwortung
- [ ] Gewählte Option als neue ADR dokumentieren.
- [ ] TD-0001, TD-0012, TD-0016 und TD-0018 an die Entscheidung anpassen.

Akzeptanz:

- Für Session, Sync, Room List, Timeline, Crypto und Persistenz ist jeweils
  genau eine verantwortliche Schicht benannt.
- Android und iOS haben einen realistischen Migrationspfad.
- Es gibt keine widersprüchlichen Architekturtexte mehr.

### P0-03 Performance-Baseline und Messinfrastruktur

Ziel: Performance nicht mehr nur aus Code abzuleiten, sondern reproduzierbar
zu messen.

- [ ] Messbudgets für folgende Vorgänge festlegen:
  - Cold Start und Warm Start
  - Session Restore
  - erste sichtbare Raumliste
  - Öffnen eines Raums
  - Laden der ersten Timeline-Seite
  - Senden bis lokaler Status sichtbar ist
  - Scroll-Jank in Raumliste und Timeline
  - Speicher nach Öffnen mehrerer Räume
- [ ] iOS `os_signpost`-Messpunkte an Service- und Repository-Grenzen ergänzen.
- [ ] iOS-XCTest-Performancefälle für Mapping und Timeline-Diffs ergänzen.
- [ ] Android-Macrobenchmark-Modul für Start und Scrollen anlegen.
- [ ] Android Baseline Profile für die wichtigsten Startpfade prüfen.
- [ ] Rust-Benchmarks für DTO-Mapping und größere Snapshots ergänzen.
- [ ] Deterministische Fixtures definieren:
  - 100, 1.000 und 10.000 Räume
  - 100, 1.000 und 10.000 Timeline-Einträge
  - Diff-Bursts mit Insert, Remove, Reset und Set
- [ ] Messergebnisse unter `docs/quality/` versionieren.
- [ ] CI-Grenzwerte erst nach stabiler Baseline aktivieren.

Akzeptanz:

- Ein dokumentierter Befehl erzeugt pro Plattform vergleichbare Ergebnisse.
- Performance-Änderungen können gegen eine gespeicherte Baseline geprüft werden.
- Debug-Buildzeiten werden nicht als App-Laufzeitmessung ausgegeben.

### P0-04 Raumlisten-Ladepfad skalierbar machen

Ziel: Die Raumliste darf nicht für jeden Raum seriell auf `roomInfo()` warten.

- [ ] Aktuellen seriellen Ladepfad instrumentieren.
- [ ] Matrix Room List beziehungsweise Sliding-Sync-API als primäre Quelle prüfen.
- [ ] Falls Einzelabfragen notwendig bleiben, begrenzte Parallelität einsetzen.
- [ ] Ergebnisse inkrementell statt erst nach vollständigem Laden bereitstellen.
- [ ] Sortierregeln für Favoriten, Ungelesen und Aktualität zentralisieren.
- [ ] Fehler einzelner Räume isolieren; nicht die komplette Liste verwerfen.
- [ ] Caching- und Invalidierungsregeln dokumentieren.
- [ ] Tests mit großen Room-Fixtures und Teilfehlern ergänzen.

Akzeptanz:

- Kein unbegrenzter serieller `roomInfo()`-Loop im UI-kritischen Pfad.
- Erste verwertbare Raumdaten können vor Abschluss aller Detailabfragen erscheinen.
- Reihenfolge und Trust-Kennzeichnung bleiben deterministisch.

### P0-05 Timeline: Pagination, Diff-Verarbeitung und Cache-Lebensdauer

Ziel: Lange Timelines dürfen weder unbegrenzt wachsen noch bei Änderungen
regelmäßig vollständige Arrays kopieren.

- [ ] Initiale Seitenlänge und Pagination-Token in den Contract aufnehmen.
- [ ] Ältere Nachrichten bedarfsgesteuert nachladen.
- [ ] Maximale Zahl gleichzeitig aktiver Timeline-Kontexte definieren.
- [ ] Listener beim Verlassen eines Raums oder bei Eviction sicher abbrechen.
- [ ] Wiederöffnung und Cache-Wiederverwendung testen.
- [ ] `insert(at: 0)` und `removeFirst()` im häufigen Pfad vermeiden.
- [ ] Mehrere Diffs gebündelt anwenden.
- [ ] Nur geänderte Timeline-Items in UI-Modelle umwandeln.
- [ ] Reset-, Truncate-, Insert-, Remove- und Set-Grenzfälle testen.
- [ ] Initialisierungs-Polling durch ein klares asynchrones Signal mit Timeoutfehler ersetzen.
- [ ] Cancellation beim Raumwechsel und Logout testen.

Akzeptanz:

- Speicherverbrauch bleibt bei wiederholtem Öffnen vieler Räume begrenzt.
- Pagination und Listener-Lifecycle besitzen automatisierte Tests.
- Diff-Verarbeitung hat Benchmarks für große Timelines.
- Ein Initial-Load kann nicht still nach einer Polling-Schleife mit unklarem
  Zustand zurückkehren.

### P0-06 Listen- und Motion-Rendering optimieren

Ziel: Liquid-Glass-Design erhalten, ohne Scrollen und Texteingabe zu belasten.

- [ ] Bestehende iOS-Oberflächen vollständig gegen die iOS-27-Designsprache prüfen.
- [ ] Navigation, Materialien, Typografie, Controls und Übergänge mit nativen iOS-27-Komponenten abgleichen.
- [ ] Abweichungen zwischen iOS-27-Designziel und iOS-18-Deployment-Kompatibilität dokumentieren.
- [ ] Motion-Matrix für App-Start, Tabs, Raumwechsel, Nachrichten, Composer, Sheets, Auth, Recovery, Bridges und Security Center erstellen.
- [ ] Für jeden Übergang Trigger, Richtung, Dauer, Kurve, Unterbrechbarkeit und Reduce-Motion-Alternative festlegen.
- [ ] Interaktive Gesten und Übergänge auf Abbruch, Richtungswechsel und schnelle Wiederholung testen.
- [ ] Reale Frame-Zeiten, Hitches, Overdraw und GPU-Kosten auf Referenzgeräten messen.
- [ ] Motion-Regressionsprüfung mit langen Chatlisten und Timelines ergänzen.
- [ ] iOS-Animationen nicht mehr an `items.map(id)` der vollständigen Liste hängen.
- [ ] Einfüge-, Lösch- und Statusanimationen gezielt pro Element auslösen.
- [ ] Schatten, Material und Overdraw mit Instruments/Core Animation messen.
- [ ] Reduzierte visuelle Variante für lange Listen prüfen.
- [ ] Android-Recompositionen mit Layout Inspector beziehungsweise Tracing prüfen.
- [ ] `collectAsStateWithLifecycle()` für Android-Routen bewerten.
- [ ] Stabile Schlüssel und unveränderliche UI-Modelle beibehalten.
- [ ] Reduce Motion und Reduce Transparency auf beiden Plattformen testen.
- [ ] Scrolltests mit langen Texten, großen Schriftgrößen und 10.000 Items ausführen.

Akzeptanz:

- Keine vollständige Listenanimation für eine einzelne Statusänderung.
- Performancebudgets werden auf den definierten Referenzgeräten eingehalten.
- Accessibility-Varianten sind funktional und visuell geprüft.

### P0-07 CI vollständig und reproduzierbar machen

Ziel: Jede relevante Plattformänderung erhält den passenden automatischen
Nachweis.

- [ ] Rust-CI um Format, Tests und später Benchmarks ergänzen.
- [ ] Android-CI mit `assembleDebug`, Unit-Tests und Lint bestätigen.
- [ ] iOS-CI mit XcodeGen, SwiftPM-Tests und Simulator-Build bestätigen.
- [ ] Workflow-Trigger für den Produktbranch und Pull Requests prüfen.
- [ ] Dependency-Caches kontrolliert und reproduzierbar einrichten.
- [ ] Testreports und relevante Build-Artefakte hochladen.
- [ ] Performancejobs getrennt von normalen Korrektheitschecks ausführen.
- [ ] Branch Protection und erforderliche Checks für `main` festlegen.

Akzeptanz:

- Ein sauberer Checkout kann alle nicht geheimnisabhängigen Checks ausführen.
- Pull Requests zeigen eindeutig, welcher Plattformnachweis fehlt oder fehlschlägt.
- Keine produktiven Zugangsdaten befinden sich in CI-Konfigurationen.

### P0-08 Session, Storage und Logout produktionsnah validieren

Ziel: Session-Restore, Tokenrotation und Löschung müssen nachweisbar sicher sein.

- [ ] Login gegen einen kontrollierten Test-Homeserver prüfen.
- [ ] OIDC/MAS-Callback, Abbruch und Fehlerzustände testen.
- [ ] Passwort-Login nur bei angebotener Capability anzeigen.
- [ ] App-Neustart mit gültiger und ungültiger Session testen.
- [ ] Tokenrotation und Keychain-Update prüfen.
- [ ] Logout entfernt Restoration Token, Store und Cache.
- [ ] Backup-Ausschluss für Daten- und Cacheverzeichnisse verifizieren.
- [ ] Logs auf Tokens, Recovery Keys und personenbezogene Inhalte prüfen.
- [ ] Mehrkontenfähigkeit gegen ADR-0005 abgleichen.

Akzeptanz:

- Sicherheitsrelevante Zustandsübergänge sind automatisiert oder mit
  reproduzierbarem Testprotokoll nachgewiesen.
- Logout hinterlässt keine wiederverwendbare lokale Sitzung.
- Geheimnisse erscheinen weder in UI-DTOs noch Logs.

## P1 - Produktionsnahes MVP

### P1-01 Android-Live-Integration

- [ ] Gewählte Core-/Adapterarchitektur für Android implementieren.
- [ ] Session-State und Login an Android anbinden.
- [ ] Live-Raumliste hinter `ChatListRepository` bereitstellen.
- [ ] Live-Timeline und Textversand hinter `RoomTimelineRepository` bereitstellen.
- [ ] Offline-, Auth-expired- und Rate-limit-Zustände modellieren.
- [ ] Android-Integrationstests mit Fixtures ergänzen.
- [ ] Verhalten und Trust-Kennzeichnung gegen iOS vergleichen.

### P1-02 Live-Update-Contracts

- [ ] Snapshot-only-Repositories um lifecycle-sichere Streams ergänzen.
- [ ] Cancellation, Backpressure und Fehlerbeendigung definieren.
- [ ] Sessionwechsel als harte Stream-Grenze behandeln.
- [ ] Room List- und Timeline-Events wertbasiert und SDK-frei halten.
- [ ] Streaming-Tests für langsame Consumer und Diff-Bursts ergänzen.

### P1-03 Nachrichtenfluss vervollständigen

- [ ] Lokales Echo und Serverbestätigung eindeutig trennen.
- [ ] Sendestatus `sending`, `sent`, `delivered`, `read`, `failed` validieren.
- [ ] Retry und Fehlerdetails implementieren.
- [ ] Doppelte Events nach Sync oder Retry verhindern.
- [ ] Edits, Deletes und Reactions im Domain-Contract vorbereiten.
- [ ] Offline-Queue und Wiederanlaufentscheidung dokumentieren.

### P1-04 Push und Notification Service Extension

- [ ] Release-Push-Gateway konfigurieren.
- [ ] APNs-Tokenrotation testen.
- [ ] `event_id_only`-Pusher gegen Testumgebung validieren.
- [ ] App Group und Shared Keychain provisionieren.
- [ ] NSE-Entschlüsselungsstrategie entscheiden und implementieren.
- [ ] Zeitlimit-, Fallback- und fehlende-ID-Fälle testen.
- [ ] Push-Open navigiert immer in den korrekten Account und Raum.

### P1-05 Security Center und Recovery

- [ ] SAS-Verifikation auf zwei realen Testgeräten prüfen.
- [ ] Emoji-Übereinstimmung, Ablehnung und Abbruch testen.
- [ ] Recovery-Key-Erzeugung, Rotation und Import validieren.
- [ ] Key-Backup-Zustände verständlich darstellen.
- [ ] Matrix-, Device- und Bridge-Trust sichtbar trennen.
- [ ] Screenshots und Accessibility-Review dokumentieren.

### P1-06 Bridge Hub produktionsnah machen

- [ ] Konkrete mautrix-whatsapp- und mautrix-signal-Versionen festlegen.
- [ ] Management-Room-IDs umgebungsspezifisch konfigurieren.
- [ ] Login, Cancel und Logout gegen reale Testinstanzen prüfen.
- [ ] QR-Medien und Ablaufzeiten behandeln.
- [ ] Bridge-Bot-Antworten robust parsen.
- [ ] Externe Transportwarnung dauerhaft sichtbar halten.
- [ ] Fehler- und Reconnect-Zustände testen.

### P1-07 Ende-zu-Ende-Qualitätsszenarien

- [ ] Login -> Raumliste -> Timeline -> Send -> Empfang testen.
- [ ] Session Restore nach Prozessende testen.
- [ ] Verschlüsselten und unverschlüsselten Raum vergleichen.
- [ ] Push -> App-Open -> korrekter Raum testen.
- [ ] Logout -> erneuter Login testen.
- [ ] Netzwerkverlust und Wiederverbindung testen.
- [ ] Große Raumliste und lange Timeline auf Referenzgeräten testen.

## P2 - Produktausbau

### P2-01 Nachrichtenfunktionen

- [ ] Mediennachrichten
- [ ] Antworten und Threads
- [ ] Reactions
- [ ] Bearbeiten und Löschen
- [ ] Suche
- [ ] Lesebestätigungen und Typing-Zustände

### P2-02 Plattformfunktionen

- [ ] iOS Share Extension
- [ ] Android Share Target
- [ ] Deep Links und Universal Links
- [ ] Hintergrundverhalten und Energiemessung
- [ ] Datei- und Mediencache mit Limits

### P2-03 Calls

- [ ] Call-Boundary gemäß ADR-0011 konkretisieren.
- [ ] Anbieter- und Protokollentscheidung dokumentieren.
- [ ] Audio-/Video-Berechtigungen und Unterbrechungen behandeln.
- [ ] CallKit beziehungsweise Android Telecom Integration prüfen.
- [ ] Netzwerk-, Akku- und Thermal-Performance messen.

### P2-04 Billing und Entitlements

- [ ] Free-/Pro-/Business-Entitlements implementieren.
- [ ] StoreKit- und Google-Play-Billing-Adapter trennen.
- [ ] Entitlement-State nicht in Screens verteilen.
- [ ] Restore Purchases und Accountwechsel testen.
- [ ] Serverseitige Validierungsstrategie dokumentieren.

### P2-05 Release-Vorbereitung

- [ ] App-IDs, Signing, Team und Provisioning festlegen.
- [ ] Datenschutztexte und Store-Metadaten finalisieren.
- [ ] Threat Model und Security Review aktualisieren.
- [ ] Accessibility-Audit durchführen.
- [ ] Lokalisierung und Pseudolokalisierung prüfen.
- [ ] Crash- und Performance-Monitoring datensparsam konfigurieren.
- [ ] Rollback- und Incident-Prozess dokumentieren.
- [ ] Release Candidate gegen `quality/release-definition.md` abnehmen.

## Empfohlene Reihenfolge der nächsten fünf Arbeitspakete

1. P0-01 Branch- und CI-Status klären.
2. P0-02 Core-/FFI-Architekturentscheidung treffen.
3. P0-03 Performance-Baseline einführen.
4. P0-04 Raumliste und P0-05 Timeline skalierbar machen.
5. P0-08 Session- und Storage-Sicherheit in einer Testumgebung validieren.

## Abschlussnachweis pro Aufgabe

Jeder abgeschlossene Punkt soll im zugehörigen PR enthalten:

- Problem und Ziel
- betroffene Module und Architekturgrenzen
- Implementierung
- automatisierte Tests
- manuelle Prüfungen
- Performancevergleich, falls relevant
- aktualisierte Dokumentation
- bekannte Risiken und Folgeaufgaben
