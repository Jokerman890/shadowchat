# Chat Design Motion Spec

## Zielbild

ShadowChat soll sich wie ein moderner Premium-Messenger anfuehlen: hohe visuelle Qualitaet, starke Motion und klare Lesbarkeit.

## Prinzipien

- Reading first
- Motion with purpose
- Premium calm

## Kernbereiche

- Chat-Liste
- Chat-Raum
- Composer
- Search
- Media Viewer

## Motion-Regeln

- Animation erklaert Fokus und Status.
- Keine hektische Dauerbewegung.
- Listen bleiben ruhig und performant.
- Reduce Motion ist Pflicht.
- Interaktionsfeedback nutzt kurze Press-Scale- oder Fade-Uebergaenge statt dekorativer Dauerbewegung.
- Screen- und Room-Uebergaenge bleiben unter ca. 250 ms und duerfen Lesefluss nicht stoeren.
- Wenn Reduce Motion aktiv ist, fallen Uebergaenge auf sofortige Zustandswechsel zurueck.

## Chat-Liste

- Sanfte Zellen-Transitions.
- Klare Unread-Badges.
- Typing-Zustaende weich statt hektisch.
- Helle Glas-Cards auf Pastell-Hintergrund.
- Trust-Indikatoren bleiben sichtbar, aber nicht aggressiv.

## Chat-Raum

- Neue Nachrichten mit leichter Materialisierung.
- Reply und Reactions mit kurzen Uebergaengen.
- Composer als schwebende Oberflaeche.
- Incoming- und Outgoing-Bubbles nutzen helle, abgesetzte Liquid-Glass-nahe Flaechen.

## Mobile App Shell

- Bottom Navigation hostet die vorhandenen Hauptbereiche als Shell.
- Chats bleibt der Startbereich.
- Calls, Updates, Profile und Settings sind visuelle Shells ohne Produktlogik, bis eigene Slices folgen.
- Tab-Wechsel nutzen ruhige Fade-/Scale-Uebergaenge; Hauptinhalt bleibt stabil und lesbar.
