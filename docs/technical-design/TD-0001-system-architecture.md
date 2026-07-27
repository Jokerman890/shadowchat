# TD-0001 System Architecture

## Ziel
Definition der Zielarchitektur für ShadowChat auf iOS und Android.

## Architektur
- gemeinsamer Rust-Core für plattformneutrale Produktregeln, Wertmodelle und
  Contract-Fixtures
- native UI auf iOS und Android
- je Plattform ein Matrix-Adapter für Session, Sync, Room List, Timeline,
  Crypto und SDK-Persistenz
- klarer Boundary-Layer zwischen UI, Feature-Repositories, Plattformadapter
  und gemeinsamem Core
- vorbereitete Module für Billing, Bridges und Security Center

## Hauptschichten
1. Gemeinsamer Rust-Core
   - Session-, Trust- und Fehlersemantik
   - deterministische Room-/Timeline-Policies
   - plattformübergreifende Fixtures und Testvektoren
   - keine Matrix-Netzwerk-, Crypto- oder Store-Laufzeit
2. Plattformservices
   - genau ein Matrix-Client und Sync-Owner pro Account
   - Room List, Timeline, Senden und Pagination
   - Matrix-Crypto und Matrix-SDK-Store
   - Keychain beziehungsweise Android Keystore
   - Push, Notification Extension und Plattform-Lifecycle
3. Native UI
   - iOS SwiftUI
   - Android Compose
4. Produkt
   - Free / Pro / Business
   - Security Center
   - Bridge Hub

## Regeln
- UI importiert keine rohen Core-Implementierungsdetails
- UI und Feature-Module importieren keine Matrix-SDK-Typen
- Domain-Typen bleiben app-eigen
- Security- und Bridge-Kontexte werden sichtbar markiert
- Room-List- und Timeline-Hot-Paths werden nicht durch eine zusätzliche
  ShadowChat-FFI geleitet
- Plattformparität wird mit gemeinsamen Contracts, Fixtures und
  Conformance-Tests abgesichert

## Verantwortlichkeiten

| Bereich | Verantwortliche Schicht |
| --- | --- |
| Session und Sync | Plattform-Matrix-Adapter |
| Room List und Timeline | Plattform-Repositories über dem Matrix-Adapter |
| Crypto und Matrix-Store | Plattform-Matrix-Adapter und dessen SDK |
| Secrets | Plattform-Secure-Storage hinter dem Adapter |
| Gemeinsame Produktregeln | Rust-Core |
| Darstellung und Navigation | native Feature-UI |

Die vollständige Entscheidung und die Migrationspfade stehen in ADR-0016.
