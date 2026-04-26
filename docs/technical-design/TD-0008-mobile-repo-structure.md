# TD-0008 Mobile Repo Structure

## Ziel
Startstruktur für ShadowChat im Repo.

## Hauptebenen
- docs
- core
- apps/ios
- apps/android
- infra
- product

## iOS
- App Target
- Notification Service Extension
- Share Extension
- Design- und Motion-Module
- Feature-Module

## Android
- app
- appnav
- appconfig
- core
- features
- services
- designsystem
- motion

## Aktueller Mobile Build-Slice
- iOS SwiftPM liegt unter `apps/ios/Packages`.
- iOS App Target liegt unter `apps/ios/ShadowChat.xcodeproj`.
- Android Gradle Root liegt unter `apps/android`.
- Android Module:
  - `:app`
  - `:designsystem`
  - `:features:chatlist`
  - `:features:timeline`
- Android `:app` hostet die Chat-Liste als Startscreen.
- iOS `ShadowChat` hostet `ShadowChatRootView` aus `ShadowChatAppShell` als Startscreen.
- Der Chat-Listen-Slice ist buildbar, testbar und ohne Matrix- oder Rust-Bridge verdrahtet.
- Der Room-Timeline-Shell-Slice liegt als eigenes Android-Feature-Modul und als eigenes iOS SwiftPM-Feature-Target vor.
- Der Liquid-Glass-UI-Slice erweitert die bestehenden Designsystem-Module um helle Pastell-Hintergründe, Glas-Panels, stärkere Rundungen und Lila-Blau-Akzente.
- Android und iOS besitzen eine minimale Bottom-Tab-App-Shell; nur `Chats` ist fachlich verdrahtet, `Calls`, `Updates`, `Profile` und `Settings` bleiben reine UI-Shells ohne Produktlogik.

## Regeln
- Feature-Grenzen bleiben sichtbar
- UI bleibt vom Core getrennt
- Billing und Trust-Kontexte bleiben eigene Themen
