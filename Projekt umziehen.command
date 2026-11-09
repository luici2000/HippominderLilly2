#!/bin/bash
#
#  Projekt umziehen.command
#  Hippominder
#
#  Verschiebt das Projekt nach dm_code_reader in iCloud, wo Mathias
#  seine Projekte sammelt. Danach muss dieses Skript nicht mehr
#  aufgerufen werden.
#

ZIEL_BASIS="$HOME/Library/Mobile Documents/com~apple~CloudDocs/dm_code_reader/projekte/hippominder"
QUELLE="$(cd "$(dirname "$0")" && pwd)"
NAME="$(basename "$QUELLE")"
ZIEL="$ZIEL_BASIS/$NAME"

echo ""
echo "  Hippominder - Projekt umziehen"
echo "  =============================="
echo ""
echo "  von:  $QUELLE"
echo "  nach: $ZIEL"
echo ""

if [ "$QUELLE" = "$ZIEL" ]; then
  echo "  Das Projekt liegt bereits dort. Nichts zu tun."
  read -r -p "  Mit der Eingabetaste schliessen."
  exit 0
fi

# Xcode und laufende Lilly wuerden ins Leere greifen
if pgrep -x Xcode >/dev/null 2>&1; then
  echo "  Xcode laeuft noch. Bitte erst beenden (Befehlstaste+Q),"
  echo "  sonst zeigt es danach auf einen Ordner, den es nicht mehr gibt."
  echo ""
  read -r -p "  Mit der Eingabetaste schliessen."
  exit 1
fi

if [ -e "$ZIEL" ]; then
  echo "  Dort liegt schon etwas mit diesem Namen."
  echo "  Bitte erst dort aufraeumen oder Lilly fragen."
  read -r -p "  Mit der Eingabetaste schliessen."
  exit 1
fi

if [ ! -d "$QUELLE/.git" ]; then
  echo "  Das hier sieht nicht nach dem Projektordner aus (kein .git)."
  read -r -p "  Mit der Eingabetaste schliessen."
  exit 1
fi

echo "  Ziehe um ..."
mkdir -p "$ZIEL_BASIS" || { echo "  Zielordner liess sich nicht anlegen."; read -r -p "  Eingabetaste."; exit 1; }

if mv "$QUELLE" "$ZIEL"; then
  echo "  Fertig."
  echo ""
  echo "  Pruefe, ob Git noch zufrieden ist ..."
  if (cd "$ZIEL" && git status >/dev/null 2>&1); then
    echo "  Ja - alles in Ordnung."
    echo "  Letzte Aenderung: $(cd "$ZIEL" && git log -1 --format='%s')"
  else
    echo "  Git meldet ein Problem. Starte Lilly und sag ihr Bescheid."
  fi
  echo ""
  echo "  Ab jetzt liegen 'Stand holen' und 'Lilly starten' dort."
  echo "  Ich oeffne den neuen Ordner im Finder."
  open "$ZIEL"
else
  echo "  Der Umzug ist fehlgeschlagen. Nichts wurde veraendert."
fi

echo ""
read -r -p "  Mit der Eingabetaste schliessen."
