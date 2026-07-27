# ADR-0015 Element X iOS Pattern Adoption

## Status

Akzeptiert.

## Kontext

ShadowChat benötigt eine belastbare native iOS-Struktur für Matrix-Session, Room List, Timeline, Crypto und spätere Bridges. Element X iOS ist die wichtigste produktive Referenz für den Einsatz des Matrix Rust SDK auf Apple-Plattformen. Ein direktes Einbetten der Element-X-UI würde jedoch ShadowChat-Domainmodelle, Produktnavigation und Trust-Kommunikation mit fremden App-Details koppeln.

## Entscheidung

ShadowChat übernimmt die Architekturprinzipien von Element X iOS, aber nicht dessen UI als Produktkern:

- SDK-nahe Implementierungen liegen hinter app-eigenen Actor-Protokollen.
- SwiftUI erhält ausschließlich ShadowChat-Modelle.
- Session- und Sync-Lifecycle sind getrennte Zustände.
- Der produktive Matrix-Adapter wird injiziert; lokale Vorschau und Tests verwenden denselben Contract.
- Zugangsdaten und Restoration Tokens werden nie in UI-DTOs transportiert.
- Bridges erhalten eigene Trust-Signale und werden nicht wie native Matrix-E2EE-Räume dargestellt.
- Element X bleibt als Upstream-Referenz getrennt; ShadowChat kann Upstream-Änderungen gezielt prüfen, ohne dessen Quellbaum zu vendoren.

## Konsequenzen

- Produkt-UI und Matrix-SDK können unabhängig weiterentwickelt und getestet werden.
- Ein SDK-Upgrade betrifft primär den Adapter und nicht alle Features.
- Die lokale Vorschau muss sichtbar als Vorschau gekennzeichnet bleiben.
- Der App-Store-fähige Build setzt einen produktiven `ShadowClientService` mit Keychain-Persistenz, Matrix-Sync und Crypto-Validierung voraus.

## Verworfene Alternativen

### Direkter Element-X-UI-Fork als ShadowChat-App

Dies würde schnelle erste Screens liefern, aber Branding, Navigation, Feature-Flags und Domainmodelle eng an Element X koppeln.

### Matrix-SDK-Typen direkt in SwiftUI

Dies reduziert kurzfristig Mapping-Code, macht UI-Tests und spätere Bridge-Trust-Regeln jedoch instabil.
