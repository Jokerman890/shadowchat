# Mobile Validation Task Prompt

Du validierst Mobile-Aenderungen in diesem Repository.

## Ziel
Fuehre die passenden Checks fuer `[FEATURE/AREA]` aus und dokumentiere das Ergebnis nachvollziehbar.

## Kontext
- Lies zuerst:
  - `AGENTS.md`
  - relevante Dateien unter `docs/quality/`
  - relevante technische Designs unter `docs/technical-design/`
  - betroffene Projektdateien unter `apps/ios/`, `apps/android/` oder `core/`
- Waehle Checks passend zum betroffenen Bereich. Fuehre keine unrelated Refactors aus.

## Check-Auswahl
- Rust:
  - `cargo fmt --all --check`
  - `cargo test --workspace`
- Android:
  - relevante Gradle Builds, z. B. `./gradlew assembleDebug`
  - relevante Unit- oder UI-Tests
  - Lint, falls konfiguriert
- iOS:
  - relevante Build- oder Test-Schritte, wenn Projektdateien und Targets vorhanden sind
  - Preview- oder Simulator-Kompatibilitaet, soweit lokal moeglich
- Dokumentation:
  - pruefen, ob PRD, Technical Design, ADR, Design- oder Quality-Dokumente betroffen sind

## Vorgehen
- Pruefe zuerst, welche Build-Systeme und Targets tatsaechlich vorhanden sind.
- Starte mit den kleinsten relevanten Checks und erweitere nur bei Bedarf.
- Brich nicht beim ersten Fehler ab, wenn weitere unabhaengige Checks sinnvoll sind.
- Sammle konkrete Fehlermeldungen mit betroffenen Modulen oder Dateien.
- Aendere Code nur, wenn die Validierungsaufgabe ausdruecklich auch Fehlerbehebung umfasst.

## Ausgabeformat
- Kurze Zusammenfassung des Validierungsergebnisses.
- Auflistung der ausgefuehrten Checks mit Status:
  - passed
  - failed
  - skipped, inklusive Grund
- Bei Fehlern:
  - betroffener Befehl
  - relevante Fehlermeldung
  - wahrscheinlicher naechster Schritt
- Offene Risiken oder nicht validierte Bereiche.

## Done When
- Alle relevanten vorhandenen Checks wurden ausgefuehrt oder begruendet uebersprungen.
- Ergebnis ist fuer einen PR oder Handoff direkt nutzbar.
