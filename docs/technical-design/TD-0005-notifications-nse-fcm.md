# TD-0004 Notifications NSE FCM

## Ziel
Präzisierung der Push-Architektur für iOS und Android.

## iOS
- Notification Service Extension ist eigener Ausführungskontext.
- Remote Notifications können vor der Anzeige angepasst werden.
- Decryption oder Medienanreicherung gehören in diesen Pfad, nicht in die Haupt-UI.

## Android
- Push-Handling und Open-Flow werden getrennt vom Screen-Code modelliert.
- Deep Links und Zielkontext müssen stabil und testbar sein.

## Regeln
- Notification-Handling nie über mehrere Screens verstreuen.
- Trust- und Session-Kontext beim Öffnen erhalten.
- Fehlerfall und Fallback-Pfade explizit testen.
