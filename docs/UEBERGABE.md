# Übergabe — die eine Datei, die jede Sitzung zuerst liest

Mathias arbeitet mit mehreren Claude-Sitzungen: eine in der Cloud (kann
lesen, rechnen, schreiben — aber **nicht bauen**), eine auf dem Mac (kann
bauen). Sie haben kein gemeinsames Gedächtnis. **Diese Datei ist das
Gedächtnis.**

Für Mathias heißt das: Es ist egal, mit welcher Sitzung er redet. Jede
liest hier und weiß, wo es steht.

---

## Wenn du eine neue Sitzung bist

1. Diese Datei ganz lesen, vor allem das **Logbuch** unten.
2. `/Users/mathias/Developer/HippominderLilly2/CLAUDE.md` — Projektwissen,
   das nicht nochmal erraten werden soll.
3. `/Users/mathias/Developer/HippominderLilly2/docs/OFFEN.md` — die
   Arbeitsliste. Abgehaktes steht drin, damit niemand zweimal prüft.
4. `/Users/mathias/Developer/HippominderLilly2/CLAUDE.local.md` — Mathias'
   persönliche Regeln. Kurzfassung: alles ohne Rückfrage machen.

**Bevor du eine Sitzung beendest oder länger pausierst: schreib einen
Logbuch-Eintrag.** Drei Zeilen reichen. Was eine Sitzung nicht aufschreibt,
ist für die nächste nicht passiert.

---

## Wo alles liegt

| | |
|---|---|
| Arbeitskopie (MacBook) | `/Users/mathias/Developer/HippominderLilly2` |
| Branch | `claude/ipad-coding-exploration-3Y3F6` |
| Für Mathias sichtbar | Verknüpfung in iCloud: `dm_code_reader/projekte/hippominder/` |
| Lilly örtlich starten | `/Users/mathias/Developer/HippominderLilly2/Lilly hier starten.command` |
| Lilly mit Fernsteuerung | `/Users/mathias/Developer/HippominderLilly2/Lilly starten.command` |
| Nur Stand holen | `/Users/mathias/Developer/HippominderLilly2/Stand holen.command` |

Das Repository liegt **bewusst nicht** in iCloud — iCloud hatte schon neun
Asset-Dateien verdoppelt. In `dm_code_reader` steht nur eine Verknüpfung.

---

## Wie die Sitzungen sich nicht in die Quere kommen

Das ging schon einmal schief: beide auf demselben Branch, Push abgelehnt,
Merge von Hand.

- **Wer baut, hat Vorrang.** Die Mac-Sitzung führt.
- Die Cloud-Sitzung fasst die Dateien nicht an, an denen die Mac-Sitzung
  gerade arbeitet. Welche das sind, steht im Logbuch.
- **Vor jedem Commit `git pull`**, danach zügig pushen.
- Was die andere Seite wissen muss, gehört ins Logbuch — es gibt keinen
  direkten Draht zwischen den Sitzungen.

---

## Logbuch

Neueste zuerst. Format: Datum, welche Sitzung, was getan, was offen.

### 22.11.2026 — Cloud

**Getan:** Übersichtsseite vor den drei Terminen auf der Uhr (Tipp auf den
Pferdenamen führt dorthin, Tipp auf eine Blume weiter direkt auf ihre
Seite). Acht Tests für `HorseBackupService` — die Datensicherung war nie
geprüft. Datensicherung läuft jetzt auch auf dem Mac (war komplett
`#if os(iOS)`). Der Mac kann alle drei Darstellungen und hat einen eigenen
Umschalter dafür; im Glasmodus liegt das Pferdefoto hinter den Blumen.
Doku zur Uhr als Artifact: <https://claude.ai/artifact/ELjBLy7M2iN5GBJmWMvzSA>

**Offen und wichtig:**
- Die neuen Tests sind **nie gelaufen** (SwiftData gibt es auf Linux
  nicht). Erster `⌘U` ist ihr erster Lauf. Wahrscheinlichster Stolperstein:
  die Datei hängt noch nicht im Test-Target.
- Die Übersichtsseite ist **auf keiner echten Uhr gesehen**. Gerechnet
  passt sie (142 von 162 pt breit, 117 von 197 pt hoch auf der 41 mm).
- **Offene Frage an Mathias:** Die Uhr bekommt vom iPhone die Darstellung
  geschickt, legt sie ab und **liest sie nie** — `WatchGlas.designModeKey`
  wird im ganzen Uhr-Quelltext nur definiert und geschrieben. Die Uhr zeigt
  darum immer Glas. Entweder Classic dort wirklich anzeigen (wäre auf
  Schwarz sogar sparsamer) oder den Wert gar nicht erst schicken. In
  `CLAUDE.md` steht bis dahin das Gegenteil.

### 22.11.2026 — Mac

**Getan:** Der Uhr eine einzige Farbregel gegeben und Größen, die sich nach
dem Bildschirm richten.

### 14.11.2026 — Mac

**Getan:** Classic-Rosen richten sich nach der Displaybreite statt fester
86 pt (auf iPad und Mac standen sie verloren in der Fläche). Dreistellige
Tagesangaben sind jetzt so groß wie ihre Nachbarn.

### 12.11.2026 — Mac

**Getan:** Der Uhr-Verlust aufgeklärt und abgestellt — ein einziger leerer
Datensatz löschte alle Pferde auf der Uhr. Jetzt schickt das iPhone keine
leere Liste mehr, und die Uhr löscht bei einer leeren Liste nichts. Die Uhr
kann das iPhone außerdem um die Pferde bitten, wenn sie selbst keine hat.

**Bekannte Kehrseite:** Löscht Mathias sein **letztes** Pferd, bleibt es auf
der Uhr stehen, bis ein neues kommt. Bewusst in Kauf genommen — der kleinere
Schaden.

### 10./11.11.2026 — Mac

**Getan:** 3.1.0 (2) auf dem echten iPhone gebaut und installiert, 0 Fehler,
0 Warnungen. Unit-Tests laufen wieder (`⌘U`, 12 Tests). Watch-Target baut.
Uhr gekoppelt, Watch-App läuft darauf. Mac bekam die Detailseite und Liste
des iPhones.

**Wichtig:** **Bina hat die iCloud-Umstellung überstanden** — Migration von
3.0.0 auf 3.1.0 sauber, mit Foto, iCloud-Datensatz vorhanden.

---

## Fallen, die schon Zeit gekostet haben

- **Xcode hält eine Dateisperre** auf dem Projektordner. Builds bleiben dann
  ohne Fehlermeldung hängen. Xcode zwingend beenden (⌥⌘Esc).
- **iCloud verdoppelt Dateien** (`datei 2.svg`). Bei merkwürdigen
  Git-Fehlern ist das die erste Vermutung, nicht der Code.
- **Die Fernsteuerung reißt ab**, wenn der Mac einschläft. Das Skript hält
  ihn mit `caffeinate` wach — aber nur bei offenem Deckel.
- **Nur eine `.sheet` pro View** rendert zuverlässig. Deshalb
  `.sheet(item:)` mit Enum in `HorseDetailView`.
- **Eine Cloud-Sitzung kann nicht bauen.** Sie kann Syntax prüfen
  (`swiftc -parse`), rechnen und rendern — mehr nicht. Alles mit **[Build]**
  in `docs/OFFEN.md` gehört auf den Mac.
