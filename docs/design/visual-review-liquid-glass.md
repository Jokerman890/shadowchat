# Visual Review: Liquid Glass Messenger UI

## Kontext

Dieser Review bewertet den gemergten Liquid-Glass-UI-Slice aus echten Android-Emulator-Screenshots gegen die Referenzrichtung aus Issue #5.

Android wurde lokal auf einer temporären AVD `shadowchat_visual_review` ausgeführt. iOS-Screenshots konnten lokal nicht erzeugt werden, weil die Maschine Windows ist und kein Xcode/iOS Simulator verfügbar ist.

## Artefakte

### Android

- [Chats](screenshots/android/chats.png)
- [Conversation / Timeline](screenshots/android/conversation.png)
- [Calls](screenshots/android/calls.png)
- [Updates](screenshots/android/updates.png)
- [Profile](screenshots/android/profile.png)
- [Settings](screenshots/android/settings.png)

### iOS

- Keine lokalen iOS-Screenshots erzeugt.
- Erforderliche Folgeprüfung: macOS/Xcode-Simulator-Screenshotlauf für dieselben sechs Screens.

## Was zur Referenz passt

- Die App liest visuell klar als helle Messenger-Oberfläche, nicht als dunkles Tech-Design.
- Pastell-Hintergründe in Lavendel, hellem Blau und Rosa sind sichtbar.
- Chat-Liste und Shell-Screens nutzen große, schwebende Karten mit starker Rundung.
- Avatare, Unread-Badges und aktive Akzente folgen einem Lila-Blau-Verlauf.
- Die Bottom Tab Bar wirkt weich, großflächig und iOS-nah.
- Chat-Liste enthält Avatar, Preview, Uhrzeit, Badge und Trust-Indikator.
- Conversation/Timeline enthält Header, Incoming-/Outgoing-Bubbles, Day Chip und Composer-Shell.
- Calls, Updates, Profile und Settings sind als vollständige visuelle UI-Shells vorhanden.

## Abweichungen zur Referenz

- Die Bottom Tab Bar wirkt noch zu textlastig, weil Android aktuell Text-Symbole statt echte Iconography rendert.
- Die Suchleiste wirkt stärker wie ein `OutlinedTextField` als wie eine vollständig integrierte Glasfläche.
- Transparenz und innere Highlights sind sichtbar, aber noch nicht fein genug abgestuft; viele Cards wirken eher weiß als wirklich glassy.
- Die Conversation-Hierarchie ist funktional klar, aber noch etwas grob: Header, Messages und Composer brauchen feinere vertikale Verdichtung.
- Calls, Updates, Profile und Settings erfüllen den Shell-Scope, wirken aber noch wie generische Listen statt individuell komponierte Messenger-Screens.
- Statusbar-Kontrast ist auf sehr hellem Hintergrund zu niedrig.

## Konkrete Polish-Punkte für den nächsten Slice

1. Bottom Tab Bar auf echte Icons umstellen und aktive Tab-Hervorhebung kompakter gestalten.
2. Search Bar als eigene `ShadowGlassSearchBar` / SwiftUI-Äquivalent bauen, ohne sichtbaren Material-Default-Rahmen.
3. Glass Cards mit subtilerem Stroke, innerem Highlight und differenzierterem Schattenmodell verfeinern.
4. Conversation Header kompakter machen und Avatar/Call/Video-Actions stärker wie iOS Messenger ausrichten.
5. Composer visuell näher an WhatsApp/iOS bringen: Attachment-, Mic- und Send-Actions als Glass Icon Buttons.
6. Calls/Updates/Profile/Settings je Screen mit eigener visueller Struktur polishen, nicht nur generische Rows.
7. Statusbar/Safe-Area-Kontrast prüfen und helle Systemleisten konsistent setzen.
8. iOS-Simulator-Screenshots ergänzen und gegen Android vergleichen, um native Plattformunterschiede bewusst zu halten.

## Bewertung

Der Slice trifft die geforderte Richtung deutlich: hell, pastellig, rund, weich und Messenger-nah. Die größten verbleibenden Lücken liegen nicht in der Architektur, sondern im visuellen Feinschliff: echte Icons, weniger Material-Default-Anmutung bei Suchleiste und Bottom Bar, feinere Glass-Materialität und eine stärkere screen-spezifische Komposition der Nicht-Chat-Tabs.
