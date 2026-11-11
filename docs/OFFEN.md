# Offene Punkte

Arbeitsliste zwischen den Sitzungen. Die Cloud-Sitzung kann lesen,
messen und schreiben, aber nicht bauen — alles mit **[Build]** kann nur
eine Sitzung auf dem Mac erledigen.

Erledigtes bitte abhaken statt löschen, dann sieht man, was schon geprüft
wurde.

---

## Zuerst: ist überhaupt baubar?

- [x] **[Build]** Baut das Projekt? Ja — am 10.11.2026 mit Xcode 27.1 für
      das echte iPhone (blackiPhone_14, iOS 27.2) gebaut, 0 Fehler,
      0 Warnungen, und als 3.1.0 (2) installiert. Simulator iPhone 16e
      noch nicht geprüft.
- [x] **[Build]** Läuft `⌘U`? Ja, seit 10.11.2026: 12 Tests in
      `FlowerGeometryTests`, 0 Fehler, auf dem Simulator iPhone 16e. Drei
      Dinge waren falsch verdrahtet: `TEST_HOST` zeigte noch auf
      `HippominderLilly2.app` (das Produkt heißt `Hippominder.app`), der
      Test importierte das Modul `HippominderLilly2` (heißt jetzt
      `Hippominder`), und es gab kein geteiltes Schema mit den Tests —
      liegt jetzt in `xcshareddata/xcschemes/HippominderLilly2.xcscheme`.
- [x] **[Build]** Baut auch das Watch-Target? Ja, 10.11.2026 für
      `generic/platform=watchOS`, 0 Fehler. Auf einer echten Uhr noch nicht
      installiert.

## Dann: sieht es richtig aus?

- [ ] **[Build]** Alle drei Darstellungen im Simulator ansehen: Glas,
      Classic, Blume. Umschalter sitzt in der Pferde-Detailansicht.
- [ ] **[Build]** Mit einem echten Pferdefoto prüfen, ob das Glas gut
      aussieht — bisher nur mit einem gemalten Platzhalter getestet.
- [ ] **[Build]** Mini-Blumen in der Pferdeliste: sind die zwölf Blätter
      auf dem Gerät noch zählbar? Am Rechner war 30 pt die Untergrenze.
- [ ] **[Build]** Uhr ansehen. Dort ist die Blume neu, vorher waren es
      Ampelpunkte und ein Balken. Layout wurde bei 162–205 pt gerendert
      geprüft und passt, auch auf der 40 mm.
      **Stand 11.11.2026:** Erledigt — die Ultra 2 („Apple Watch von
      Mathias", watchOS 27.2) ist mit Xcode gekoppelt, im Profil
      registriert, und die Watch-App 3.1.0 (2) läuft darauf. Die
      Watch-App ist zudem in die iPhone-App eingebettet („Embed Watch
      Content", nur iOS).
      Was die Kopplung am Ende brauchte: **Xcode 27.2** (mit 27.1 sah die
      Uhr den Mac, baute aber nie eine Verbindung auf), Device Hub →
      „Pair Nearby Device…", Bluetooth am iPhone aus (sonst nutzt die Uhr
      ihr WLAN nicht), dann auf der Uhr Entwicklermodus → „Andere Geräte"
      → Mathias-MacBook, Code vom Mac eingeben. Fritz!Box, Firewall,
      Mac-Hotspot: alles geprüft, alles unschuldig.
      Installation: `xcrun devicectl device install app --device
      00008310-00143CE02E10E01E …/HippominderWatch.app`.
- [ ] **[Build, wichtig]** „War heute da" auf der Uhr testen. Der Rückkanal
      Uhr → iPhone ist **neu und noch nie gelaufen**. Zu prüfen:
      1. Termin auf der Uhr abhaken, während das iPhone in der Nähe ist →
         kommt er im iPhone an?
      2. Dasselbe mit iPhone außer Reichweite (Flugmodus), danach wieder
         verbinden → wird die Meldung nachgereicht? Das läuft über
         `transferUserInfo` und ist der eigentliche Stallfall.
      3. Läuft keine Schleife? iPhone antwortet mit `syncToWatch`, die Uhr
         darf darauf nicht erneut melden.

- [x] **[Build]** Überfällige Erinnerungen geprüft, 11.11.2026 im
      Simulator iPhone 16e mit `-demoDaysAgo 50,200,100 -dumpNotifications`:
      1. Drei Termine überfällig → genau drei geplante Meldungen
         `…-ueberfaellig`, alle für den nächsten Morgen 09:00 (wöchentlich
         wiederholend, keine doppelte Einmalmeldung).
      2. Termine eingetragen (`-demoDaysAgo 0,0,0`) → die drei
         Überfällig-Meldungen sind weg, stattdessen drei reguläre
         „in 3 Tagen fällig" am 20.12.2026, 06.02.2027 und 07.05.2027,
         jeweils 09:00 Ortszeit. Nachgerechnet, stimmt.
      Der Debug-Dump schreibt jetzt per `NSLog` ins Systemprotokoll
      (`log show --predicate 'process == "Hippominder"'`), `print` kam dort
      nicht an.

- [x] **[Build]** Wechselndes App-Symbol geprüft, 11.11.2026 im Simulator:
      überfällig → Symbol rot (Protokoll: „Setting preferredIconName to
      Ueberfaellig"), Termine eingetragen → wieder orange („preferredIconName
      to (null)"). Beides im Home-Bildschirm gesehen. Punkt 3 (kein Hinweis
      bei unverändertem Zustand) am echten iPhone noch offen.
      4. ~~Liegen `AppIcon-Ueberfaellig@2x/@3x.png` wirklich flach im Bundle?~~
         Ja, 10.11.2026 im gebauten `Hippominder.app` nachgesehen: alle drei
         liegen direkt im Bundle.

- [ ] **[Build]** iPad-Layout prüfen. Auf dem iPad läuft jetzt eine
      zweispaltige Ansicht (Liste links, Pferd rechts), auf dem iPhone
      unverändert der bisherige Stapel. Zu prüfen:
      1. ~~iPad: Pferd antippen → erscheint es rechts?~~ Ja, 11.11.2026 im
         iPad-Simulator (A16) quer gesehen: Liste links, Pferd rechts, die
         Blume in allen drei Spalten vollständig. Hochkant zeigt iPadOS
         nur die rechte Spalte mit Seitenleisten-Knopf, das ist Systemverhalten.
      2. iPad: Pferd löschen, das gerade rechts steht → leert sich die
         rechte Spalte, oder zeigt sie ein gelöschtes Tier?
      3. iPhone: Navigation muss **genau wie vorher** funktionieren —
         der Zweig ist unverändert, aber der Umbau war invasiv.
      4. Quer/Hochformat und Splitscreen auf dem iPad.

- [ ] **[Build, wichtig]** iCloud-Abgleich in Betrieb nehmen. Die Pferde
      liegen jetzt in iCloud statt nur auf dem Gerät. **Vor dem ersten
      Start mit den echten Daten:**
      1. ~~In Xcode unter *Signing & Capabilities* **iCloud** hinzufügen~~
         Erledigt 10.11.2026: das automatische Profil enthält den
         Container `iCloud.com.roboterwerk.HippominderLilly2`, CloudKit
         und `aps-environment`; die signierte App trägt alle drei.
      2. ~~**Background Modes → Remote notifications**~~ — steckt in
         denselben Entitlements, siehe 1.
      3. ~~Erst auf einem Testgerät prüfen, dass vorhandene Pferde die
         Umstellung überstehen~~ — 10.11.2026 auf blackiPhone_14: Bina hat
         die Migration von 3.0.0 (1) auf 3.1.0 (2) überstanden, mit Foto und
         Intervallen. CloudKit-Einrichtung, Import und Export liefen beim
         ersten Start fehlerfrei, Bina hat einen iCloud-Datensatz.
      4. Dann auf zwei Geräten: Pferd auf dem Mac anlegen → erscheint es
         auf dem iPhone?
      5. iCloud testweise abschalten → läuft die App weiter (lokal)?

## Neu seit 11.11.2026 (Mathias, nach dem ersten Blick auf die Uhr)

- [ ] **Optik der Watch-App überarbeiten.** Mathias: „mit der Optik müssen
      wir was machen". Was genau stört, ist noch nicht benannt — erst
      Screenshots aus dem Simulator und von der Uhr nebeneinanderlegen,
      dann entscheiden.
- [ ] **Nebenprojekt: Zifferblatt im Classic-LCD-Stil.** Eigene Zifferblätter
      lässt Apple nicht zu, aber eine Watch-App mit Uhrzeit im Stil des
      graugrünen Gerätedisplays (plus Komplikation) geht. Idee notiert,
      nicht begonnen.

## Akku der Uhr

Mathias meldete am 11.11.2026 starken Akkuverbrauch. Zwei Ursachen
gefunden und abgestellt, eine bleibt zu messen:

- [x] **Milchglas auf der Uhr.** Jedes der zwölf Blätter lag auf
      `.ultraThinMaterial`. Ein Material verwischt bei jedem Bild, was
      dahinterliegt — auf der Uhr liegt dahinter aber nur Schwarz.
      Ersetzt durch eine ruhige Fläche; über Schwarz ergibt das
      denselben Farbwert auf 0,006 pro Kanal. Dazu die zwölf
      Einzelschatten raus.
- [x] **Funk bei jedem Tastendruck.** Plus und Minus schickten pro
      Druck `transferUserInfo` **und** `sendMessage`, und das iPhone
      antwortete auf jeden mit dem vollen Datensatz. Von 42 auf 56 sind
      das rund sechzig Funkvorgänge. Jetzt wird 1,2 s nach dem letzten
      Druck gemeldet, und nur der Endwert. Beim Verlassen der Seite und
      beim Handgelenk-Senken geht ein wartender Wert sofort raus.
- [ ] **[Build] Nachmessen**, ob es gereicht hat: App auf der Uhr offen
      liegen lassen und den Verbrauch ansehen.
- [ ] Falls nicht: `WatchSyncService.syncToWatch` schickt denselben
      Datensatz **zweimal** — `updateApplicationContext` *und*
      `sendMessage`. Das wäre der nächste Kandidat. Vorher prüfen, ob
      der Datensatz ohne `sendMessage` schnell genug ankommt, wenn die
      Uhr gerade geweckt wird.

## Bekannte Schwachstellen

- [x] ~~Plus/Minus-Tasten in Glas und Classic kaum unterscheidbar~~ —
      10.11.2026 neu: Classic = erhabene Gehäusetasten mit Schattenkante
      und olivgrauem Ziffernfeld (Farben aus dem Gerätefoto), Glas =
      Milchglas in der Glasfarbe. Im Simulator gerendert geprüft.
- [ ] Die Symbole im Classic-Modus sind für ein Segment-LCD fein
      gezeichnet, besonders die Spritze; auf dem Original wirken sie
      gröber. **Bewusst nicht geändert** — Mathias' Ansage war, seine
      Grafiken zu verwenden und keine neuen zu erfinden. Falls gewünscht,
      wäre der Weg: dieselben SVGs kräftiger rendern, nicht neu zeichnen.
- [x] ~~Umschalter mit drei Knöpfen auf schmalen Geräten~~ — nachgemessen
      bei 320, 375, 390 und 430 pt: nichts wird abgeschnitten, auch nicht
      auf dem kleinsten iPhone SE.

## Für TestFlight

- [ ] GitHub Pages aktivieren (Einstellungen → Pages → `/docs`), sonst ist
      die Datenschutz-Seite nicht erreichbar. Letzter offener Punkt in
      `docs/testflight-checklist.md`.

---

## Wenn `xcodebuild` einfach hängt

Am 10.11.2026 blieb jedes `xcodebuild -list` und jeder Build im
Projektordner ohne CPU-Last stehen. Ursache war ein seit acht Tagen
laufendes, eingefrorenes Xcode, das eine Dateikoordinations-Sperre
(`NSFileCoordinator`) auf dem Projektpfad hielt — nicht das Projekt.
Erkennbar: `sample <pid>` zeigt `_blockOnAccessClaim`, und AppleScript
`tell application "Xcode" to quit` läuft in den Timeout.

Ausweg, wenn Xcode nicht beendet werden kann: Projekt ohne `.git` in
einen anderen Ordner kopieren und dort bauen — die Sperre gilt nur für
den Originalpfad. Sauberer ist, das hängende Xcode zu beenden.

Am selben Tag stand außerdem ein **Verweis des Projekts auf sich selbst**
(`projectReferences` → `HippominderLilly2.xcodeproj`) in der
`project.pbxproj`; wahrscheinlich in Xcode versehentlich hineingezogen.
Entfernt — so etwas gehört nie hinein.

## Wenn zwei Sitzungen gleichzeitig arbeiten

Das ging schon einmal schief: beide auf demselben Branch, Push abgelehnt,
Merge von Hand. Darum:

- Wer baut, hat Vorrang — die Mac-Sitzung führt.
- Die Cloud-Sitzung fasst den Branch nicht an, solange auf dem Mac
  gearbeitet wird.
- Vor jedem Commit `git pull`, danach zügig pushen.
- Was die andere Seite wissen muss, gehört in die Commit-Nachricht oder
  in `CLAUDE.md` — es gibt keinen direkten Draht zwischen den Sitzungen.
