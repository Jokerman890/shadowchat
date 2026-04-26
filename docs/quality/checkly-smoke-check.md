# Checkly Browser Smoke Check

## Ziel

Der Browser-Smoke-Check prueft spaeter eine Web-/Preview-URL von ShadowChat auf grundlegende Erreichbarkeit und Metadaten. Er veraendert keine Produktlogik und ist nicht an Mobile-, Matrix-, Auth-, Sync- oder FFI-Code gekoppelt.

## Datei

- `checks/browser/smoke.spec.js`

## Erwartete Umgebung

Der Check nutzt:

- `ENVIRONMENT_URL`
- alternativ `BASE_URL`

Wenn keine der Variablen gesetzt ist, verwendet der Test nur eine Platzhalter-URL:

```text
https://shadowchat-preview.example.invalid
```

Diese Adresse ist bewusst keine produktive URL. Checkly oder CI muss spaeter eine echte Preview-URL setzen.

## Gepruefte Punkte

- initialer HTTP-Status ist kleiner als `400`
- Seitentitel enthaelt `ShadowChat` oder `Shadow Chat`
- `meta[name="description"]` existiert und ist nicht leer
- OpenGraph-Tags `og:title`, `og:description` und `og:url` existieren und sind nicht leer
- `body` ist sichtbar und enthaelt Text
- offensichtliche Fehlerseiten wie `404`, `Not Found`, `Application Error` oder `Internal Server Error` werden erkannt

## Spaetere Checkly-Einbindung

Aktuell existiert keine `checkly.config.ts`. Deshalb wird noch keine vollstaendige Checkly-Projektstruktur angelegt.

Sobald Checkly konfiguriert wird, sollte der Check als Browser Check eingebunden und mit einer echten Preview-URL versorgt werden. Die bestehende Testdatei kann dafuer direkt referenziert werden.

## Lokale Ausfuehrung

Falls ein Node-/Playwright-Setup ergaenzt wird:

```powershell
$env:BASE_URL = "https://example-preview-url"
npx playwright test checks/browser/smoke.spec.js
```

Dieser Slice fuehrt kein neues Node-Setup und keine neuen Dependencies ein.
