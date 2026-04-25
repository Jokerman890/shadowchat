# iOS Screen Task Prompt

Du arbeitest im iOS-Teil dieses Repositories.

## Ziel
Implementiere bzw. ueberarbeite die iOS-App-Oberflaeche fuer `[FEATURE/SCREEN]` in SwiftUI.

## Kontext
- Lies zuerst die relevanten Dateien unter:
  - `apps/ios/`
  - `docs/design/`
  - `docs/technical-design/`
  - `docs/adr/`
- Nutze vorhandene Design-System-Dateien, Theme-Dateien und Komponenten.
- Falls bestehende Patterns vorhanden sind, erweitere diese statt neue Parallelstrukturen zu bauen.
- Beachte `AGENTS.md` und speziellere `AGENTS.md`-Dateien in Unterverzeichnissen.

## Plattform-Vorgaben
- Native SwiftUI-Struktur verwenden.
- Keine UIKit-Bridges, ausser im Projekt bereits etabliert oder technisch notwendig.
- Navigation mit SwiftUI-Navigation APIs passend zur vorhandenen Architektur.
- Dark Mode, Dynamic Type, Safe Areas und Accessibility Labels unterstuetzen.
- SF Symbols verwenden, sofern passende Icons benoetigt werden.
- Design soll Apple-nativ wirken, nicht wie ein Android-Port.
- Falls Liquid-Glass-Stil verwendet wird: subtil, performant, lesbar, keine uebertriebene Transparenz.

## Architektur
- View-Code von State- und Business-Logik trennen.
- Bestehende ViewModels, StateHolder oder Services nutzen.
- Keine Hardcoded Mock-Daten in produktiven Views.
- Keine globalen Singletons einfuehren, ausser dies ist bereits ein bestehendes Projektpattern.
- UI darf keine rohen Core-Implementierungsdetails oder internen Infrastrukturtypen direkt kennen.

## Umfang
- Implementiere nur `[KONKRETER SCOPE]`.
- Aendere keine unrelated Files.
- Keine neuen Dependencies ohne ausdrueckliche Begruendung.
- Wenn Produktverhalten geaendert wird, pruefe, ob PRD oder Technical Design aktualisiert werden muessen.
- Wenn eine neue technische Entscheidung entsteht, lege eine ADR an oder aktualisiere eine bestehende ADR.

## Validierung
- Fuehre iOS Build/Test aus, falls im Repo moeglich.
- Pruefe Preview- oder Simulator-Kompatibilitaet, soweit lokal moeglich.
- Achte bei UI-Aenderungen auf Zielhierarchie, Accessibility und State-Konsistenz.
- Dokumentiere, welche Checks erfolgreich waren und welche nicht ausgefuehrt werden konnten.

## Done When
- Screen ist funktional.
- UI folgt dem bestehenden Design-System.
- Keine Compile-Fehler.
- Keine Placeholder-Texte ausser explizit erlaubt.
- Kurze Abschlusszusammenfassung mit geaenderten Dateien, Tests und Risiken.
