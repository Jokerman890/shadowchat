# Privacy Logging Policy

## Ziel
Logging und Telemetry dürfen keine unnötigen sensiblen Inhalte preisgeben.

## Regeln
- Keine Message-Inhalte in Logs.
- Keine Klartext-Token in Logs.
- Session- und Device-IDs nur kontrolliert und minimiert loggen.
- Fehlerberichte priorisieren technische Ursache, nicht Nutzerdaten.
- Debug-Ausgaben für lokale Entwicklung dürfen nicht ungeprüft in Produktivpfade gelangen.

## Produktprinzip
ShadowChat nutzt redacted observability. Stabilität und Diagnose sind wichtig, aber Inhalte und Identitäten werden nur so weit verarbeitet, wie es technisch zwingend nötig ist.
