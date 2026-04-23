# TD-0004 Notifications

## Ziel
Zuverlässige Push- und Open-Flows für iOS und Android.

## Anforderungen
- Push muss Chat-Einstieg sauber öffnen
- Notification-Handling ist eigener Architekturteil
- sensible Inhalte werden nur kontrolliert dargestellt
- iOS Notification Service Extension wird von Anfang an berücksichtigt

## Kernpfade
1. Push empfangen
2. Payload validieren
3. Zielkontext bestimmen
4. Chat öffnen
5. Fehlerfall sauber abfangen

## Regeln
- Notification-Logik nicht in UI verteilen
- Push-Open-Flows werden separat getestet
- Security- und Trust-Status bleiben auch aus Notifications sichtbar
