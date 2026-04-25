# Mobile Review Task Prompt

Du fuehrst ein Mobile-Code-Review in diesem Repository durch.

## Ziel
Reviewe die Aenderungen fuer `[FEATURE/AREA]` mit Fokus auf iOS, Android, gemeinsamen Core und Dokumentation.

## Kontext
- Lies zuerst die relevanten Dateien unter:
  - `apps/ios/` fuer SwiftUI/iOS-Aenderungen
  - `apps/android/` fuer Kotlin/Compose-Aenderungen
  - `core/` fuer Rust-Core-Aenderungen
  - `docs/design/`
  - `docs/technical-design/`
  - `docs/adr/`
  - `docs/quality/`
- Beachte `AGENTS.md` und speziellere `AGENTS.md`-Dateien in Unterverzeichnissen.
- Vergleiche die Aenderungen gegen bestehende Patterns, nicht gegen erfundene Zielarchitektur.

## Review-Fokus
- Compile- oder Runtime-Risiken.
- Architekturgrenzen zwischen UI, Domain, Security, Notifications, Billing und externen Quellen.
- State-Management, Navigation und Lifecycle-Verhalten.
- Accessibility, Dark Mode, Dynamic Type bzw. Font Scaling und Displaygroessen.
- Performance in Listen, Chat-Timelines, Animationen und Core-Bridges.
- Security- und Trust-Zustaende: explizit, sichtbar und nicht mit sicheren nativen Kontexten verwechselt.
- Billing- und Entitlement-Logik: nicht ueber Screens verteilt.
- Notification-Handling: eigener Architekturstrang bleibt erkennbar.
- Tests, Previews, Fixtures und Dokumentationspflichten.

## Plattform-Hinweise
- iOS: SwiftUI, systemnahe APIs, keine unnoetigen UIKit-Bridges, saubere Accessibility Labels.
- Android: Jetpack Compose, Material 3, State down/events up, Ressourcen statt hardcoded Strings.
- Rust: `shadow_core_*`-Konventionen und klare FFI-/Bridge-Grenzen beachten.

## Ausgabeformat
- Findings zuerst, nach Schwere sortiert.
- Jede Finding mit Datei, Zeile, Risiko und konkreter Begruendung.
- Keine grossen Zusammenfassungen vor den Findings.
- Wenn keine Findings gefunden werden, sage das klar und nenne verbleibende Testluecken oder Restrisiken.
- Danach kurz:
  - Offene Fragen oder Annahmen.
  - Welche Checks gelesen oder ausgefuehrt wurden.
  - Kurze Zusammenfassung des geprueften Umfangs.

## Done When
- Risiken sind konkret und reproduzierbar beschrieben.
- Keine Stilfragen ohne praktisches Risiko dominieren das Review.
- Dokumentations- oder Testluecken sind sichtbar gemacht.
