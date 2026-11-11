# Übergabe an die örtliche Sitzung

Ab hier wird **auf Mathias' Mac** gearbeitet, nicht mehr in der Cloud.
Diese Datei ist das Erste, was eine neue Sitzung auf dem Mac liest.

Stand: 11. November 2026.

---

## Warum der Umzug

Die Cloud-Sitzung kann lesen, rechnen und schreiben, aber **nicht
bauen** — kein Mac, kein Xcode. Jedes Mal, wenn gebaut werden musste,
landete das bei Mathias in Xcode. Das hat einen ganzen Abend gekostet
und ihn zu Recht geärgert. Darum: eine Sitzung, die selbst baut.

## Zuerst lesen

1. `/Users/mathias/Developer/HippominderLilly2/CLAUDE.md` — das
   Projektwissen. Vor allem: **die Blume nicht neu erfinden**, und
   **Mathias immer den ganzen Pfad nennen**.
2. `/Users/mathias/Developer/HippominderLilly2/CLAUDE.local.md` — seine
   persönlichen Regeln. Kurzfassung: alles ohne Rückfrage machen.
3. `/Users/mathias/Developer/HippominderLilly2/docs/OFFEN.md` — die
   Arbeitsliste. Abgehaktes steht drin, damit niemand zweimal prüft.

## Wo was liegt

| | |
|---|---|
| Arbeitskopie (MacBook) | `/Users/mathias/Developer/HippominderLilly2` |
| Branch | `claude/ipad-coding-exploration-3Y3F6` |
| Verknüpfung für Mathias | `dm_code_reader/projekte/hippominder/` in iCloud |
| Lilly starten | `/Users/mathias/Developer/HippominderLilly2/Lilly starten.command` |
| Stand holen | `/Users/mathias/Developer/HippominderLilly2/Stand holen.command` |

Das Repository liegt **bewusst nicht** in iCloud — iCloud hatte schon
neun Asset-Dateien verdoppelt. In `dm_code_reader` steht nur eine
Verknüpfung.

## Wo das Projekt gerade steht

**Version 3.1.0 (2).** Gebaut am 10.11.2026 mit Xcode 27.1, auf dem
echten iPhone (blackiPhone_14, iOS 27.2) installiert, 0 Fehler,
0 Warnungen. Unit-Tests laufen (12 in `FlowerGeometryTests`), das
Watch-Target baut.

**Bina hat die Umstellung überstanden** — Migration von 3.0.0 auf 3.1.0
sauber, mit Foto, iCloud-Datensatz vorhanden. Das war die große offene
Frage und sie ist beantwortet.

Unten in der App steht jetzt eine kleine Zeile mit Version und
**Bauzeit** (`Models/Versionsinfo.swift`). Die beantwortet beim Bauen
die eigentliche Frage: ist mein Stand wirklich drauf? Siehe
`/Users/mathias/Developer/HippominderLilly2/docs/VERSION.md`.

## Neu: frisches Xcode auf dem MacBook

Mathias hat am 11.11.2026 die neueste Xcode-Version installiert. Der
letzte grüne Build (3.1.0 (2), 0 Fehler, 0 Warnungen) entstand noch mit
Xcode 27.1 — **der zählt damit nicht mehr als Beweis.** Erster Schritt
jeder Sitzung auf dem MacBook: einmal neu bauen und nachsehen, was das
neue SDK meckert.

Womit zu rechnen ist:

- Beim ersten Start installiert Xcode Komponenten nach und will die
  Lizenz bestätigt haben (`sudo xcodebuild -license accept`).
- **„Update to recommended settings"** kommt wieder. Nicht blind
  annehmen — erst ansehen, was es an `project.pbxproj` ändern will, und
  den Diff in den Commit schreiben.
- Neue Warnungen sind bei einem SDK-Sprung normal. Erst sammeln, dann
  bewerten, nicht hektisch wegpatchen.

## Was als Nächstes dran ist

Alles in `docs/OFFEN.md`, das Wichtigste zuerst:

1. **Die Uhr.** Die Watch-App wird jetzt in die iPhone-App eingebettet,
   kam aber noch nie auf eine echte Uhr. Haken: das Signaturprofil kennt
   die Ultra 2 nicht. Entwicklermodus auf der Uhr, iPhone daneben
   entsperrt, dann ein Build mit
   `-allowProvisioningDeviceRegistration`.
2. **„War heute da" auf der Uhr.** Der Rückkanal Uhr → iPhone ist nie
   gelaufen. Besonders der Fall mit iPhone außer Reichweite
   (`transferUserInfo`) — das ist der eigentliche Stallfall.
3. **Die drei Darstellungen ansehen** (Glas, Classic, Blume), mit einem
   echten Pferdefoto, nicht dem Platzhalter.
4. **Überfällige Erinnerungen** und das **wechselnde App-Symbol** prüfen.
5. **Widget-Target** in Xcode anlegen. Die Datenbrücke steht
   (`Models/WidgetBridge.swift`, `Services/WidgetSyncService.swift`),
   das Target fehlt.
6. **Mac-Version** — hat von allem die wenigste Aufmerksamkeit bekommen.

## Wie hier gearbeitet wird

- **Selbst bauen, selbst Fehler wegmachen.** Mathias nicht nach Xcode
  schicken. Das ist der ganze Grund für diese Sitzung.
- **Vor dem Zeigen selbst ansehen.** Gerendert, nicht nur geschrieben.
- **Behauptungen nachrechnen**, nicht hinschreiben.
- **Immer den ganzen Pfad nennen**, auch bei Befehlen zum Kopieren.
- Erledigtes in `docs/OFFEN.md` abhaken statt löschen.

## Fallen, die schon Zeit gekostet haben

- **Xcode hält eine Dateisperre** auf dem Projektordner. Builds bleiben
  dann ohne Fehlermeldung hängen. Xcode zwingend beenden (⌥⌘Esc).
- **iCloud verdoppelt Dateien** (`datei 2.svg`). Bei merkwürdigen
  Git-Fehlern ist das die erste Vermutung, nicht der Code.
- **Die Fernsteuerung reißt ab**, wenn der Mac einschläft. Das Skript
  hält ihn mit `caffeinate` wach — aber nur bei offenem Deckel.
- **Nur eine `.sheet` pro View** rendert zuverlässig. Deshalb
  `.sheet(item:)` mit Enum in `HorseDetailView`.
