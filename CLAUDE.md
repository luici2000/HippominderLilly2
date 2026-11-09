# Hippominder — Projektwissen

Diese Datei liest jede Claude-Sitzung automatisch. Sie hält fest, was
hart erarbeitet wurde und nicht nochmal erraten werden soll.
Mathias' persönliche Regeln stehen in `CLAUDE.local.md`.

## Was die App ist

Erinnert an drei Pferdetermine: Hufschmied, Impfung, Wurmkur. SwiftUI +
SwiftData, Ziele iOS / macOS / watchOS. Nachbau eines echten Geräts, das
Mathias 2006 bauen ließ (Roboterwerk Hubrich, Firmware von Avisaro).

## Die Blume — bitte nicht neu erfinden

Der teuerste Fehler dieses Projekts war, die Blume aus dem Wort „Blume"
zu erfinden, statt die Vorlagen anzusehen. **Immer zuerst
`Assets.xcassets/flower_*.png` und `docs/original_geraet/` ansehen.**

Aufbau, belegt durch Firmware und Gerätefoto:

- **12 Blütenblätter** als Kapseln, radial nach außen, mit Lücke zur Mitte.
  Zwölf wie Stundenpositionen — es ist ein Zifferblatt.
- **Füllung startet bei 1 Uhr**, im Uhrzeigersinn. Steht wörtlich in
  `fet430_1.c`: „Rosen fangen bei 1 Uhr an", Segmente 1–12.
- **Die Mitte ist leer.** Kein Ring. Erst bei Ablauf erscheint dort ein
  **fetter Punkt** (Segment 13 der Firmware), etwa 0,38 der Blumenbreite.
- **Bei Alarm blinkt nur die Glocke**, nie die Symbole.

Maße und Rechnung stehen **einmal** in `Models/FlowerGeometry.swift`
(`FlowerGeometry` und `LCDGeometry`). Dort, weil das Watch-Target nur
`WatchApp` und `Models` synchronisiert — so rechnen Uhr, iPhone und Mac
mit denselben Werten. Bitte nicht wieder in die Views kopieren.

Maße als Anteil der Blumenbreite:

| | aus den PNGs | am Gerät gemessen |
|---|---|---|
| Blattbreite | 0,117 | 0,089 |
| Blattlänge | 0,255 | 0,23 |
| Mitte → Blattmitte | 0,363 | 0,354 |

## Die drei Darstellungen

`GlobalSettings.designMode` schaltet um, Umschalter in `HorseDetailView`.

- **Glas** — `FlowerTimerViewGlass.swift`. Blütenblätter aus
  `.ultraThinMaterial`, das Pferdefoto dahinter wird gebrochen sichtbar.
  Freie Farbwahl. Kein Schein/Hof hinter der Blume — ausdrücklich
  unerwünscht.
- **Classic** — `FlowerTimerViewLCD.swift`. Das graugrüne Gerätedisplay.
  Unbeleuchtete Segmente sind **feine Konturen**, keine grauen Flächen —
  das macht den LCD-Charakter. Grundton olivgrau (#959585), gemessen.
- **Blume** — `FlowerTimerView.swift`. Mathias' vorgerenderte
  Icon-Composer-PNGs mit den drei Farbschemata.

Auch die Pferdeliste (`MiniRose` in `ContentView.swift`) und die Uhr
(`WatchApp/WatchFlower.swift`) zeigen dieselbe Blume, nur kleiner — statt
eines Ampelpunkts oder Balkens. Unter etwa 30 pt lassen sich die zwölf
Blätter nicht mehr zählen; das wurde durch Rendern geprüft.

Lichteinfall überall **−45°** (oben links). Bei gedrehten Blättern wird
der Glanz gegenrotiert, sonst wandert das Licht mit.

## Fallen

- **Die Event-Icons rendern als Template.** Jedes `Image(eventType.symbol)`
  braucht ein explizites `foregroundStyle`, sonst erscheint es in der
  Akzentfarbe statt schwarz.
- **Profilbild ≠ Hintergrundfoto.** Beide gehen durch `ImageCropperView`,
  aber mit unterschiedlicher Form: der Avatar rund (`.circle`), das
  Hintergrundfoto rechteckig im Format der Fotobühne
  (`.rect(aspect:)`, siehe `HorseDetailView.buehnenFormat`). Beide Maße
  müssen zusammenpassen, sonst wird der gewählte Ausschnitt wieder
  beschnitten. Der runde Schnitt taugt **nicht** als Hintergrund: JPEG
  kann keine Transparenz, das gäbe schwarze Ecken.
- **`interval == 0`** machte die Division `.infinity`, und `Int(.infinity)`
  stürzt ab. Abgefangen in `FlowerGeometry.filledPetals`.
- **Blinkanimationen** brauchen `.onChange`, nicht nur `.onAppear` — sonst
  bleiben sie hängen, wenn ein Termin währenddessen erledigt wird.
- **Das App-Target synchronisiert `.`** Jeder neue Ordner landet darin,
  wenn er nicht in `EXCLUDED_SOURCE_FILE_NAMES` steht. Für Testordner
  zwingend, sonst wandert XCTest-Code in die App.
- **Krumme Pixelmaße** lassen den Blattkranz driften, weil jede der zwölf
  Drehungen anders rundet. Maße auf ganze Punkte legen.

## Wo das Projekt liegt

Mathias sammelt seine Projekte in iCloud unter
`dm_code_reader/projekte/hippominder/` — **nicht** im Home-Ordner. Neue
Kopien gehören dorthin; `Projekt umziehen.command` erledigt das.

Nebenwirkung, die man kennen muss: iCloud lädt Dateien bei Platzmangel
aus und gleicht laufend ab. Bei merkwürdigen Git-Fehlern (beschädigter
Index, fehlende Objekte) ist das die erste Vermutung, nicht der Code.

## Arbeitsweise

Mathias arbeitet aus dem Bett am iPad und schaut selten in Xcode. Was
ihm gezeigt wird, muss ohne Build beurteilbar sein — HTML-Vorschauen als
Artifact haben sich bewährt.

**Vor dem Zeigen selbst prüfen.** Gerendert ansehen, nicht nur schreiben.
Mehrere Fehler fielen so auf, bevor er sie sehen musste: ein gelbes
Emoji im monochromen Display, eine umgebrochene dritte Blume, nicht
unterscheidbare Füllstände.

**Behauptungen nachrechnen, nicht hinschreiben.** Die Testerwartungen in
`FlowerGeometryTests` wurden ausgeführt, bevor sie festgeschrieben wurden —
eine davon war falsch, und zwar meine Erwartung, nicht der Code.

## Was die Blume nicht kann

Ein Blatt deckt ein Zwölftel des Intervalls ab. Die Blume ist deshalb
voll, **bevor** der Termin fällig ist — bei 90 Tagen ab 7 Tagen Rest, bei
365 Tagen ab 30. Das ist keine Schwäche, das Gerät hatte dieselbe
Auflösung. Den Unterschied zu wirklich fällig macht der Mittelpunkt.
