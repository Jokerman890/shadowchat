# Navigation Flow: Liquid Glass Mobile Shell

## Ziel

Dieser Slice beschreibt die lokale Shell-Navigation der Liquid-Glass-Mobile-UI. Er fuehrt keine Matrix-, Auth-, Send-, Push-, Bridge- oder Produktlogik ein.

## Scope

- Chat-Liste fuehrt lokal in die Conversation/Timeline-Shell.
- Der ausgewaehlte Demo-Raum wird nur im lokalen Shell-State gehalten.
- Es gibt keine Persistenz, keine Netzwerkzugriffe und keine echte Matrix-Raum-Navigation.
- Calls, Updates, Profile und Settings bleiben reine UI-Shells.

## Android

- `MainActivity` haelt den lokalen Shell-State fuer aktiven Tab und ausgewaehlten Raum.
- `ChatListRoute` bleibt der Einstieg fuer den Chats-Tab.
- `RoomTimelineRoute` wird weiterverwendet und erhaelt nur ein optionales `onBackRequested`.
- `BackHandler` ist nur aktiv, wenn im Chats-Tab eine Conversation offen ist.
- System-Back schliesst in diesem Zustand die Conversation und kehrt zur Chat-Liste zurueck, statt die App unerwartet zu schliessen.
- Der Timeline-Header enthaelt einen lokalen Back-Button, Avatar/Room-Symbol, Raumtitel sowie Call-/Video-Shell-Actions ohne echte Aktion.
- Tab-Wechsel setzt die lokale Conversation-Auswahl zurueck.

## iOS

- `ShadowChatRootView` nutzt `TabView` mit stabilen Tab-Tags.
- Der Chats-Tab nutzt einen nativen `NavigationStack`.
- Chat-Auswahl pusht die `RoomTimelineRoute` ueber den lokalen `NavigationPath`.
- Der native iOS-Back-Button des `NavigationStack` fuehrt von der Timeline zur Chat-Liste zurueck.
- Tab-Wechsel aus dem Chats-Tab heraus leert den lokalen Chat-Pfad.

## Motion

- Bestehende Motion-Tokens bleiben massgeblich.
- Android nutzt die vorhandenen dezenten `AnimatedContent`-Uebergaenge.
- iOS nutzt native NavigationStack-Transitions.
- Reduce Motion bleibt ueber die bestehenden Plattformsignale respektiert.

## Offene Punkte

- Spaetere echte Navigation muss an Matrix-Session- und Room-List-Contracts angebunden werden.
- Deep Links, Push-Open, Auth-Restore und Bridge-Kontexte sind eigene Slices.
- Calls, Updates, Profile und Settings benoetigen spaeter eigene Feature-Flows.
