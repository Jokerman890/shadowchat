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

## Regeln
- Feature-Grenzen bleiben sichtbar
- UI bleibt vom Core getrennt
- Billing und Trust-Kontexte bleiben eigene Themen
