# Test Strategy

## Ziel
ShadowChat braucht frühe Tests für Core, Session, Push und Chat-Flows.

## Ebenen
- Unit Tests für Domain und Mapper
- Integrationstests für Auth, Session und Timeline
- UI-Tests für Chat-Liste, Chat-Raum und wichtige Flows
- Notification- und Deep-Link-Tests

## Prioritäten
1. Login
2. Session Restore
3. Chat-Liste
4. Nachrichten senden und empfangen
5. Push-Open-Flows
6. Security Center Basis

## Qualitätsregel
Kritische Produktflüsse werden vor visuellen Extras abgesichert.

## Mobile CI Checks
- Android App-Shell und Chat-Liste:
  - `cd apps/android`
  - `./gradlew tasks`
  - `./gradlew assembleDebug`
  - `./gradlew testDebugUnitTest`
  - `./gradlew lint`
- Android Room-Timeline-Shell:
  - `cd apps/android`
  - `./gradlew :features:timeline:testDebugUnitTest`
- iOS Packages:
  - `cd apps/ios/Packages`
  - `xcodebuild -list`
  - `xcodebuild test -scheme ShadowChatMobile -destination "platform=iOS Simulator,name=<iPhone Simulator>"`
- iOS App Target:
  - `cd apps/ios`
  - `xcodebuild -list -project ShadowChat.xcodeproj`
  - `xcodebuild build -project ShadowChat.xcodeproj -scheme ShadowChat -sdk iphonesimulator -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO`
