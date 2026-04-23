# ADR-0002 Rust Core

## Entscheidung
Der gemeinsame Produktkern wird in Rust aufgebaut.

## Begründung
- gemeinsame Logik für iOS und Android
- saubere Trennung von UI und Domain
- gute Grundlage für Session, Sync, Security und Messaging

## Konsequenzen
- FFI- und Binding-Schichten sind notwendig
- Domain-Modelle müssen bewusst gestaltet werden
