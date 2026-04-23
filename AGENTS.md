# AGENTS.md

## Scope
Diese Datei gilt für das gesamte Repository, sofern in Unterverzeichnissen keine speziellere AGENTS.md liegt.

## Ziel des Repos
ShadowChat ist ein Monorepo für einen Premium-Messenger auf iOS und Android.

Kernprinzipien:
- gemeinsamer Rust-Core
- native UI auf iOS und Android
- klare Trennung zwischen UI, Domain, Security, Notifications, Billing und externen Quellen
- motion-first Designsystem mit kontrollierter Performance

## Codex-Arbeitsregeln
1. Lies vor jeder Änderung die relevante Dokumentation unter `docs/`.
2. Bevorzuge kleine, klar begrenzte Änderungen.
3. Erfinde keine Architekturannahmen, wenn ein passendes Dokument bereits existiert.
4. Wenn du eine neue technische Entscheidung triffst, lege eine ADR an oder aktualisiere eine bestehende ADR.
5. Wenn du Produktverhalten änderst, aktualisiere auch PRD oder Technical Design.
6. Wenn du neue Module einführst, halte Namensschema und Boundary-Regeln ein.

## Architekturregeln
- UI darf keine rohen Core-Implementierungsdetails oder interne Infrastrukturtypen direkt kennen.
- Domain-Modelle bleiben app-eigen und stabil.
- Security- und Trust-Zustände müssen explizit und sichtbar sein.
- Externe oder gebridgte Kontexte dürfen nicht wie native sichere Kontexte behandelt werden.
- Billing- und Entitlement-Logik wird nicht in Screens verteilt.
- Notification-Handling ist ein eigener Architekturstrang.

## iOS-Regeln
- Primärer UI-Stack: SwiftUI.
- Bevorzuge systemnahe Komponenten und APIs.
- Nutze Standardnavigation und Standardcontrols, wenn dies Produkt- und Designziele nicht verletzt.
- Berücksichtige Notification Service Extension und Share Extension als eigene Ziele.
- Harte Layout- oder Appearance-Overrides in Navigations- und Control-Layern vermeiden, wenn sie Systemverhalten stören.

## Android-Regeln
- Primärer UI-Stack: Jetpack Compose.
- Halte die Android-Architektur geschichtet und klar getrennt.
- Bevorzuge modulare Features mit sichtbaren Grenzen.
- Neue Features sollen möglichst als eigene Feature-Module gedacht werden.
- Navigation, State und UI-Logik nicht unstrukturiert vermischen.

## Design- und Motion-Regeln
- Lesbarkeit vor Effekten.
- Animation erklärt Fokus, Status oder Hierarchie.
- Listen und Chat-Timelines bleiben performant.
- Reduce Motion und Reduce Transparency immer mitdenken.
- Design-Tokens statt hart codierter Einzelwerte bevorzugen.

## Dokumentationspflichten
Aktualisiere bei Bedarf:
- `docs/prd/`
- `docs/technical-design/`
- `docs/adr/`
- `docs/design/`
- `docs/quality/`

## Dateinamens- und Modulkonventionen
- Rust-Crates: `shadow_core_*`
- iOS-Module: `Shadow*`
- Android-Packages: `com.shadowchat.*`
- Dokumente: konsistente Nummerierung und klare Titel

## Tests und Verifikation
Wenn die nötigen Projektdateien bereits vorhanden sind, führe die passenden Checks für den betroffenen Bereich aus.

### Rust
- `cargo fmt --all --check`
- `cargo test --workspace`

### Android
- relevante Gradle-Checks für betroffene Module
- UI- oder State-Änderungen möglichst mit Preview- oder UI-Test-Update begleiten

### iOS
- relevante Build- oder Test-Schritte nur dann verlangen, wenn Projektdateien und Targets vorhanden sind
- bei UI-Änderungen auf Zielhierarchie, Accessibility und State-Konsistenz achten

## Pull-Request-Qualität
Jede Änderung soll in der Beschreibung oder Commit-Struktur klar machen:
- was geändert wurde
- warum es geändert wurde
- welche Dokumente mitgezogen wurden
- welche Risiken oder offenen Punkte bleiben
