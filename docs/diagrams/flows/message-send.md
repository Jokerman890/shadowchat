# Flow Message Send

1. Composer validiert Eingabe.
2. Nachricht wird lokal modelliert.
3. Timeline zeigt lokalen Zustand.
4. Sendepfad über Core wird ausgelöst.
5. Erfolg oder Fehler aktualisiert den Nachrichtenstatus.
6. Reaktionen und Retry-Pfade bleiben getrennt behandelbar.
