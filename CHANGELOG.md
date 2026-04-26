# Changelog

Alle relevanten Aenderungen an ShadowChat werden in dieser Datei dokumentiert.

Das Format orientiert sich an "Keep a Changelog"; die Produktversion folgt `MAJOR.MINOR.PATCH` gemaess `docs/technical-design/TD-0010-versioning.md`.

## [Unreleased]

### Added

- Mobile App-Shell fuer Android und iOS mit Chat-Liste als Startscreen.
- Room Timeline Shell fuer Android und iOS ohne Matrix-Live-Anbindung.
- Helle Liquid-Glass-Messenger-UI fuer Chat-Liste, Timeline und Shell-Tabs.
- Visueller Screenshot-Review fuer die Android Liquid-Glass-UI.
- Visual-Polish-Slice fuer Bottom Bar, Glass Search Bar, Timeline Header, Composer und Glass Panels.
- Matrix-Integration-Readiness-Audit fuer Mobile-, Rust-, FFI-, Repository- und Demo-Data-Grenzen.
- Matrix Session Contract fuer Session-/Client-Lifecycle, Commands, Events, Errors und FFI-/DTO-Grenzen.
- Rust Matrix Runtime Skeleton mit app-eigenen Session-Commands, States, Events, DTOs, Errors und No-op-Tests.
- FFI-/DTO-Surface fuer Session Snapshot, Commands, States, Events, Errors und Capabilities im Rust Runtime Crate.
- Mobile Repository Swap Boundary fuer Android und iOS, damit Demo-Repositories spaeter gegen FFI-backed Repositories getauscht werden koennen.
- Room List Adapter Contract fuer Rust/Core und Mobile-Mapping-Modelle als Vorbereitung auf spaetere Matrix Room List Integration.

### Changed

- Android, iOS und Rust CI sind als zentrale Validierungspfade fuer mobile Slices etabliert.
- Mobile UI-Dokumentation beschreibt die verbleibenden visuellen Polish-Punkte.
- Motion- und Interaktionsverhalten fuer Mobile Shell, Chat-Liste und Timeline wurde mit kurzen, Reduce-Motion-bewussten Uebergaengen verfeinert.
- Lokale Shell-Navigation zwischen Chat-Liste und Timeline wurde fuer Android und iOS plattformnaeher gepolisht.
- Runtime-Demo-Daten und lokale InMemory-Repositories der Mobile App-Shell wurden fuer Android und iOS gekapselt.

### Known Gaps

- iOS-Simulator-Screenshots muessen weiterhin auf macOS ergaenzt werden.
- Matrix-, Auth-, Send-, Push- und Bridge-Integration sind noch nicht Teil der mobilen UI-Slices.

## [0.1.0] - unreleased

### Added

- Initiale Repo-Version fuer den ShadowChat MVP-Aufbau.
