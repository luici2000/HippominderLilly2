#!/bin/bash
#
#  Lilly starten.command
#  Hippominder
#
#  Doppelklick im Finder startet Lilly auf diesem Mac und meldet sie
#  zur Fernsteuerung an, damit Mathias vom iPad aus mitarbeiten kann.
#
#  Die Datei liegt im Projektordner und findet ihn darum selbst - egal
#  wohin das Projekt verschoben wird.
#

BRANCH="claude/ipad-coding-exploration-3Y3F6"

# In den Ordner wechseln, in dem diese Datei liegt
cd "$(dirname "$0")" || exit 1

echo ""
echo "  Hippominder"
echo "  ==========="
echo ""
echo "  Projektordner: $(pwd)"
echo ""

# --- Laeuft Claude Code ueberhaupt? ---
if ! command -v claude >/dev/null 2>&1; then
  echo "  Claude Code ist auf diesem Mac noch nicht installiert."
  echo ""
  echo "  Bitte einmalig im Terminal eingeben:"
  echo "      npm install -g @anthropic-ai/claude-code"
  echo ""
  echo "  Falls npm fehlt, vorher:"
  echo "      brew install node"
  echo ""
  read -r -p "  Mit der Eingabetaste schliessen."
  exit 1
fi

# --- Neuesten Stand holen ---
echo "  Hole den neuesten Stand ..."
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "  Achtung: Das hier ist kein Git-Projektordner."
  echo "  Lilly startet trotzdem, aber ohne Abgleich."
else
  git fetch --quiet origin 2>/dev/null

  # Unfertige Aenderungen zur Seite legen, damit der Abgleich nicht scheitert
  STASHED=0
  if [ -n "$(git status --porcelain)" ]; then
    echo "  Es liegen noch unfertige Aenderungen - ich lege sie kurz beiseite."
    git stash push --include-untracked --quiet --message "automatisch vor dem Start" && STASHED=1
  fi

  git checkout --quiet "$BRANCH" 2>/dev/null || git checkout --quiet -b "$BRANCH" "origin/$BRANCH" 2>/dev/null

  if git pull --quiet --ff-only origin "$BRANCH" 2>/dev/null; then
    echo "  Stand ist aktuell."
  else
    echo "  Der Abgleich ging nicht glatt durch - Lilly klaert das gleich."
  fi

  if [ "$STASHED" = "1" ]; then
    git stash pop --quiet 2>/dev/null \
      && echo "  Deine Aenderungen sind wieder da." \
      || echo "  Deine Aenderungen liegen in 'git stash' - sag Lilly Bescheid."
  fi

  echo "  Branch: $(git rev-parse --abbrev-ref HEAD)"
  echo "  Letzter Stand: $(git log --oneline -1)"
fi

echo ""
echo "  Starte Lilly mit Fernsteuerung."
echo "  Diese Sitzung erscheint gleich in der Claude-App auf dem iPad."
echo ""
echo "  Zum Beenden: Strg+C, oder dieses Fenster schliessen."
echo ""

claude remote-control

# Falls Lilly sich beendet, Fenster offen lassen statt wortlos zuzuklappen
echo ""
read -r -p "  Lilly wurde beendet. Mit der Eingabetaste schliessen."
