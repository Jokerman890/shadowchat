# iOS AGENTS

## Scope
Gilt für `apps/ios/`.

## Basis
- SwiftUI ist der primäre UI-Stack.
- Struktur: `App` -> `Scene` -> `View`.
- Systemnahe APIs bevorzugen.
- Visuelles und interaktives Designziel ist iOS 27.
- Das iOS-27-Designziel ändert nicht automatisch das in `project.yml` konfigurierte Deployment Target.
- Motion ist ein zentrales Produktmerkmal: Oberflächen sollen reichhaltig animiert, reaktionsschnell und flüssig wirken.

## Regeln
- UI und Domain trennen.
- Keine rohen Core-Details direkt in Views.
- Feature-Grenzen sichtbar halten.
- Navigation nicht mit Datenlogik vermischen.
- Reduce Motion und Accessibility mitdenken.
- Neue Oberflächen gegen iOS-27-Navigation, Materialien, Typografie, Motion und Systemverhalten prüfen.
- Übergänge passend zum Kontext variieren, zum Beispiel für App-Bereiche, Raumwechsel, Nachrichten, Composer, Sheets und Security-Flows.
- Animationen interaktiv und unterbrechbar gestalten, wenn das Systemverhalten dies vorsieht.
- Keine Animation akzeptieren, die Scrollen, Texteingabe, Navigation oder Energieverbrauch merklich verschlechtert.
- Für Reduce Motion eine vollständige, ruhige Alternative ohne Informationsverlust bereitstellen.

## Ziele
- `ShadowChatApp`
- `ShadowChatNSE`
- `ShadowChatShareExtension`

## Prüfen
- relevante Build- und Test-Schritte
- State- und Zielkonsistenz
