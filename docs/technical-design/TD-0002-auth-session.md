# TD-0002 Auth and Session

## Ziel
Saubere Anmeldung, Session-Verwaltung und spätere Multi-Account-Fähigkeit.

## Prinzipien
- OIDC / MAS als Standardpfad
- keine Singleton-Session im Architekturmodell
- Account- und Session-Daten werden logisch getrennt
- Device Trust ist sichtbar und reviewbar

## Kernobjekte
- Account
- Session
- Device
- Trust State
- Entitlement State

## Flows
1. Homeserver / Auth-Discovery
2. Login
3. Session-Erstellung
4. Device-Registrierung
5. Wiederherstellung bestehender Session
6. Logout / Geräte-Review

## Risiken
- zu frühe Vereinfachung auf Single Account
- unsaubere Persistenz von Tokens und Session-Zuständen
