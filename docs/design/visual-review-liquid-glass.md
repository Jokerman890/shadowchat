# Visual Review: Liquid Glass Messenger UI

## Kontext

Dieser Review bewertet den gemergten Liquid-Glass-UI-Slice aus echten Android-Emulator-Screenshots gegen die Referenzrichtung aus Issue #5.

Android wurde lokal auf einer temporaeren AVD `shadowchat_visual_review` ausgefuehrt. iOS-Screenshots konnten lokal nicht erzeugt werden, weil die Maschine Windows ist und kein Xcode/iOS Simulator verfuegbar ist.

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
- Erforderliche Folgepruefung: macOS/Xcode-Simulator-Screenshotlauf fuer dieselben sechs Screens.

## Was zur Referenz passt

- Die App liest visuell klar als helle Messenger-Oberflaeche, nicht als dunkles Tech-Design.
- Pastell-Hintergruende in Lavendel, hellem Blau und Rosa sind sichtbar.
- Chat-Liste und Shell-Screens nutzen grosse, schwebende Karten mit starker Rundung.
- Avatare, Unread-Badges und aktive Akzente folgen einem Lila-Blau-Verlauf.
- Die Bottom Tab Bar wirkt weich, grossflaechig und iOS-nah.
- Chat-Liste enthaelt Avatar, Preview, Uhrzeit, Badge und Trust-Indikator.
- Conversation/Timeline enthaelt Header, Incoming-/Outgoing-Bubbles, Day Chip und Composer-Shell.
- Calls, Updates, Profile und Settings sind als vollstaendige visuelle UI-Shells vorhanden.

## Abweichungen zur Referenz

- Die Bottom Tab Bar wirkte im ersten Review noch zu textlastig, weil Android Text-Symbole statt echte Iconography renderte.
- Die Suchleiste wirkte staerker wie ein `OutlinedTextField` als wie eine vollstaendig integrierte Glasflaeche.
- Transparenz und innere Highlights waren sichtbar, aber noch nicht fein genug abgestuft; viele Cards wirkten eher weiss als wirklich glassy.
- Die Conversation-Hierarchie war funktional klar, aber noch etwas grob: Header, Messages und Composer brauchten feinere vertikale Verdichtung.
- Calls, Updates, Profile und Settings erfuellen den Shell-Scope, wirken aber noch wie generische Listen statt individuell komponierte Messenger-Screens.
- Statusbar-Kontrast war auf sehr hellem Hintergrund zu niedrig.

## Umgesetzter Visual-Polish-Slice

- Android Bottom Tab Bar nutzt jetzt gezeichnete Iconography statt Text-Symbole und eine kompaktere aktive Hervorhebung.
- Android Chat-Liste nutzt eine integrierte Glass Search Bar ohne sichtbaren Material-Default-Rahmen.
- Android und iOS Glass Panels wurden mit subtilerem Stroke, feinerem Schatten und innerem Highlight ueberarbeitet.
- Android und iOS Conversation Header wurden kompakter gefasst; Call-/Video-Actions sitzen naeher an iOS-Messenger-Pills.
- Android und iOS Composer nutzen visuell klarere Attachment-, Mic- und Send-Actions als runde Glass-/Gradient-Buttons.
- Android Systemleisten werden fuer die helle Liquid-Glass-Oberflaeche transparent und mit Light-Statusbar-/Navigationbar-Flags gesetzt.

## Verbleibende Polish-Punkte

1. Calls, Updates, Profile und Settings koennen in einem spaeteren UI-Slice noch screen-spezifischer komponiert werden.
2. iOS-Simulator-Screenshots muessen auf macOS ergaenzt und gegen Android verglichen werden.
3. Echte Icon-Bibliotheken oder Plattform-Icons sollten erst dann erweitert werden, wenn das Projekt eine klare Dependency-Entscheidung dafuer trifft.

## Bewertung

Der Visual-Polish-Slice schliesst die groessten Abweichungen aus dem ersten Screenshot-Review: weniger Material-Default-Anmutung, kompaktere Bottom Bar, feinere Glass-Materialitaet und ein besserer Messenger-Composer. Die verbleibenden Luecken sind bewusst keine Produktlogik, sondern spaetere visuelle Vertiefungen.
