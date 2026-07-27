# Chat Design Motion Spec

## Zielbild

ShadowChat soll sich wie ein moderner Premium-Messenger anfuehlen: hohe visuelle Qualitaet, starke Motion und klare Lesbarkeit.

Für iOS ist die visuelle und interaktive Designsprache von iOS 27 verbindliches Ziel. Dazu gehören systemnahe Navigation, Materialien, Typografie, Motion, Interaktionsfeedback und Accessibility. Das Designziel ist nicht gleichbedeutend mit einer automatischen Anhebung des Deployment Targets.

## Prinzipien

- Reading first
- Motion with purpose
- Premium calm
- Rich, fluid and responsive

## Motion als Produktmerkmal

ShadowChat verwendet bewusst viele Animationen und unterschiedliche Übergänge. Motion soll die App hochwertig, lebendig und unmittelbar wirken lassen, ohne den Nachrichteninhalt zu überdecken.

Verbindliche Einsatzbereiche:

- App-Start und Session-Wiederherstellung
- Wechsel zwischen Hauptbereichen und Tabs
- Öffnen und Schließen eines Raums
- Einfügen, Senden, Empfangen und Statuswechsel von Nachrichten
- Composer-Fokus, Anhänge und Senden
- Sheets, Dialoge und kontextbezogene Overlays
- Onboarding, Authentifizierung und Recovery
- Bridge-Pairing und Security-Center-Zustände
- Lade-, Leer-, Fehler- und Wiederverbindungszustände

Übergänge dürfen je nach Bedeutung als Fade, Scale, Materialisierung, räumliche Bewegung, Morphing oder interaktive Geste auftreten. Die Zuordnung bleibt konsistent: gleiche Zustandsarten verwenden dieselbe Motion-Sprache.

## Flüssigkeit und Reaktionsverhalten

- Animationen orientieren sich an der Bildwiederholrate des Geräts.
- Scrollen, Wischen, Texteingabe und interaktive Gesten haben Vorrang vor dekorativer Motion.
- Übergänge reagieren unmittelbar auf Eingaben und sind nach Möglichkeit unterbrechbar.
- Lange Timeline- oder Raumlistenänderungen dürfen keine vollständige Neu-Animation aller Elemente auslösen.
- Materialien, Schatten und Blur werden auf Overdraw und GPU-Kosten gemessen.
- Performance wird mit Instruments, Signposts und reproduzierbaren großen Fixtures geprüft.
- Dauerbewegung und unendliche dekorative Animationen bleiben die Ausnahme.
- Reduce Motion ersetzt räumliche oder starke Scale-Effekte durch ruhige Fades oder unmittelbare Zustandswechsel.

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
- iOS-Komponenten werden zuerst gegen das native iOS-27-Systemverhalten geprüft, bevor eigene Nachbildungen oder harte Appearance-Overrides eingesetzt werden.

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
