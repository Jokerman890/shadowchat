# TD-0003 Chat, Room List and Timeline

## Ziel
Definition der zentralen Messaging-Flows für Chat-Liste und Chat-Raum.

## Bereiche
- Room List
- Timeline
- Composer
- Message States
- Search Basis

## Anforderungen
- Room List muss schnell und stabil sein
- Timeline muss Reply, Reactions und Statuszustände sauber abbilden
- Composer bleibt eigenständige Komponente mit klaren States
- Native und externe Räume sind visuell unterscheidbar

## Kernzustände
- sending
- sent
- delivered
- read
- edited
- deleted
- external-source
- verified

## Regeln
- Lesbarkeit vor Effekten
- Motion erklärt Zustände
- Timeline-Modelle kommen aus dem Core
