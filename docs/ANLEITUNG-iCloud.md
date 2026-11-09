# iCloud einschalten — Schritt für Schritt

Das hier muss einmal von Hand in Xcode gemacht werden. Es ist der einzige
Teil, den weder ein Skript noch Lilly übernehmen kann, weil Xcode dabei
mit Apples Servern spricht.

**Dauer: etwa fünf Minuten.**

---

## Vorher: einmal sichern

Bevor irgendetwas umgestellt wird — die Pferde wegsichern. Das dauert
20 Sekunden und ist dein Netz, falls etwas klemmt.

1. Hippominder auf dem iPhone öffnen
2. Oben links **Kontakte** antippen
3. Ganz unten **Daten sichern**
4. **Pferde sichern** antippen
5. Im Teilen-Menü **„In Dateien sichern"** → iCloud Drive

Fertig. Die Datei heißt `Hippominder-Pferde-JAHR-MONAT-TAG.json`.

---

## Schritt 1 — Stand holen

Doppelklick auf **„Stand holen"** im Projektordner.

Das Fenster holt den neuesten Stand und öffnet Xcode von selbst.

> **Beim allerersten Mal** warnt macOS: Rechtsklick auf die Datei →
> **Öffnen** → im Dialog nochmal **Öffnen**. Danach reicht Doppelklick.

---

## Schritt 2 — iCloud anschalten

In Xcode, das jetzt offen ist:

**2.1** Links oben in der Dateiliste ganz oben auf den **blauen
Projektnamen** „HippominderLilly2" klicken.

**2.2** In der mittleren Spalte unter **TARGETS** auf
**HippominderLilly2** klicken (das mit dem App-Symbol, nicht die
Tests-Einträge).

**2.3** Oben die Registerkarte **Signing & Capabilities** anklicken.

**2.4** Darunter links auf **+ Capability** klicken. Ein Suchfenster geht
auf.

**2.5** **iCloud** tippen und doppelklicken.

**2.6** Es erscheint ein neuer Block „iCloud". Dort:
- bei **Services** das Häkchen bei **CloudKit** setzen
- bei **Containers** sollte `iCloud.com.roboterwerk.HippominderLilly2`
  erscheinen. Steht es nicht da: auf **+** klicken und es eintippen.

> Xcode legt den Container bei Apple an. Das kann einen Moment dauern und
> braucht Internet.

---

## Schritt 3 — Hintergrund-Abgleich anschalten

Ohne das kommen Änderungen vom anderen Gerät erst, wenn du die App neu
startest.

**3.1** Nochmal auf **+ Capability**

**3.2** **Background Modes** tippen und doppelklicken

**3.3** Im neuen Block das Häkchen bei **Remote notifications** setzen

---

## Schritt 4 — Bauen

**4.1** Oben in der Leiste neben dem Projektnamen das Gerät wählen —
dein iPhone steht ganz oben unter „Personal Device".

**4.2** **Befehlstaste + R**

---

## Schritt 5 — Nachsehen, ob alles da ist

- **Sind deine Pferde noch da?** Wenn nicht: nicht neu anlegen! Stattdessen
  **Kontakte → Daten sichern → Sicherung einlesen** und die Datei von
  vorhin wählen. Dabei wird nichts gelöscht, nur ergänzt.
- **Kommt eine Frage nach iCloud?** Erlauben.

---

## Wenn etwas schiefgeht

**Rote Fehlermeldung in Xcode:** Oben rechts auf das rote Symbol klicken,
den Text kopieren und Lilly schicken.

**„Failed to register bundle identifier" oder Ähnliches beim Container:**
Das heißt meist, dass der Name schon vergeben ist. Dann einen anderen
nehmen, z. B. `iCloud.com.roboterwerk.hippominder` — und Lilly Bescheid
sagen, damit sie die Entitlements anpasst.

**App startet, aber nichts gleicht sich ab:** Prüfen, ob auf beiden
Geräten dieselbe Apple-ID angemeldet ist und iCloud Drive an ist.

---

## Was danach gilt

Die Pferde liegen in **deinem** iCloud — nicht auf einem fremden Server.
Sie erscheinen auf iPhone und Mac, und ein verlorenes Gerät nimmt sie
nicht mehr mit.

Die Uhr bleibt bewusst außen vor: Sie holt sich die Daten weiterhin direkt
vom iPhone, weil das im Stall auch ohne Netz funktioniert.
