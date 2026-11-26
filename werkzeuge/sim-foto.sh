#!/bin/zsh
#
# sim-foto.sh - App im Simulator starten und abfotografieren.
#
# Wozu: Damit jede Sitzung selbst nachsehen kann, wie etwas aussieht,
# bevor Mathias es zu sehen bekommt (CLAUDE.md: "Vor dem Zeigen selbst
# pruefen"). Ein Aufruf baut bei Bedarf, installiert, startet mit den
# Demo-Schaltern und legt ein PNG ab.
#
# Aufruf:
#   werkzeuge/sim-foto.sh <iphone|ipad|uhr> <name> [Startschalter ...]
#   werkzeuge/sim-foto.sh --bauen uhr termin -demoHorse -demoTermin
#
#   --bauen   vorher neu bauen (sonst nur, wenn noch kein Build da ist)
#   <name>    Dateiname des Fotos, ohne .png
#
# Beispiele fuer Startschalter (siehe Quelltext, alle nur im Debug-Build):
#   iPhone: -demoHorse -demoDaysAgo 30,120,10 -demoDetail -demoHorsePhoto
#   Uhr:    -demoHorse -demoDaysAgo 30,120,10 -demoDetail -demoTermin
#           -demoScroll -demoGlas -demoClassic -demoStil -demoPferdFarbe
#
# Fotos landen in $SIM_FOTOS (Vorgabe: /private/tmp/hippominder-fotos).
# Geraete lassen sich ueber SIM_IPHONE, SIM_IPAD, SIM_UHR (Name) waehlen.
#
# Wenn es haengt: `xcrun simctl shutdown all`, notfalls den Dienst
# neu starten (`killall -9 com.apple.CoreSimulator.CoreSimulatorService`).
# Am 25.11.2026 hingen Installieren und Starten auf iOS 18.4 neben
# Xcode 27.2 ohne Meldung - seither gibt es die iOS-27-Laufzeit.

set -u

PROJEKT="$(cd "$(dirname "$0")/.." && pwd)"
ABLAGE="${SIM_FOTOS:-/private/tmp/hippominder-fotos}"
BUILD="/private/tmp/hippominder-sim-build"

bauen=0
if [[ "${1:-}" == "--bauen" ]]; then bauen=1; shift; fi
ziel="${1:-}"; name="${2:-}"
if [[ -z "$ziel" || -z "$name" ]]; then
    sed -n '9,20p' "$0"; exit 64
fi
shift 2

case "$ziel" in
    iphone) geraet="${SIM_IPHONE:-iPhone 17}"; schema=HippominderLilly2
            bundle=com.roboterwerk.HippominderLilly2; produkt=Debug-iphonesimulator/Hippominder.app ;;
    ipad)   geraet="${SIM_IPAD:-iPad (A16)}"; schema=HippominderLilly2
            bundle=com.roboterwerk.HippominderLilly2; produkt=Debug-iphonesimulator/Hippominder.app ;;
    uhr)    geraet="${SIM_UHR:-Apple Watch Series 9 (41mm)}"; schema=HippominderWatch
            bundle=com.roboterwerk.HippominderLilly2.watchkitapp; produkt=Debug-watchsimulator/HippominderWatch.app ;;
    *) echo "Ziel muss iphone, ipad oder uhr sein"; exit 64 ;;
esac

# Neuestes Geraet dieses Namens (bei mehreren Laufzeiten das letzte in der Liste)
id=$(timeout 60 xcrun simctl list devices available | grep -F "    $geraet (" | tail -1 \
     | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
if [[ -z "$id" ]]; then echo "Kein Simulator \"$geraet\" gefunden"; exit 1; fi
echo "Geraet: $geraet ($id)"

timeout 180 xcrun simctl bootstatus "$id" -b >/dev/null || { echo "Simulator startet nicht"; exit 1; }

app="$BUILD/Build/Products/$produkt"
if [[ $bauen == 1 || ! -d "$app" ]]; then
    echo "Baue $schema ..."
    timeout 900 xcodebuild -project "$PROJEKT/HippominderLilly2.xcodeproj" -scheme "$schema" \
        -destination "id=$id" -derivedDataPath "$BUILD" build > "$BUILD.log" 2>&1 \
        || { grep -E "error:" "$BUILD.log" | sort -u | head -20; echo "Build fehlgeschlagen, Log: $BUILD.log"; exit 1; }
fi

timeout 180 xcrun simctl install "$id" "$app" || { echo "Installieren haengt oder scheitert"; exit 1; }
timeout 30 xcrun simctl terminate "$id" "$bundle" 2>/dev/null
timeout 60 xcrun simctl launch "$id" "$bundle" "$@" >/dev/null || { echo "Start scheitert"; exit 1; }
perl -e 'select(undef,undef,undef,4.5)'   # Demo-Schalter springen nach ~1 s

mkdir -p "$ABLAGE"
timeout 30 xcrun simctl io "$id" screenshot "$ABLAGE/$name.png" >/dev/null 2>&1 \
    || { echo "Foto scheitert"; exit 1; }
echo "$ABLAGE/$name.png"
