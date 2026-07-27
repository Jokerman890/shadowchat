# TD-0005 Notifications NSE FCM

## Ziel
Präzisierung der Push-Architektur für iOS und Android.

## iOS
- Notification Service Extension ist eigener Ausführungskontext.
- Remote Notifications können vor der Anzeige angepasst werden.
- Decryption oder Medienanreicherung gehören in diesen Pfad, nicht in die Haupt-UI.

### ShadowChat-Implementierungsstand

- `ShadowChatNSE` wird als eigenes App-Extension-Target durch XcodeGen erzeugt
  und in `ShadowChat` eingebettet.
- APNs-Registrierung beginnt ausschließlich nach expliziter Benutzeraktion.
- Matrix erhält einen `event_id_only`-Pusher mit datensparsamer Standard-Payload.
- `SHADOW_PUSH_GATEWAY_URL` ist eine notwendige Release-Konfiguration und hat
  keinen erfundenen Laufzeit-Fallback.
- Solange Shared-Keychain und NSE-Matrix-Client nicht mit einem Apple Team
  provisioniert sind, zeigt die NSE ausschließlich einen generischen Hinweis
  auf eine neue verschlüsselte Nachricht.

## Android
- Push-Handling und Open-Flow werden getrennt vom Screen-Code modelliert.
- Deep Links und Zielkontext müssen stabil und testbar sein.

## Regeln
- Notification-Handling nie über mehrere Screens verstreuen.
- Trust- und Session-Kontext beim Öffnen erhalten.
- Fehlerfall und Fallback-Pfade explizit testen.
