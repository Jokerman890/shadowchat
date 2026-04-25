# Android Screen Task Prompt

Du arbeitest im Android-Teil dieses Repositories.

## Ziel
Implementiere bzw. ueberarbeite den Android-Screen `[FEATURE/SCREEN]` mit Kotlin und Jetpack Compose.

## Kontext
- Lies zuerst die relevanten Dateien unter:
  - `apps/android/`
  - `docs/design/`
  - `docs/technical-design/`
  - `docs/adr/`
- Nutze vorhandene Theme-, Navigation- und Design-System-Strukturen.
- Keine neue Architektur neben der bestehenden einfuehren.
- Beachte `AGENTS.md` und speziellere `AGENTS.md`-Dateien in Unterverzeichnissen.

## Plattform-Vorgaben
- Jetpack Compose verwenden.
- Material 3 und `MaterialTheme` verwenden.
- State hoisting und unidirectional data flow beachten:
  - State down.
  - Events up.
- ViewModel bzw. vorhandene StateHolder verwenden.
- Dark Mode, Dynamic Color, Accessibility und unterschiedliche Displaygroessen beruecksichtigen.
- Adaptive Layouts beruecksichtigen, wenn der Screen fuer Tablet oder Foldable relevant ist.
- Keine XML-Layouts neu einfuehren, ausser das Projekt verwendet sie bereits bewusst.

## Architektur
- UI-Composables moeglichst stateless halten.
- Business-Logik nicht in Composables verstecken.
- Navigation ueber vorhandenes Navigation-System.
- Keine Hardcoded Strings; Ressourcen verwenden.
- Keine neuen Dependencies ohne klare technische Notwendigkeit.
- UI darf keine rohen Core-Implementierungsdetails oder internen Infrastrukturtypen direkt kennen.

## Umfang
- Implementiere nur `[KONKRETER SCOPE]`.
- Keine unrelated Refactors.
- Bestehende Tests nicht entfernen.
- Bestehende APIs nicht brechen.
- Wenn Produktverhalten geaendert wird, pruefe, ob PRD oder Technical Design aktualisiert werden muessen.
- Wenn eine neue technische Entscheidung entsteht, lege eine ADR an oder aktualisiere eine bestehende ADR.

## Validierung
- Fuehre einen Gradle Build aus, z. B. `./gradlew assembleDebug`, falls im Repo moeglich.
- Fuehre relevante Unit- oder UI-Tests aus, falls vorhanden.
- Pruefe Lint, falls im Projekt konfiguriert.
- Melde sauber, welche Checks gelaufen sind und welche nicht ausgefuehrt werden konnten.

## Done When
- Screen kompiliert.
- UI folgt Material 3 und dem Projekt-Design-System.
- State/Event-Fluss ist sauber.
- Keine Placeholder-Texte ausser explizit erlaubt.
- Kurze Zusammenfassung mit geaenderten Dateien, Tests und offenen Risiken.
