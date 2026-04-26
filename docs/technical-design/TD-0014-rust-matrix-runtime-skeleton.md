# TD-0014 Rust Matrix Runtime Skeleton

## Status

Akzeptiert als minimaler Rust/Core-Skeleton-Slice. Dieser Slice baut keine echte Matrix-SDK-Live-Integration.

## Ziel

Das neue Crate `shadow_core_runtime` legt die Contract-Grundlage fuer eine spaetere Matrix Session Runtime. Es enthaelt nur Rust-Typen, Traits, DTOs, Commands, Events, Error-Kategorien und eine testbare No-op-Referenz.

## 🦀 Rust/Core Umfang

Neu im Rust-Workspace:

- `crates/shadow_core_runtime`
- `SessionState`
- `SessionCommand`
- `SessionEvent`
- `SessionErrorKind`
- `SessionRuntimeError`
- `SessionSnapshot`
- `SessionCapability`
- `MatrixSessionRuntime`
- `NoopMatrixSessionRuntime`

Das Crate haengt nur an bestehenden Workspace-Dependencies und an `shadow_core_domain`. Es fuegt bewusst kein `matrix-rust-sdk` hinzu.

## 🧩 Architektur

`shadow_core_runtime` sitzt zwischen zukuenftigen Matrix-Adaptern und den bereits dokumentierten Mobile-/FFI-Boundaries.

Die Struktur ist bewusst klein:

- `command.rs`: app-eigene Session-Commands
- `state.rs`: Session-State und Runtime-Events
- `dto.rs`: wertbasierte Snapshot-/Capability-DTOs
- `error.rs`: Session-Error-Kategorien und Runtime-Fehler
- `runtime.rs`: Runtime-Trait und No-op-Skeleton

`NoopMatrixSessionRuntime` ist keine produktive Runtime. Es ist eine deterministische Referenz fuer Contract-Tests.

## 🔐 Session / Sicherheit

`SessionSnapshot` enthaelt keine Secrets:

- keine Access Tokens
- keine Refresh Tokens
- keine Crypto Secrets
- keine SDK-internen Client-Handles

Security-relevante Fehler bleiben explizit modelliert, z. B. `DeviceUntrusted` und `CryptoStateUnavailable`.

## 🔄 Lifecycle

Das Skeleton kann folgende lokale State-Uebergaenge ausdruecken:

- `NotConfigured`
- `Discovering`
- `Authenticating`
- `Active`
- `Syncing`
- `Unauthenticated`

Diese Uebergaenge loesen keine Netzwerkzugriffe aus. `StartSync` prueft nur, ob die angefragte `MatrixSessionId` zur lokalen Skeleton-Session passt.

## 🚫 Nicht-Ziele

- keine echte Matrix-SDK-Integration
- kein `matrix-rust-sdk` als Dependency
- kein echter Login
- kein echter Sync
- keine Netzwerkzugriffe
- keine produktive Persistenz
- keine echten Matrix-Credentials
- keine Crypto-/Encryption-Integration
- keine Push Notifications
- keine Bridge-Implementierung
- keine Send-Pipeline

## ✅ Akzeptanzkriterien

- Das neue Crate ist im Rust-Workspace eingebunden.
- Commands, States, Events und DTOs sind app-eigene Rust-Typen.
- Es gibt ein Runtime-Trait fuer spaetere Adapter.
- Es gibt Tests fuer initialen Snapshot, Restore-Skeleton und Session-ID-Pruefung.
- Es gibt keine neue Matrix-SDK-Dependency.

## 🧪 Validierung

Fuer diesen Slice:

- `cargo fmt --all --check`
- `cargo test --workspace`
- `git diff --check`

## ⚠️ Risiken

- Das Skeleton darf nicht als fertige Matrix-Runtime missverstanden werden.
- Der No-op-Restore erzeugt nur eine lokale Skeleton-Session-ID und keine echte Session.
- Streaming, Cancellation, FFI-Memory-Ownership und echte Error-Mappings muessen in spaeteren Slices konkretisiert werden.

## Naechster sinnvoller Slice

Der naechste Slice sollte die `Core Domain Contract Alignment`-Arbeit starten: Session-, Room-List- und Timeline-Domain-Modelle zwischen `core/contracts`, Rust-Crates und Mobile-Repositories angleichen, weiterhin ohne echte Matrix-SDK-Live-Anbindung.
