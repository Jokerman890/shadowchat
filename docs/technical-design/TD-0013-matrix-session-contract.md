# TD-0013 Matrix Session Contract

## Status

Akzeptiert als vorbereitender Contract-Slice. Dieser Slice dokumentiert Session-, Client- und Lifecycle-Grenzen, ohne echte Matrix-SDK-Integration zu bauen.

## Ziel

Der `Matrix Session Contract` beschreibt, welche app-eigenen Zustände, Commands, Errors und DTO-Grenzen ShadowChat braucht, bevor echte Matrix Room List / Timeline Services angebunden werden.

Der Contract ist bewusst vor der Implementierung definiert, damit Mobile UI, Rust-Core, FFI und spätere Matrix-Adapter dieselbe Sprache sprechen.

## 🚫 Nicht-Ziele

Dieser Slice führt nicht ein:

- keine echte Matrix-SDK-Integration
- kein echter Login
- kein echter Sync
- keine echten Matrix-Credentials
- keine Netzwerkzugriffe
- keine produktive Persistenz
- keine Crypto-/Encryption-Integration
- keine Push Notifications
- keine Bridge-Implementierung
- keine Send-Pipeline

## 🧩 Architekturgrenze

Die Session-Grenze liegt zwischen App-Shell/Feature-Repositories und dem späteren Rust-/Matrix-Runtime-Layer.

Mobile Plattformen dürfen nicht direkt mit `matrix-rust-sdk`-Typen arbeiten. Sie sprechen über app-eigene Contracts:

- `SessionState`
- `SessionCommand`
- `SessionEvent`
- `SessionError`
- `SessionSnapshotDto`
- `SessionCapabilityDto`

Rust-Core oder ein späterer Service-Adapter darf Matrix-nahe Typen intern nutzen, muss sie aber an der Boundary in ShadowChat-Modelle mappen.

## 🔐 Session State Model

Der Contract benötigt ein kleines, explizites Zustandsmodell:

- `notConfigured`: Es ist kein Homeserver/Auth-Kontext ausgewählt.
- `discovering`: Homeserver- oder Auth-Discovery läuft.
- `unauthenticated`: Discovery ist möglich, aber es gibt keine aktive Session.
- `authenticating`: ein Login-/Restore-Vorgang läuft.
- `restoring`: eine lokal bekannte Session wird geprüft oder wiederhergestellt.
- `active`: Session ist verwendbar; Room List / Timeline Services dürfen angefragt werden.
- `syncing`: Session ist aktiv und ein Sync-Lifecycle läuft.
- `offline`: Session existiert, aber Netzwerk/Sync ist aktuell nicht verfügbar.
- `expired`: Session existiert, aber Auth ist abgelaufen oder Refresh ist nötig.
- `locked`: Session ist vorhanden, aber Security-/Device-State blockiert Nutzung.
- `failed`: Session konnte nicht hergestellt oder wiederhergestellt werden.

`active` und `syncing` sind bewusst getrennt: UI kann eine vorhandene Session anzeigen, auch wenn Sync noch startet oder temporär pausiert.

## 🔄 Lifecycle

Der spätere Lifecycle besteht aus klaren Phasen:

1. App startet.
2. Plattform fragt `SessionSnapshot` ab.
3. Falls ein lokaler Session-Hinweis existiert, wird `restoreSession` angefordert.
4. Runtime prüft Session- und Device-State.
5. Bei Erfolg wird `active` gemeldet.
6. Room List / Timeline Services dürfen erst nach `active` starten.
7. Sync startet als separater Lifecycle und meldet `syncing`, `offline`, `expired` oder `failed`.
8. Logout beendet Sync, leert volatile Runtime-Ressourcen und meldet `unauthenticated`.

Wichtig: `restoreSession` darf keine UI-Views direkt blockieren. Mobile StateHolder/ViewModels müssen Loading-/Error-Zustände darstellen können.

## Session Commands

Commands sind Absichten der App an die spätere Runtime:

- `discoverServer(serverHint)`
- `beginLogin(authHint)`
- `completeLogin(callbackPayload)`
- `restoreSession(accountId)`
- `startSync(sessionId)`
- `pauseSync(sessionId)`
- `resumeSync(sessionId)`
- `logout(sessionId)`
- `clearLocalSession(accountId)`

Für diesen Contract bleiben Commands rein dokumentiert. Sie dürfen noch keine echten Credentials, Netzwerkaufrufe oder SDK-Calls auslösen.

## Session Events

Events beschreiben Veränderungen aus der Runtime zurück an App/Repository-Layer:

- `discoveryStarted`
- `discoveryCompleted`
- `loginStarted`
- `loginCompleted`
- `restoreStarted`
- `restoreCompleted`
- `sessionBecameActive`
- `syncStarted`
- `syncPaused`
- `syncRecovered`
- `sessionExpired`
- `sessionLocked`
- `sessionFailed`
- `loggedOut`

Mobile UI soll Events nicht roh rendern, sondern sie in Feature-State übersetzen.

## Session Error Model

Fehler müssen bewusst grober bleiben als SDK-Details, aber präziser als ein generisches `failed`:

- `networkUnavailable`
- `serverDiscoveryFailed`
- `authenticationRequired`
- `authenticationExpired`
- `restoreFailed`
- `deviceUntrusted`
- `cryptoStateUnavailable`
- `syncUnavailable`
- `rateLimited`
- `serverRejected`
- `storageUnavailable`
- `unknown`

🔐 Security-relevante Fehler wie `deviceUntrusted` oder `cryptoStateUnavailable` dürfen nicht als normale Offline-Fehler dargestellt werden.

## FFI-/DTO-Planung

Die spätere FFI-Grenze soll wertbasierte DTOs verwenden:

```text
SessionSnapshotDto
- accountId: String?
- sessionId: String?
- state: SessionStateDto
- homeserver: String?
- userDisplayName: String?
- deviceId: String?
- capabilities: [SessionCapabilityDto]
- lastSyncLabel: String?
- error: SessionErrorDto?
```

```text
SessionCapabilityDto
- roomListAvailable
- timelineAvailable
- sendAvailable
- mediaAvailable
- pushAvailable
- encryptionAvailable
```

DTOs dürfen keine Access Tokens, Refresh Tokens, Crypto Secrets oder interne Matrix-Client-Handles enthalten.

## Mapping zu Mobile

Android und iOS sollen Session-State später oberhalb der Feature-Repositories halten:

- App-Shell oder ein dedizierter Session-StateHolder kennt `SessionState`.
- `ChatListRepository` und `RoomTimelineRepository` dürfen erst über echte Adapter auf Matrix zugreifen, wenn eine aktive Session verfügbar ist.
- Feature-Views erhalten weiterhin nur ihre bisherigen UI-State-Modelle.
- Demo-Repositories bleiben als fallback/testbare Shell-Implementierung erhalten, bis echte Services angeschlossen sind.

## Mapping zu Rust

Rust-Core sollte langfristig trennen:

- `shadow_core_auth`: Auth-/Discovery-Contracts
- `shadow_core_session`: Session-State, Commands, Events, Error Model
- `shadow_core_rooms`: Room List Service Contract
- `shadow_core_timeline`: Timeline Service Contract

Der bestehende `SessionStore` ist nur ein Stub. Er ist nicht der finale Session Runtime Store und darf nicht als Singleton-Architektur missverstanden werden.

## 📌 Entscheidungen

- Session-State wird vor Room List und Timeline modelliert.
- Mobile UI sieht keine rohen Matrix-SDK-Typen.
- Session-Commands und Events werden als app-eigene Boundary-Sprache dokumentiert.
- FFI-DTOs enthalten keine Secrets.
- Sync ist ein separater Lifecycle nach erfolgreichem Session-Restore.

## ⚠️ Risiken

- Zu frühe SDK-Anbindung könnte Matrix-Details in Mobile UI und Feature-Repositories leaken.
- Ein zu grobes Error Model würde Security-, Auth- und Offline-Zustände vermischen.
- Ein impliziter Single-Account-Store würde spätere Multi-Account-Fähigkeit erschweren.
- FFI-Streaming ohne klare Cancellation-Regeln kann Mobile-Lifecycle-Probleme erzeugen.

## ✅ Akzeptanzkriterien für spätere Implementierung

- Session-State ist testbar ohne echte Matrix-Credentials.
- Room List und Timeline starten erst nach einem aktiven Session-State.
- Auth-expired, offline und device-untrusted werden unterscheidbar modelliert.
- DTOs enthalten keine Secrets und keine SDK-internen Handles.
- Mobile Feature-Views bleiben unabhängig vom Session-Runtime-Layer.

## 🧪 Validierung

Für diesen Dokumentationsslice:

- `git diff --check`
- `cargo fmt --all --check`
- `cargo test --workspace`

Für spätere Implementierungsslices zusätzlich:

- Android `assembleDebug`, `testDebugUnitTest`, `lint`
- iOS `swift test` und `xcodebuild build` auf macOS
- Contract-Mapping-Tests für Session-State und Error Mapping

## Nächster sinnvoller Slice

Der nächste technische Slice sollte `Core Domain Contract Alignment` sein. Dabei werden die in diesem Dokument beschriebenen Session-State-, Command-, Event- und Error-Typen als Rust-/Contract-Modelle vorbereitet, weiterhin ohne echte Matrix-SDK-Live-Anbindung.
