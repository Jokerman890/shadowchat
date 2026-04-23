# ADR-0004 Auth OIDC MAS

## Entscheidung
ShadowChat wird OIDC / MAS-first aufgebaut.

## Begründung
- moderner Auth-Pfad im Matrix-Umfeld
- saubere Discovery- und Session-Modelle
- gute Grundlage für Multi-Account und Device Trust

## Konsequenzen
- Auth-Flow wird als eigener Architekturstrang behandelt
- Discovery und Redirect-Handling müssen früh sauber sein
