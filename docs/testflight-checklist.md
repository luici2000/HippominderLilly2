# Hippominder – TestFlight / Beta-Test Checkliste

## Voraussetzungen

- [x] Apple Developer Account (Team: H5FBB5BQB6)
- [x] Bundle ID: com.roboterwerk.HippominderLilly2
- [x] App Icon vorhanden
- [x] Privacy Policy URL: https://luici2000.github.io/HippominderLilly2/privacy-policy.html
- [x] Support URL: https://luici2000.github.io/HippominderLilly2/support.html
- [ ] GitHub Pages aktivieren (Settings > Pages > /docs)

---

## Schritt-fuer-Schritt: TestFlight Upload

### 1. Xcode vorbereiten
```
1. Xcode oeffnen > HippominderLilly2.xcodeproj
2. Target "HippominderLilly2" waehlen
3. Signing & Capabilities:
   - Team: H5FBB5BQB6 (Mathias Hubrich)
   - Bundle ID: com.roboterwerk.HippominderLilly2
   - Automatic Signing: An
4. Build-Nummer erhoehen (z.B. 1 → 2)
5. Version: 2.0.0
```

### 2. Archive erstellen
```
1. Schema auf "Any iOS Device (arm64)" aendern
2. Product > Archive
3. Warten bis Build abgeschlossen ist
4. Organizer oeffnet sich automatisch
```

### 3. App Store Connect Upload
```
1. Im Organizer: "Distribute App" klicken
2. "App Store Connect" waehlen
3. "Upload" waehlen (nicht "Export")
4. Automatic Signing waehlen
5. Upload starten
6. Warten bis Upload abgeschlossen (~2-5 Min.)
```

### 4. App Store Connect konfigurieren
```
1. https://appstoreconnect.apple.com oeffnen
2. "Meine Apps" > Hippominder
3. Falls noch nicht angelegt: "+ Neue App"
   - Plattform: iOS
   - Name: Hippominder
   - Primaere Sprache: Deutsch
   - Bundle ID: com.roboterwerk.HippominderLilly2
   - SKU: hippominder-lilly2
```

### 5. TestFlight einrichten
```
1. App Store Connect > Hippominder > TestFlight
2. Der Upload erscheint nach einigen Minuten unter "Builds"
3. "Internes Testen" > Gruppe erstellen ("Familie")
4. Tester per Apple-ID/E-Mail einladen
5. Build der Gruppe zuweisen
6. Tester erhalten Einladung per E-Mail
```

### 6. Beta-App-Informationen
```
- Beta App Description:
  "Hippominder - Pferde-Termin App (Beta).
   Bitte teste die App und gib Feedback zur Bedienung,
   Blumen-Anzeige und allen Funktionen.
   Debug: 5x auf das Logo tippen fuer versteckte Optionen."

- Feedback E-Mail: support@roboterwerk.de
- Demo Account: nicht erforderlich (keine Anmeldung)
```

---

## Beta-Test Plan

### Testgruppe: Familie & Freunde (5-10 Personen)

#### Tester-Checkliste
Jeder Tester sollte folgendes pruefen:

**Grundfunktionen:**
- [ ] App startet ohne Absturz
- [ ] Pferd anlegen (Name + Foto)
- [ ] Intervalle aendern (+/- Buttons und direkte Eingabe)
- [ ] Datum aendern
- [ ] Termin bestaetigen
- [ ] Blumen-Timer Anzeige korrekt
- [ ] Farbschema wechseln (3 Farben)
- [ ] Kontakte anlegen

**Pro-Features:**
- [ ] 2. Pferd anlegen → Paywall erscheint
- [ ] Kauf-Dialog korrekt (Sandbox-Modus)
- [ ] Nach Kauf: Unbegrenzte Pferde moeglich

**Lokalisierung:**
- [ ] App auf Englisch testen (iPhone-Sprache wechseln)
- [ ] App auf Spanisch testen
- [ ] App auf Franzoesisch testen

**Benachrichtigungen:**
- [ ] Push-Berechtigung wird angefragt
- [ ] Erinnerung kommt korrekt (Debug: Zeit vorspulen)

**E-Mail:**
- [ ] E-Mail-Vorlage wird korrekt erstellt
- [ ] Kontaktdaten werden eingesetzt

**Edge Cases:**
- [ ] Pferd ohne Foto anlegen
- [ ] Sehr lange Pferdennamen
- [ ] Intervall auf 1 Tag setzen
- [ ] Datum weit in der Vergangenheit
- [ ] App beenden und neu starten → Daten erhalten?
- [ ] Dark Mode
- [ ] Verschiedene iPhone-Groessen

**Debug (versteckter Zugang):**
- [ ] 5x Logo tippen → Beta-Info erscheint
- [ ] Zeitsimulation funktioniert
- [ ] Zeit zuruecksetzen funktioniert

---

## Feedback sammeln

### Feedback-Formular (an Tester senden)

```
Hallo [Name]!

Danke, dass du Hippominder testest! Bitte gib mir kurz Feedback:

1. Wie findest du die Blumen-Anzeige? (Verstaendlich? Schoen?)
2. Ist die Bedienung intuitiv?
3. Fehlt dir eine Funktion?
4. Gab es Abstuerze oder Fehler?
5. Wuerdest du die App weiterempfehlen?
6. Was wuerdest du verbessern?

Geheimtipp: 5x auf das Logo tippen fuer Debug-Modus!

Danke! 🐴
Mathias
```

---

## Bekannte Einschraenkungen (Beta)

1. **In-App-Kauf:** Funktioniert nur im Sandbox-Modus waehrend TestFlight
2. **Benachrichtigungen:** Muessen manuell erlaubt werden
3. **Kalender-Integration:** Noch nicht implementiert (nur Platzhalter im App Store Text)
4. **Fotos:** Erfordern Foto-Berechtigung beim ersten Zugriff

---

## Nach dem Beta-Test

1. Feedback auswerten
2. Kritische Bugs fixen
3. UI-Verbesserungen basierend auf Feedback
4. Version 2.0.1 mit Fixes uploaden
5. App Store Review einreichen
