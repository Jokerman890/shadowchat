# Android AGENTS

## Scope
Gilt für `apps/android/`.

## Basis
- Jetpack Compose ist der primäre UI-Stack.
- Android bleibt geschichtet und modular.
- Feature-Grenzen sollen sichtbar bleiben.

## Regeln
- UI, State und Datenlogik trennen.
- Neue Features möglichst als eigene Feature-Module denken.
- Navigation nicht unstrukturiert in Screens verteilen.
- Designsystem und Motion zentral halten.
- Keine rohen Core-Details direkt in UI-Modulen.

## Modulrichtung
- `app`, `appnav`, `appconfig`
- `core/*`
- `features/*`
- `services/*`

## Prüfen
- relevante Gradle-Checks
- Compose-State und Navigation konsistent halten
- Performance in Listen und Chat-Timelines beachten
