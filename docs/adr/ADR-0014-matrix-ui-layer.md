# ADR-0014 Matrix UI Layer

## Entscheidung
ShadowChat kapselt SDK-nahe Typen hinter einem app-eigenen Domain- und Service-Layer.

## Ziel
UI und Features arbeiten mit stabilen ShadowChat-Modellen statt direkt mit low-level SDK-Typen.

## Konsequenzen
- Mapping bleibt zentral.
- UI-Modelle bleiben kontrollierbar.
- Produktlogik für Trust, Billing und externe Quellen kann sauber ergänzt werden.
