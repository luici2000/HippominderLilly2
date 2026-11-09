#!/bin/bash
#
#  Projekt umziehen.command
#  Hippominder
#
#  Legt in dm_code_reader eine Verknuepfung auf das Projekt an.
#
#  Warum nicht wirklich verschieben: iCloud laedt Dateien bei
#  Platzmangel aus und gleicht laufend ab. Ein .git-Ordner und
#  Xcode vertragen das schlecht - beschaedigter Index, fehlende
#  Objekte, Builds die ins Leere greifen. Die Arbeitskopie bleibt
#  darum oertlich, und in dm_code_reader steht ein Verweis.
#

QUELLE="$(cd "$(dirname "$0")" && pwd)"
ZIEL_BASIS="$HOME/Library/Mobile Documents/com~apple~CloudDocs/dm_code_reader/projekte/hippominder"
VERWEIS="$ZIEL_BASIS/$(basename "$QUELLE")"

echo ""
echo "  Hippominder - Verknuepfung anlegen"
echo "  =================================="
echo ""
echo "  Arbeitskopie: $QUELLE"
echo "  Verweis in:   $ZIEL_BASIS"
echo ""

if [ ! -d "$QUELLE/.git" ]; then
  echo "  Das hier sieht nicht nach dem Projektordner aus."
  read -r -p "  Mit der Eingabetaste schliessen."
  exit 1
fi

if [ ! -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs" ]; then
  echo "  iCloud Drive ist auf diesem Mac nicht eingerichtet."
  read -r -p "  Mit der Eingabetaste schliessen."
  exit 1
fi

mkdir -p "$ZIEL_BASIS" || { echo "  Ordner liess sich nicht anlegen."; read -r -p "  Eingabetaste."; exit 1; }

# Alten Verweis ersetzen, aber niemals einen echten Ordner anfassen
if [ -L "$VERWEIS" ]; then
  rm "$VERWEIS"
elif [ -e "$VERWEIS" ]; then
  echo "  Dort liegt bereits ein echter Ordner, keine Verknuepfung."
  echo "  Ich fasse ihn nicht an - bitte Lilly fragen."
  read -r -p "  Mit der Eingabetaste schliessen."
  exit 1
fi

if ln -s "$QUELLE" "$VERWEIS"; then
  echo "  Fertig. In dm_code_reader/projekte/hippominder liegt jetzt"
  echo "  ein Verweis auf das Projekt."
  echo ""
  echo "  Doppelklick darauf oeffnet die Arbeitskopie."
  open "$ZIEL_BASIS"
else
  echo "  Die Verknuepfung liess sich nicht anlegen."
fi

echo ""
read -r -p "  Mit der Eingabetaste schliessen."
