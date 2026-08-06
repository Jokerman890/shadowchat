# TD-0015 FFI DTO Surface

## Status

Akzeptiert als vorbereitender Rust/Core-Slice. Dieser Slice definiert eine FFI-/DTO-Surface, erzeugt aber keine Android-/iOS-Bindings.

Durch ADR-0016 als nicht angebundener Contract-Prototyp eingeordnet. Für
Session-, Room-List- oder Timeline-Laufzeit werden vorerst keine Mobile-Bindings
erzeugt. Die Typen dürfen später nur für grobgranulare, pure Core-Funktionen
weiterverwendet werden.

## Ziel

Die FFI-/DTO-Surface macht Session State, Session Error, Session Snapshot und Session Command fuer spaetere mobile Bindings stabiler. Sie bleibt Rust-seitig und mappt zwischen internen `shadow_core_runtime`-Typen und stringnahen DTO-Typen.

## 🔗 FFI/DTO Boundary

Neu im Crate `shadow_core_runtime`:

- `FfiSessionSnapshot`
- `FfiSessionCommand`
- `FfiSessionState`
- `FfiSessionEvent`
- `FfiSessionErrorKind`
- `FfiSessionCapability`

Diese Typen liegen in `src/ffi.rs` und werden aus `lib.rs` exportiert. Sie sind wertbasiert, `serde`-serialisierbar und enthalten keine Matrix-SDK-Handles.

## 🦀 Rust/Core Mapping

Die DTO-Surface mappt explizit:

- `SessionSnapshot` <-> `FfiSessionSnapshot`
- `SessionCommand` <-> `FfiSessionCommand`
- `SessionState` <-> `FfiSessionState`
- `SessionEvent` <-> `FfiSessionEvent`
- `SessionErrorKind` <-> `FfiSessionErrorKind`
- `SessionCapability` <-> `FfiSessionCapability`

IDs und URLs werden an der FFI-Grenze als `String` transportiert:

- `AccountId`
- `MatrixSessionId`
- `HomeserverUrl`
- `DeviceId`

Damit bleibt die mobile Seite frei von Rust-Newtype-Details, ohne die internen Core-Typen aufzugeben.

## Historischer Prototyp-Datenfluss

```text
Mobile Binding
  -> FfiSessionCommand
  -> SessionCommand
  -> MatrixSessionRuntime
  -> SessionSnapshot / SessionEvent
  -> FfiSessionSnapshot / FfiSessionEvent
  -> Mobile Binding
```

Der Datenfluss endet im `NoopMatrixSessionRuntime` und ist in keiner Mobile-App
angebunden. Er ist ausdrücklich nicht der Zielpfad für Matrix-Live-Daten.

## 🚫 Nicht-Ziele

- keine echte Matrix-SDK-Integration
- keine Android-/iOS-Binding-Generierung
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

- FFI-DTOs sind vom internen Runtime-Modell getrennt.
- Mapping ist explizit und testbar.
- DTOs enthalten keine Secrets und keine SDK-internen Handles.
- Security-relevante Fehler wie `DeviceUntrusted` bleiben sichtbar.
- Es wird keine neue Matrix-SDK-Dependency eingefuehrt.

## 🧪 Validierung

Fuer diesen Slice:

- `cargo fmt --all --check`
- `cargo test --workspace`
- `git diff --check`

Neue Tests pruefen:

- Snapshot-Mapping bleibt wertbasiert.
- Command-Mapping erhaelt String-Payloads.
- Security-relevante Error-Kategorien bleiben explizit.

## ⚠️ Risiken

- Die DTOs sind noch keine stabil generierten Bindings fuer Swift/Kotlin.
- Enum-Namen muessen vor einer Binding-Generator-Entscheidung erneut gegen Generator-Konventionen geprueft werden.
- Streaming, Cancellation und Memory Ownership sind weiterhin eigene FFI-Slices.

## Naechster sinnvoller Slice

Vor jeder Binding-Generator-Entscheidung wird zuerst festgelegt, welche pure
Core-Policy den zusätzlichen Binding-Aufwand rechtfertigt. Room-List- und
Timeline-Diffs bleiben in den Plattformadaptern.
