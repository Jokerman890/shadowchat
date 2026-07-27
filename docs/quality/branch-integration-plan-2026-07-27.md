# Branch- und Integrationsplan vom 27.07.2026

## Ziel

Dieses Dokument legt den überprüfbaren Weg des iOS-Produktstands nach `main`
fest. Es ist der Abschlussnachweis für `P0-01` aus `docs/PROJECT-TODO.md`.

## Geprüfter Stand

- Ziel-Repository: `Jokerman890/shadowchat`
- Zielbranch: `main`
- Produktbranch: `codex/shadowchat-ios-product-shell`
- Geprüfter Ausgangs-Head: `084374d30e60cb0751c0c2c099ac745aa9f54677`
- Abstand zu `main`: 14 Commits voraus, 0 Commits zurück
- Pull Request: [#19 feat(ios): build ShadowChat product shell](https://github.com/Jokerman890/shadowchat/pull/19)
- PR-Status: Draft, mergefähig, keine Reviews, Kommentare oder offenen
  Review-Threads

Für den geprüften Ausgangs-Head waren Android-, iOS- und Rust-CI erfolgreich.
Nach jeder weiteren Änderung ist der neue exakte Head erneut durch diese drei
Workflows zu verifizieren.

## Entscheidung für den Produktbranch

PR #19 ist der einzige Integrationsweg für den aktuellen iOS-Produktstand.
Weitere Slice-Branches werden nicht in diesen PR hineingemischt.

Der PR darf erst aus dem Draft-Status genommen und zusammengeführt werden,
wenn:

1. Android-, iOS- und Rust-CI für den exakten Head erfolgreich sind,
2. die unabhängige fachliche und technische Review abgeschlossen ist,
3. alle Review-Kommentare aufgelöst sind,
4. keine unaufgelösten Konflikte mit `main` bestehen und
5. die Versionsangaben weiterhin mit `VERSION` übereinstimmen.

Es erfolgt kein automatisches Zusammenführen ohne diese Nachweise.

## Bewertung der Slice-Branches

### `slice/room-list-adapter-contract`

Entscheidung: nicht unverändert übernehmen; nach `P0-02` neu aufsetzen.

Begründung:

- Der Branch ist gegenüber dem Produktbranch deutlich veraltet.
- `docs/README.md` verursacht beim direkten Zusammenführen einen
  Inhaltskonflikt.
- Das neue Dokument verwendet `TD-0017`, obwohl diese Nummer im Produktbranch
  bereits durch `TD-0017-ios-product-shell.md` belegt ist.
- Der vorgeschlagene Adaptervertrag muss zuerst mit der Entscheidung aus
  `P0-02` zur dauerhaften Matrix-Core-/Adapterarchitektur abgeglichen werden.

Vorgehen:

1. PR #19 zuerst nach `main` integrieren.
2. `P0-02` abschließen.
3. Den Slice auf dem dann aktuellen `main` neu erstellen oder rebasen.
4. Das Technical Design auf die nächste freie Nummer ab `TD-0019` umbenennen.
5. Vertrag und Implementierung an die beschlossene Matrix-Architektur anpassen.

### `slice/checkly-browser-smoke-check`

Entscheidung: zurückstellen und nicht in den mobilen Produkt-PR übernehmen.

Begründung:

- Der Slice betrifft einen Browser-Smoke-Test, nicht die native
  iOS-/Android-App.
- Im Repository fehlen derzeit ein ausführbares Checkly-Paket beziehungsweise
  eine passende Projektkonfiguration.
- Die verwendete Preview-URL ist ein Platzhalter und kein überprüfbares
  Deployment-Ziel.

Der Branch ist erst neu zu bewerten, wenn ein reales Web- oder Preview-Ziel,
eine gültige Checkly-Konfiguration und ein dokumentierter Ausführungsweg
existieren.

### `slice/liquid-glass-ui-redesign`

Entscheidung: nicht erneut zusammenführen.

Begründung:

- Der Branch ist bereits Vorfahr des Produktbranches.
- Der zugehörige PR #4 wurde bereits zusammengeführt.
- Ein erneutes Merge erzeugt keinen Produktnutzen und erhöht nur das Risiko
  unnötiger Historie oder Konflikte.

Der Remote-Branch kann nach Bestätigung durch den Repository-Verantwortlichen
später gelöscht werden.

## Merge-Reihenfolge

1. Dokumentations- und Versionskorrekturen auf PR #19 veröffentlichen.
2. Android-, iOS- und Rust-CI für den exakten neuen Head abwarten.
3. PR #19 unabhängig reviewen und Review-Kommentare abarbeiten.
4. PR #19 nach erfolgreicher Abschlussprüfung nach `main` zusammenführen.
5. `P0-02` auf dem aktualisierten `main` durchführen.
6. Den Room-List-Adapter-Slice bei Bedarf neu aufsetzen.
7. Den Checkly-Slice erst mit einem realen Browser-Ziel wieder aufnehmen.

## Konfliktstrategie

- `main` wird vor der Abschlussreview in den Produktbranch aktualisiert, falls
  der Branch inzwischen zurückliegt.
- Konflikte werden fachlich pro Datei gelöst; bestehende Dokumente und
  Architekturentscheidungen werden nicht blind überschrieben.
- Doppelte ADR-/TD-Nummern werden vor dem Merge bereinigt.
- Nach jeder Konfliktlösung laufen alle drei Plattform-CI-Pfade erneut.
- Reine Branch-Aufräumarbeiten erfolgen erst nach erfolgreicher Integration
  und mit ausdrücklicher Bestätigung.

## Noch erforderlicher Abschlussnachweis

- Erfolgreiche Android-, iOS- und Rust-CI für den finalen PR-Head
- Unabhängige Review von PR #19
- Aufgelöste Review-Kommentare
- Final konfliktfreier, mergefähiger Zustand
