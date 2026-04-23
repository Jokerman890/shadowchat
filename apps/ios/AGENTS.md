# iOS AGENTS

## Scope
Gilt für `apps/ios/`.

## Basis
- SwiftUI ist der primäre UI-Stack.
- Struktur: `App` -> `Scene` -> `View`.
- Systemnahe APIs bevorzugen.

## Regeln
- UI und Domain trennen.
- Keine rohen Core-Details direkt in Views.
- Feature-Grenzen sichtbar halten.
- Navigation nicht mit Datenlogik vermischen.
- Reduce Motion und Accessibility mitdenken.

## Ziele
- `ShadowChatApp`
- `ShadowChatNSE`
- `ShadowChatShareExtension`

## Prüfen
- relevante Build- und Test-Schritte
- State- und Zielkonsistenz
