# Welche Version ist das hier?

Diese Datei und die App müssen immer dasselbe sagen. Wer die Version
anhebt, schreibt hier eine Zeile dazu — sonst weiß die nächste Sitzung
nicht, was auf dem Gerät liegt.

## Aktuell

| | |
|---|---|
| **Version** | 3.1.0 |
| **Build** | 2 |
| Gesetzt in | `HippominderLilly2.xcodeproj/project.pbxproj` (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`) |
| Angezeigt durch | `Models/Versionsinfo.swift` |

## Wo man es am Gerät abliest

- **iPhone / iPad:** ganz unten unter der Pferdeliste, kleine graue Zeile:
  `3.1.0 (2) · 9.11. 15:42`
- **Mac:** ganz unten in der Seitenleiste, dieselbe Zeile
- **Uhr:** unter der Pferdeliste, verkürzt: `3.1.0 · 15:42`
- Antippen öffnet die Beta-Info mit der vollen Bauzeit. (Die fünf
  Logo-Tipper gehen weiter, braucht man aber nicht mehr.)

## Warum da eine Uhrzeit steht

Weil die Versionsnummer die eigentliche Frage nicht beantwortet. Beim
Bauen aufs iPhone lautet sie nicht „welche Version ist das", sondern
**„ist mein neuer Stand überhaupt angekommen?"** — und dabei ist die
Nummer nutzlos: sie bleibt zwischen zwei Builds gleich.

Die **Bauzeit** ändert sich bei jedem Build. Stimmt sie nicht mit dem
Zeitpunkt überein, zu dem gerade ⌘R gedrückt wurde, dann läuft die alte
App. Gelesen wird sie vom Programm selbst — beim Bauen wird es neu
geschrieben und signiert, sein Änderungsdatum *ist* die Bauzeit. Es ist
also kein Wert, den jemand von Hand pflegen muss und darum vergessen
kann.

## Wenn die Bauzeit nicht stimmt

Dann ist nicht neu installiert worden. Der Reihe nach:

1. Hat Xcode überhaupt gebaut, oder nur den Simulator gestartet? Oben in
   der Leiste muss das iPhone stehen, nicht „Any iOS Device".
2. **Produkt → Bereinigen** (Umschalt+Befehlstaste+K), dann nochmal ⌘R.
3. App auf dem iPhone löschen und neu bauen. Achtung: dabei sind die
   örtlichen Daten weg — vorher sichern (Kontakte → Daten sichern).
4. Hängt das iPhone noch am Kabel und ist es entsperrt?

## Verlauf

- **3.1.0 (2)** — 9. November 2026. Version und Bauzeit werden in der App
  angezeigt (iPhone, iPad, Mac, Uhr), damit beim Bauen zu sehen ist, ob
  der neue Stand ankam. iCloud-Abgleich über CloudKit, Datensicherung als
  Datei, iPad-Zweispalter, wechselndes App-Symbol bei überfälligen
  Terminen, „War heute da" auf der Uhr.
- **3.0.0 (1)** — Drei Darstellungen (Glas, Classic, Blume), Blume auch
  in Liste und auf der Uhr, Bildbearbeitung für Profil- und
  Hintergrundfoto. Stand der Bedienungsanleitung in `docs/`.
