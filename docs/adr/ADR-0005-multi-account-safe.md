# ADR-0005 Multi-Account Safe

## Entscheidung
Die Architektur wird von Anfang an multi-account-safe ausgelegt.

## Begründung
- spätere Pro- und Business-Funktionen
- getrennte Arbeitskontexte
- saubere Session- und Geräteverwaltung

## Konsequenzen
- keine globale Singleton-Session
- Storage und Notification-Kontexte werden account-spezifisch gedacht
