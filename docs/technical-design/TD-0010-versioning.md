# TD-0010 Versioning

## Ziel

ShadowChat nutzt eine klare, getrennte Versionierungsstrategie fuer Produkt, iOS-Builds und Android-Builds.

## Produktversion

Die sichtbare Produktversion folgt Semantic Versioning im Format `MAJOR.MINOR.PATCH`.

### Regeln

- MAJOR bei inkompatiblen Aenderungen oder klaren Bruchstellen
- MINOR bei neuen, rueckwaertskompatiblen Funktionen
- PATCH bei Bugfixes und kleineren kompatiblen Korrekturen

## iOS

- `CFBundleShortVersionString` ist die nutzersichtbare Release-Version.
- `CFBundleVersion` ist der Build-Identifikator.
- Bei neuem Release wird die Release-Version erhoeht.
- Bei jedem neuen Upload eines Builds fuer dieselbe Release-Version wird der Build-Identifikator erhoeht.

## Android

- `versionName` ist die nutzersichtbare Version.
- `versionCode` ist die intern monoton steigende Ganzzahl.
- Bei jedem veroeffentlichten Build steigt `versionCode`.
- `versionName` folgt der Produktversion.

## Repo-Regel

Versionierung wird nicht erst kurz vor Store-Upload behandelt, sondern frueh im Repo, in CI und in Release-Dokumenten festgelegt.

## Repo-Dateien

- `VERSION` enthaelt die aktuelle Produktversion als einzelne Zeile.
- `CHANGELOG.md` dokumentiert nutzer- und release-relevante Aenderungen.
- Android `versionName` und iOS `MARKETING_VERSION` sollen zur Produktversion passen.
- Android `versionCode` und iOS `CURRENT_PROJECT_VERSION` bleiben plattformspezifische Build-Zaehler.

## Changelog-Regeln

- Neue Slices tragen ihre sichtbaren oder release-relevanten Aenderungen unter `[Unreleased]` ein.
- Interne Validierungs- oder CI-Aenderungen werden dokumentiert, wenn sie den Release-Prozess betreffen.
- Keine technischen Core-Details oder Sicherheitsannahmen werden im Changelog als Produktverhalten verkauft, solange sie nicht implementiert und validiert sind.
