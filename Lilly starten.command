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

  # Halbfertiges Zusammenfuehren zuerst aufraeumen. Solange das liegt,
  # scheitert jedes Beiseitelegen mit "needs merge" und das Holen geht
  # gar nicht erst los.
  # Zurueckgesetzt wird nur auf den eigenen Stand (HEAD), der Branch
  # bleibt wo er ist - das Holen gleich danach bringt den Server-Stand.
  if [ -n "$(git ls-files --unmerged)" ]; then
    echo ""
    echo "  Hier liegt ein halbfertiges Zusammenfuehren. Betroffen:"
    git diff --name-only --diff-filter=U | sed 's/^/      /'
    echo ""
    echo "  Soll ich das wegraeumen? Aenderungen an diesen Dateien"
    echo "  gehen dabei verloren - der Stand vom Server kommt gleich."
    read -r -p "  j = ja, alles andere = nein: " ANTWORT
    if [ "$ANTWORT" = "j" ] || [ "$ANTWORT" = "J" ]; then
      git merge --abort 2>/dev/null
      if git reset --hard --quiet HEAD 2>/dev/null; then
        echo "  Aufgeraeumt."
      else
        echo "  Hat nicht geklappt - sag Lilly Bescheid."
      fi
    else
      echo "  Gut, bleibt liegen. Lilly kann sich darum kuemmern."
    fi
    echo ""
  fi

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
    # Haeufigster Grund: eigene Festschreibungen, die der Server nicht
    # kennt. Hier nur melden - Lilly sitzt gleich davor und kann es
    # sich ansehen, statt dass das Skript etwas verwirft.
    EIGENE=$(git log --oneline "origin/$BRANCH..HEAD" 2>/dev/null)
    if [ -n "$EIGENE" ]; then
      echo "  Hier liegen Festschreibungen, die der Server nicht hat:"
      echo "$EIGENE" | sed 's/^/      /'
      echo "  Lilly sieht sich das gleich an."
    else
      echo "  Der Abgleich ging nicht glatt durch - Lilly klaert das gleich."
    fi
  fi

  if [ "$STASHED" = "1" ]; then
    git stash pop --quiet >/dev/null 2>&1 \
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

# Solange Lilly verbunden ist, darf der Mac nicht einschlafen - sonst
# reisst die Fernsteuerung ab und Mathias steht vor "Remote Control
# getrennt". caffeinate gilt nur fuer die Dauer dieses Befehls, danach
# schlaeft der Mac wieder wie gewohnt.
#   -i  kein Leerlauf-Schlaf
#   -s  kein System-Schlaf am Netzteil
WACH=""
if command -v caffeinate >/dev/null 2>&1; then
  WACH="caffeinate -i -s"
  echo "  Der Mac bleibt wach, solange dieses Fenster offen ist."
  echo "  (Zugeklappter Deckel schlaeft trotzdem - dann Deckel auf lassen.)"
  echo ""
fi

$WACH claude remote-control

# Die Fernsteuerung gibt es nur mit angemeldetem claude.ai-Konto. Fehlt
# die Anmeldung, bricht sie mit einer englischen Meldung ab - statt
# Mathias damit sitzen zu lassen, melden wir ihn an und versuchen es
# nochmal.
if [ $? -ne 0 ]; then
  echo ""
  echo "  Die Fernsteuerung ging nicht. Meist fehlt nur die Anmeldung."
  echo "  Ich mache jetzt das Anmeldefenster auf."
  echo ""
  read -r -p "  Eingabetaste druecken, dann im Browser anmelden."
  claude auth login

  echo ""
  echo "  Nochmal mit Fernsteuerung ..."
  $WACH claude remote-control

  if [ $? -ne 0 ]; then
    echo ""
    echo "  Weiterhin keine Fernsteuerung - dann eben oertlich."
    echo "  Lilly laeuft dann nur hier im Fenster, nicht in der iPad-App."
    echo ""
    claude
  fi
fi

# Falls Lilly sich beendet, Fenster offen lassen statt wortlos zuzuklappen
echo ""
read -r -p "  Lilly wurde beendet. Mit der Eingabetaste schliessen."
