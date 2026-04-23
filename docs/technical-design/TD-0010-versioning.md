# TD-0010 Versioning

## Ziel
ShadowChat nutzt eine klare, getrennte Versionierungsstrategie für Produkt, iOS-Builds und Android-Builds.

## Produktversion
Die sichtbare Produktversion folgt Semantic Versioning im Format `MAJOR.MINOR.PATCH`.

### Regeln
- MAJOR bei inkompatiblen Änderungen oder klaren Bruchstellen
- MINOR bei neuen, rückwärtskompatiblen Funktionen
- PATCH bei Bugfixes und kleineren kompatiblen Korrekturen

## iOS
- `CFBundleShortVersionString` ist die nutzersichtbare Release-Version.
- `CFBundleVersion` ist der Build-Identifikator.
- Bei neuem Release wird die Release-Version erhöht.
- Bei jedem neuen Upload eines Builds für dieselbe Release-Version wird der Build-Identifikator erhöht.

## Android
- `versionName` ist die nutzersichtbare Version.
- `versionCode` ist die intern monoton steigende Ganzzahl.
- Bei jedem veröffentlichten Build steigt `versionCode`.
- `versionName` folgt der Produktversion.

## Repo-Regel
Versionierung wird nicht erst kurz vor Store-Upload behandelt, sondern früh im Repo, in CI und in Release-Dokumenten festgelegt.
