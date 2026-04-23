# TD-0001 System Architecture

## Ziel
Definition der Zielarchitektur für ShadowChat auf iOS und Android.

## Architektur
- gemeinsamer Rust-Core für Messaging, Session, Sync, Security und Domain-Modelle
- native UI auf iOS und Android
- klarer Boundary-Layer zwischen UI und Core
- vorbereitete Module für Billing, Bridges und Security Center

## Hauptschichten
1. Core
   - Auth
   - Session
   - Sync
   - Rooms
   - Timeline
   - Media
   - Notifications
   - Crypto
2. Plattform
   - iOS SwiftUI
   - Android Compose
3. Produkt
   - Free / Pro / Business
   - Security Center
   - Bridge Hub

## Regeln
- UI importiert keine rohen Core-Implementierungsdetails
- Domain-Typen bleiben app-eigen
- Security- und Bridge-Kontexte werden sichtbar markiert
