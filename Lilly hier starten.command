#!/bin/bash
#
#  Lilly hier starten.command
#  Hippominder
#
#  Doppelklick: holt den Stand und startet Lilly in diesem Fenster -
#  bereits eingelesen in die Uebergabe. Mathias muss nichts mehr
#  reinkopieren, er kann sofort losreden.
#
#  Unterschied zu "Lilly starten.command": das hier bleibt im Terminal
#  und braucht keine Anmeldung und keine Fernsteuerung. Dafuer erscheint
#  die Sitzung nicht in der Claude-App.
#

BRANCH="claude/ipad-coding-exploration-3Y3F6"
UEBERGABE="docs/UEBERGABE.md"

cd "$(dirname "$0")" || exit 1

echo ""
echo "  Hippominder - Lilly hier"
echo "  ========================"
echo ""

if ! command -v claude >/dev/null 2>&1; then
  echo "  Claude Code ist auf diesem Mac noch nicht installiert."
  echo ""
  echo "  Bitte einmalig im Terminal eingeben:"
  echo "      npm install -g @anthropic-ai/claude-code"
  echo ""
  read -r -p "  Mit der Eingabetaste schliessen."
  exit 1
fi

# --- Stand holen ---
if git rev-parse --git-dir >/dev/null 2>&1; then
  git fetch --quiet origin 2>/dev/null

  # Halbfertiges Zusammenfuehren wegraeumen, sonst scheitert alles weitere
  if [ -n "$(git ls-files --unmerged)" ]; then
    echo "  Hier liegt ein halbfertiges Zusammenfuehren. Betroffen:"
    git diff --name-only --diff-filter=U | sed 's/^/      /'
    read -r -p "  Wegraeumen? j = ja, alles andere = nein: " ANTWORT
    if [ "$ANTWORT" = "j" ] || [ "$ANTWORT" = "J" ]; then
      git merge --abort 2>/dev/null
      git reset --hard --quiet HEAD 2>/dev/null && echo "  Aufgeraeumt."
    fi
    echo ""
  fi

  STASHED=0
  if [ -n "$(git status --porcelain)" ]; then
    git stash push --include-untracked --quiet --message "automatisch vor dem Start" && STASHED=1
  fi

  git checkout --quiet "$BRANCH" 2>/dev/null || git checkout --quiet -b "$BRANCH" "origin/$BRANCH" 2>/dev/null
  git pull --quiet --ff-only origin "$BRANCH" 2>/dev/null \
    && echo "  Stand ist aktuell." \
    || echo "  Der Abgleich ging nicht glatt durch - Lilly sieht es sich an."

  if [ "$STASHED" = "1" ]; then
    git stash pop --quiet >/dev/null 2>&1 \
      && echo "  Deine Aenderungen sind wieder da." \
      || echo "  Deine Aenderungen liegen in 'git stash' - sag Lilly Bescheid."
  fi
fi

# --- Was zuletzt geschah, kurz anzeigen ---
if [ -f "$UEBERGABE" ]; then
  echo ""
  echo "  Zuletzt im Logbuch:"
  # Die erste Ueberschrift im Logbuch und die drei Zeilen darunter
  awk '/^### /{n++} n==1 && c<5 {print "      " $0; c++}' "$UEBERGABE"
fi

echo ""
echo "  Starte Lilly. Sie liest die Uebergabe selbst - du kannst"
echo "  sofort losreden."
echo ""
echo "  Zum Beenden: Strg+C, oder dieses Fenster schliessen."
echo ""

# Der erste Auftrag geht gleich mit, damit nichts mehr von Hand
# hineinkopiert werden muss
claude "Lies $UEBERGABE ganz, dazu CLAUDE.md, CLAUDE.local.md und docs/OFFEN.md. Sag mir danach in hoechstens fuenf Zeilen, wo das Projekt steht und was du als Naechstes vorschlaegst. Schreib am Ende der Sitzung einen Logbuch-Eintrag in $UEBERGABE."

echo ""
read -r -p "  Lilly wurde beendet. Mit der Eingabetaste schliessen."
