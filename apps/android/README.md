# Android App

Hier liegt die native Android-App von ShadowChat.

## Erwartete Bereiche
- app
- appnav
- appconfig
- core-Module
- feature-Module
- services
- designsystem und motion

## UI-Stack
Jetpack Compose mit modularer Architektur und klaren Feature-Grenzen.

## Build und Tests
- `./gradlew tasks`
- `./gradlew assembleDebug`
- `./gradlew testDebugUnitTest`
- `./gradlew lint`

## Module
- `app`: minimale Android-App-Shell mit `MainActivity` und Chat-Liste als Startscreen.
- `designsystem`: gemeinsame Compose-Tokens fuer Farbe, Spacing und Motion.
- `features/chatlist`: erster Chat-Listen-Slice mit UI-State, ViewModel, Repository-Schnittstelle und Compose-Screen.
- `features/timeline`: Room-Timeline-Shell mit UI-State, ViewModel, Repository-Schnittstelle und Compose-Screen ohne Matrix-Live-Anbindung.
