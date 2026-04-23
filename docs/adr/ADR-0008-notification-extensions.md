# ADR-0008 Notification Extensions

## Entscheidung
Notification Extensions und Push-Open-Flows sind eigene Architekturthemen.

## Konsequenzen
- iOS NSE ist eigener Kontext.
- Push-Handling bleibt außerhalb der Screen-Logik.
- Open- und Fehlerpfade werden separat getestet.
