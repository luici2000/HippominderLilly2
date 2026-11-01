# Offene Punkte

Arbeitsliste zwischen den Sitzungen. Die Cloud-Sitzung kann lesen,
messen und schreiben, aber nicht bauen — alles mit **[Build]** kann nur
eine Sitzung auf dem Mac erledigen.

Erledigtes bitte abhaken statt löschen, dann sieht man, was schon geprüft
wurde.

---

## Zuerst: ist überhaupt baubar?

- [ ] **[Build]** Baut das Projekt für iPhone 16e? Die letzten Änderungen
      entstanden ohne Compiler — geprüft wurde nur Syntax, nicht Typen.
- [ ] **[Build]** Läuft `⌘U`? Das Unit-Test-Target hatte vorher gar keine
      Quellen. `HippominderLilly2Tests` wurde in `project.pbxproj` neu
      verdrahtet, nach dem Muster der UI-Tests, aber **nie gebaut**.
      Wenn Xcode meckert: Das ist die wahrscheinlichste Fehlerquelle.
- [ ] **[Build]** Baut auch das Watch-Target? `Models/FlowerGeometry.swift`
      ist neu und wird von Uhr und App gemeinsam genutzt.

## Dann: sieht es richtig aus?

- [ ] **[Build]** Alle drei Darstellungen im Simulator ansehen: Glas,
      Classic, Blume. Umschalter sitzt in der Pferde-Detailansicht.
- [ ] **[Build]** Mit einem echten Pferdefoto prüfen, ob das Glas gut
      aussieht — bisher nur mit einem gemalten Platzhalter getestet.
- [ ] **[Build]** Mini-Blumen in der Pferdeliste: sind die zwölf Blätter
      auf dem Gerät noch zählbar? Am Rechner war 30 pt die Untergrenze.
- [ ] **[Build]** Uhr ansehen. Dort ist die Blume neu, vorher waren es
      Ampelpunkte und ein Balken.

## Bekannte Schwachstellen

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

## Wenn zwei Sitzungen gleichzeitig arbeiten

Das ging schon einmal schief: beide auf demselben Branch, Push abgelehnt,
Merge von Hand. Darum:

- Wer baut, hat Vorrang — die Mac-Sitzung führt.
- Die Cloud-Sitzung fasst den Branch nicht an, solange auf dem Mac
  gearbeitet wird.
- Vor jedem Commit `git pull`, danach zügig pushen.
- Was die andere Seite wissen muss, gehört in die Commit-Nachricht oder
  in `CLAUDE.md` — es gibt keinen direkten Draht zwischen den Sitzungen.
