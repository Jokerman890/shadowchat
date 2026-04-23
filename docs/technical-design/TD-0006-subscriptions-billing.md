# TD-0006 Subscriptions Billing

## Ziel
Technische Trennung von Billing, Store-Integrationen und produktinternen Entitlements.

## Grundsatz
Store-spezifische Billing-Flows bleiben von der Produktlogik getrennt. Die App arbeitet intern mit Entitlements und Plan-Zuständen.

## Modelle
- Free
- Pro
- Business
- Entitlement State
- Purchase State

## Regeln
- Produkt-Gating zentral modellieren.
- UI liest Entitlements, führt aber keine Geschäftslogik selbst.
- Billing-Fehler, Restore und Statuswechsel explizit behandeln.
