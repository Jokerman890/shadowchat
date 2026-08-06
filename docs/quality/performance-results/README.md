# Versionierte Performance-Ergebnisse

Hier liegen kleine, textuelle Ergebnisprotokolle. Große Instruments- oder
ETTrace-Artefakte werden nicht eingecheckt.

Dateiname:

`YYYY-MM-DD-<plattform>-<gerät>-<flow>.md`

Pflichtangaben:

- Datum, Commit und Branch
- Plattform, Gerät, OS-Build und Xcode-/Tool-Version
- Release- oder Debug-Konfiguration
- Fixture, Accountzustand und Netzwerkprofil
- Motion-, Reduce-Motion- und Reduce-Transparency-Zustand
- Thermal State und Energieversorgung
- Anzahl der Wiederholungen
- Rohwerte sowie p50 und p95
- Vergleichsbasis und prozentuale Abweichung
- sichtbare Hitches, Speicherwachstum und Fehler
- Ablageort und SHA-256 nicht versionierter Trace-Artefakte

Vorlage:

```markdown
# <Flow> – <Datum>

- Commit:
- Branch:
- Gerät / OS-Build:
- Xcode / Tool:
- Build:
- Fixture / Netzwerk:
- Accessibility:
- Thermal State / Energie:
- Wiederholungen:

## Ergebnis

| Metrik | Rohwerte | p50 | p95 | Budget | Delta |
| --- | --- | --- | --- | --- | --- |

## Beobachtungen

## Trace-Artefakte
```
