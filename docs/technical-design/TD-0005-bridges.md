# TD-0005 Bridges

## Ziel
Bridges werden als separates Produkt- und Architekturthema behandelt.

## Grundsatz
Externe Quellen oder Netzwerke sind nicht identisch mit nativen ShadowChat-Kontexten.

## Regeln
- Bridge-Kontexte brauchen eigene Trust-Signale.
- Bridge-Status darf nicht wie nativer End-to-End-Kontext erscheinen.
- Bridge-Handling bleibt aus dem MVP-Kern herausgelöst.
- Fehler-, Sync- und Warnpfade werden separat modelliert.

## Produktfolge
ShadowChat bleibt Matrix-first. Bridges sind optionale Erweiterung und kein Kernversprechen des MVP.
