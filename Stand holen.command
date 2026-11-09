#!/bin/bash
#
#  Stand holen.command
#  Hippominder
#
#  Doppelklick: holt den neuesten Stand und oeffnet Xcode.
#  Mehr muss nicht von Hand getippt werden.
#

BRANCH="claude/ipad-coding-exploration-3Y3F6"

cd "$(dirname "$0")" || exit 1

echo ""
echo "  Hippominder - Stand holen"
echo "  ========================="
echo ""

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "  Das hier ist kein Git-Ordner. Nichts zu holen."
  read -r -p "  Mit der Eingabetaste schliessen."
  exit 1
fi

# Unfertiges zur Seite legen, damit das Holen nicht daran scheitert
STASHED=0
if [ -n "$(git status --porcelain)" ]; then
  echo "  Es liegen eigene Aenderungen herum - ich lege sie kurz beiseite."
  git stash push --include-untracked --quiet --message "automatisch vor dem Holen" && STASHED=1
fi

echo "  Hole vom Server ..."
git fetch --quiet origin 2>/dev/null
git checkout --quiet "$BRANCH" 2>/dev/null || git checkout --quiet -b "$BRANCH" "origin/$BRANCH" 2>/dev/null

if git pull --quiet --ff-only origin "$BRANCH" 2>/dev/null; then
  echo "  Fertig. Neuester Stand ist da."
else
  echo "  Das Holen ging nicht glatt durch."
  echo "  Starte Lilly und sag ihr: 'Der Pull klemmt, kuemmerst du dich?'"
fi

if [ "$STASHED" = "1" ]; then
  git stash pop --quiet 2>/dev/null \
    && echo "  Deine Aenderungen sind wieder da." \
    || echo "  Deine Aenderungen liegen in 'git stash' - sag Lilly Bescheid."
fi

echo ""
echo "  Letzte Aenderung: $(git log -1 --format='%s')"
echo "  von             : $(git log -1 --format='%cr')"
echo ""

PROJEKT=$(ls -d *.xcodeproj 2>/dev/null | head -1)
if [ -n "$PROJEKT" ]; then
  echo "  Oeffne Xcode ..."
  open "$PROJEKT"
  echo ""
  echo "  In Xcode: oben das Geraet waehlen, dann Befehlstaste+R."
else
  echo "  Kein Xcode-Projekt gefunden."
fi

echo ""
read -r -p "  Mit der Eingabetaste schliessen."
