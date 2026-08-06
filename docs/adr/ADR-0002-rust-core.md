# ADR-0002 Rust Core

## Status

Akzeptiert und durch ADR-0016 präzisiert.

## Entscheidung
Der gemeinsame, plattformneutrale Produktkern wird in Rust aufgebaut.

Die operative Matrix-Laufzeit mit Client, Sync, Room List, Timeline, Crypto
und SDK-Persistenz gehört gemäß ADR-0016 in native Plattformadapter. Der
Rust-Core ist keine zweite Matrix-Laufzeit hinter einer zusätzlichen
ShadowChat-FFI.

## Begründung
- gemeinsame Produktregeln und Testvektoren für iOS und Android
- saubere Trennung von UI und Domain
- stabile Wertmodelle für Session-, Trust-, Security- und Messaging-Semantik

## Konsequenzen
- FFI- und Binding-Schichten sind nur für ausgewählte grobgranulare
  Core-Funktionen notwendig
- hochfrequente Matrix-Streams bleiben außerhalb der ShadowChat-Core-FFI
- Domain-Modelle müssen bewusst gestaltet werden
- Plattformadapter müssen gemeinsame Contract-Fixtures erfüllen
